#!/usr/bin/env node

const fs = require('node:fs');
const { execSync } = require('node:child_process');

const CLAUDE_DUMB_ZONE = 59;
const QUOTA_CACHE_FILE = '/tmp/claude-quota-cache.json';

function getGitBranch() {
  try {
    return execSync('git branch --show-current 2>/dev/null', { encoding: 'utf-8' }).trim();
  } catch {
    return '';
  }
}

function ansi(text, bgColor, color = 'rgb(255, 255, 255)') {
  const RESET = '\x1b[0m';
  const bgColorValues = bgColor.match(/\d+/g);
  const bgColorAnsi = `\x1b[48;2;${bgColorValues.join(';')}m`;
  const colorValues = color.match(/\d+/g);
  const colorAnsi = `\x1b[38;2;${colorValues.join(';')}m`;
  return `${RESET}${bgColorAnsi}${colorAnsi}${text}${RESET}`;
}

/**
 * Extracts quotas from the stdin `rate_limits` payload (epoch seconds -> ISO strings).
 * Returns null when the payload has no usable data.
 */
function parseRateLimits(rateLimits) {
  const five = rateLimits?.five_hour;
  const seven = rateLimits?.seven_day;
  if (typeof five?.used_percentage !== 'number' || typeof seven?.used_percentage !== 'number') return null;
  return {
    session: { quota: five.used_percentage, resetsAt: new Date(five.resets_at * 1000).toISOString() },
    weekly: { quota: seven.used_percentage, resetsAt: new Date(seven.resets_at * 1000).toISOString() },
  };
}

// Persisted for claude-quota.js and the claude-quota-gnome extension, which only read this file.
function writeQuotaCache(quota) {
  try {
    fs.writeFileSync(QUOTA_CACHE_FILE, JSON.stringify({ fetchedAt: new Date().toISOString(), ...quota }, null, 2));
  } catch {
    // Cache is best effort
  }
}

function formatModelName(displayName) {
  const match = displayName.match(/(\w+)\s+(\d+(?:\.\d+)?)/);
  if (!match) return displayName;

  const model = match[1];
  const version = match[2];
  const modelInitial = model[0].toUpperCase();
  const shortVersion = version.replace('.', '');

  let result = `${modelInitial}${shortVersion}`;
  if (displayName.includes('1M')) {
    result += '-1M';
  }

  return result;
}

function formatSections(sections) {

  const LEFT_ROUND = '\ue0b6';
  const RIGHT_ARROW = '\ue0b0';
  const RIGHT_ROUND = '\ue0b4';

  const coloredSections = sections.map((section, index) => {
    const { text, bgColor, color } = section;
    const coloredSection = ansi(` ${text} `, bgColor, color);

    // First section does not need a leading right arrow
    if (index === 0) {
      return coloredSection;
    }

    const prevBgColor = sections[index - 1].bgColor;
    const prefix = `${ansi(RIGHT_ARROW, bgColor, prevBgColor)}`;
    return prefix + coloredSection;
  });

  return [
    `${ansi(LEFT_ROUND, 'rgb(0,0,0)', sections.at(0).bgColor)}`,
    ...coloredSections,
    `${ansi(RIGHT_ROUND, 'rgb(0,0,0)', sections.at(-1).bgColor)}`,
  ].join('');
}

try {
  const sections = [];

  // Read data from Claude Code stdin
  const input = JSON.parse(fs.readFileSync(0, 'utf-8'));
  
  const cwd = input.workspace.current_dir;
  const dirName = cwd.split('/').at(-1);
  sections.push({ text: dirName, bgColor: "rgb(52, 86, 164)" });

  const branch = getGitBranch();
  if (branch) {
    sections.push({ text: branch, bgColor: "rgb(70, 107, 62)" });
  }
  
  let model = formatModelName(input.model.display_name);

  // Add effort level if available
  if (input.effort?.level) {
    const effortMap = { low: 'lo', medium: 'md', high: 'hi', xhigh: 'xh', max: 'mx' };
    const effortCode = effortMap[input.effort.level] || input.effort.level;
    model += `:${effortCode}`;
  }

  sections.push({ text: model, bgColor: "rgb(68, 68, 68)" });

  // Quotas are not displayed here (the GNOME extension shows them), only cached
  const quotaData = parseRateLimits(input.rate_limits);
  if (quotaData) {
    writeQuotaCache(quotaData);
  }

  // Context window fill, red past the dumb zone threshold
  const contextWindow = input.context_window;
  if (contextWindow?.current_usage && contextWindow?.context_window_size) {
    const usage = contextWindow.current_usage;
    const currentTokens = (usage.input_tokens || 0) +
                          (usage.output_tokens || 0) +
                          (usage.cache_creation_input_tokens || 0) +
                          (usage.cache_read_input_tokens || 0);
    const contextSize = contextWindow.context_window_size;
    const ctxPercent = Math.round((currentTokens / contextSize) * 100);

    const isDumbZone = ctxPercent > CLAUDE_DUMB_ZONE;
    sections.push({
      text: `󰆪 ${ctxPercent}%`,
      bgColor: isDumbZone ? 'rgb(226, 0, 0)' : 'rgb(217, 119, 87)',
      color: isDumbZone ? 'rgb(255, 255, 255)' : 'rgb(0, 0, 0)',
    });
  }

  console.log(formatSections(sections));
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
