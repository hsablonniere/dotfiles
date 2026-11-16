#!/usr/bin/env node

const fs = require('node:fs');
const { execSync } = require('node:child_process');

const CLAUDE_DUMB_ZONE = 59;
const QUOTA_CACHE_FILE = '/tmp/claude-quota-cache.json';
// Prompt cache: warn this many seconds before it goes cold, and show a miss this long after it happened
const CACHE_WARN_SECONDS = 10 * 60;
const CACHE_MISS_SHOWN_SECONDS = 5 * 60;

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

function formatTokens(tokens) {
  return tokens >= 1000 ? `${Math.round(tokens / 1000)}k` : String(tokens);
}

/**
 * The prompt cache segment, shown only when it matters: a recent miss and its cause, the cache gone cold (with what
 * the next request re-sends), or the minutes left before it does. Null otherwise.
 */
function promptCacheSection(cache) {
  if (!cache?.caching_observed) return null;
  const now = Date.now() / 1000;

  if (cache.last_miss_at && now - cache.last_miss_at < CACHE_MISS_SHOWN_SECONDS) {
    const cause = cache.last_miss_cause?.causes?.join(', ') || 'unknown';
    return { text: `cache miss: ${cause}`, bgColor: 'rgb(198, 120, 221)', color: 'rgb(0, 0, 0)' };
  }

  const isCold = !cache.warm || (cache.expires_at && cache.expires_at <= now);
  if (isCold) {
    const resend = cache.recache_tokens_if_cold ? ` ${formatTokens(cache.recache_tokens_if_cold)}` : '';
    return { text: `cache cold${resend}`, bgColor: 'rgb(226, 0, 0)' };
  }

  const left = cache.expires_at - now;
  if (left <= CACHE_WARN_SECONDS) {
    return { text: `cache ${Math.max(1, Math.ceil(left / 60))}m`, bgColor: 'rgb(229, 192, 123)', color: 'rgb(0, 0, 0)' };
  }

  return null;
}

function toHex(rgb) {
  return `#${rgb.match(/\d+/g).map((n) => Number(n).toString(16).padStart(2, '0')).join('')}`;
}

/**
 * Shares the model, context and cache sections with the Herdr pane status bar (mod my-pane-status),
 * which draws them itself under the agent pane. Keyed by the Herdr terminal id, best effort.
 */
function writeHerdrState(sections, cwd) {
  const terminal = process.env.HC_TERMINAL_ID;
  const runtime = process.env.XDG_RUNTIME_DIR;
  if (!terminal || !runtime) return;
  try {
    const dir = `${runtime}/herdr-status`;
    fs.mkdirSync(dir, { recursive: true });
    const tmp = `${dir}/.${terminal}.agent.${process.pid}`;
    const payload = sections.map(({ text, bgColor, color }) => ({
      text,
      bg: toHex(bgColor),
      fg: color ? toHex(color) : '#ffffff',
    }));
    // Same directory and git detail as the shell prompt (see scripts/herdr-status.sh)
    let dirInfo = {};
    try {
      dirInfo = JSON.parse(execSync(`"$HOME/dotfiles/scripts/herdr-status.sh" --info "${cwd}"`, { encoding: 'utf-8' }));
    } catch {
      // Falls back to the pane folder in the mod
    }
    fs.writeFileSync(tmp, JSON.stringify({ ...dirInfo, sections: payload }));
    fs.renameSync(tmp, `${dir}/${terminal}.agent.json`);
  } catch {
    // Best effort
  }
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
  
  const herdrFrom = sections.length;
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

  const cacheSection = promptCacheSection(input.prompt_cache);
  if (cacheSection) {
    sections.push(cacheSection);
  }

  writeHerdrState(sections.slice(herdrFrom), cwd);
  // Inside Herdr the pane status bar (mod my-pane-status) shows these sections: print nothing
  if (!process.env.HC_TERMINAL_ID) {
    console.log(formatSections(sections));
  }
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
