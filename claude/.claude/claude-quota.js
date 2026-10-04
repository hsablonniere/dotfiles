#!/usr/bin/env node

const fs = require('fs');

// Written by statusline.js from the `rate_limits` payload sent by Claude Code.
const CACHE_FILE = '/tmp/claude-quota-cache.json';
const SEVEN_DAYS = 7 * 24 * 60 * 60 * 1000;

/** @typedef {Object} CacheData
 * @property {string} fetchedAt
 * @property {{quota: number, resetsAt: string}} session
 * @property {{quota: number, resetsAt: string}} weekly
 */

/**
 * @param {any} data
 * @returns {data is CacheData}
 */
function isValidCacheData(data) {
  return (
    data !== null &&
    typeof data === 'object' &&
    typeof data.fetchedAt === 'string' &&
    typeof data.session?.quota === 'number' &&
    typeof data.session?.resetsAt === 'string' &&
    typeof data.weekly?.quota === 'number' &&
    typeof data.weekly?.resetsAt === 'string'
  );
}

/**
 * @returns {CacheData | null}
 */
function readCache() {
  try {
    const raw = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf-8'));
    return isValidCacheData(raw) ? raw : null;
  } catch {
    return null;
  }
}

/**
 * @param {string} isoString
 * @returns {{time: string, day: string}}
 */
function formatTime(isoString) {
  const date = new Date(isoString);
  const time = date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
  const day = date.toLocaleDateString('en-US', { weekday: 'long' });
  return { time, day: day.charAt(0).toUpperCase() + day.slice(1) };
}

/**
 * @param {string} isoString
 * @returns {string}
 */
function formatRemaining(isoString) {
  const diff = Math.max(0, new Date(isoString).getTime() - Date.now());
  const hours = Math.floor(diff / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  return `${hours}h${minutes}min`;
}

/**
 * @param {number} ageSeconds
 * @returns {string}
 */
function formatAge(ageSeconds) {
  const minutes = Math.floor(ageSeconds / 60);
  if (minutes < 1) return 'less than a minute ago';
  if (minutes < 60) return `${minutes} min ago`;
  return `${Math.floor(minutes / 60)}h${String(minutes % 60).padStart(2, '0')} ago`;
}

/**
 * @param {string} resetsAt - ISO date string for weekly quota reset
 * @returns {number} Ideal usage percentage based on elapsed time in the week
 */
function computeIdealPercent(resetsAt) {
  const timeRemaining = Math.max(0, new Date(resetsAt).getTime() - Date.now());
  return Math.round(((SEVEN_DAYS - timeRemaining) / SEVEN_DAYS) * 100);
}

/**
 * @param {CacheData} data
 * @returns {number}
 */
function getAgeSeconds(data) {
  return Math.max(0, Math.round((Date.now() - new Date(data.fetchedAt).getTime()) / 1000));
}

/**
 * @param {CacheData} data
 */
function printHuman(data) {
  const sessionTime = formatTime(data.session.resetsAt);
  const weeklyTime = formatTime(data.weekly.resetsAt);
  const sessionRemaining = formatRemaining(data.session.resetsAt);
  const fetchedTime = new Date(data.fetchedAt).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });

  console.log(`Data from ${fetchedTime} (${formatAge(getAgeSeconds(data))})\n`);
  console.log(`Session quota: ${data.session.quota}% used`);
  console.log(`Resets in ${sessionRemaining} at ${sessionTime.time}\n`);
  console.log(`Weekly quota: ${data.weekly.quota}% used (ideal: ${computeIdealPercent(data.weekly.resetsAt)}%)`);
  console.log(`Resets at ${weeklyTime.time} on ${weeklyTime.day} ${new Date(data.weekly.resetsAt).getDate()}`);
}

/**
 * @param {CacheData} data
 */
function printJson(data) {
  console.log(JSON.stringify({
    fetchedAt: data.fetchedAt,
    ageSeconds: getAgeSeconds(data),
    session: { quota: data.session.quota, resetsAt: data.session.resetsAt },
    weekly: {
      quota: data.weekly.quota,
      resetsAt: data.weekly.resetsAt,
      idealPercent: computeIdealPercent(data.weekly.resetsAt),
    },
  }));
}

function main() {
  const isJson = process.argv.slice(2).includes('--json');
  const data = readCache();

  if (!data) {
    console.error('Error: no quota data yet, the statusline has not received `rate_limits` from Claude Code');
    process.exit(1);
  }

  if (isJson) {
    printJson(data);
  } else {
    printHuman(data);
  }
}

main();
