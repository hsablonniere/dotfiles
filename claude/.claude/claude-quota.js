#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');
const { URL } = require('url');

/** @typedef {Object} CacheData
 * @property {string} fetchedAt
 * @property {{quota: number, resetsAt: string}} session
 * @property {{quota: number, resetsAt: string}} weekly
 */

/** @typedef {Object} ApiResponse
 * @property {{utilization: number, resets_at: string}} five_hour
 * @property {{utilization: number, resets_at: string}} seven_day
 */

const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
const CACHE_FILE = '/tmp/claude-quota-cache.json';
const CREDENTIALS_FILE = path.join(process.env.HOME || '', '.claude', '.credentials.json');

/**
 * @returns {number} Cache age in milliseconds
 */
function getCacheAge() {
  if (!fs.existsSync(CACHE_FILE)) return Infinity;
  const stat = fs.statSync(CACHE_FILE);
  return Date.now() - stat.mtime.getTime();
}

/**
 * @param {any} data
 * @returns {data is CacheData}
 */
function isValidCacheData(data) {
  return (
    data !== null &&
    typeof data === 'object' &&
    data.session !== undefined &&
    data.session !== null &&
    typeof data.session === 'object' &&
    typeof data.session.quota === 'number' &&
    typeof data.session.resetsAt === 'string' &&
    data.weekly !== undefined &&
    data.weekly !== null &&
    typeof data.weekly === 'object' &&
    typeof data.weekly.quota === 'number' &&
    typeof data.weekly.resetsAt === 'string'
  );
}

/**
 * @returns {CacheData | null}
 */
function readCache() {
  if (getCacheAge() < CACHE_TTL && fs.existsSync(CACHE_FILE)) {
    try {
      const raw = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf-8'));
      if (isValidCacheData(raw)) {
        return raw;
      }
      // Cache is corrupted / invalid, remove it
      fs.unlinkSync(CACHE_FILE);
      return null;
    } catch {
      return null;
    }
  }
  return null;
}

/**
 * @param {CacheData} data
 */
function writeCache(data) {
  fs.writeFileSync(CACHE_FILE, JSON.stringify(data, null, 2));
}

/**
 * @returns {{token: string | undefined, expiresAt: number | undefined}}
 */
function readTokenInfo() {
  const credentials = JSON.parse(fs.readFileSync(CREDENTIALS_FILE, 'utf-8'));
  return {
    token: credentials.claudeAiOauth?.accessToken,
    expiresAt: credentials.claudeAiOauth?.expiresAt,
  };
}

/**
 * @returns {Promise<ApiResponse>}
 */
function fetchFromApi() {
  return new Promise((resolve, reject) => {
    try {
      const { token, expiresAt } = readTokenInfo();

      if (!token) {
        throw new Error('No access token found in credentials');
      }

      if (expiresAt && Date.now() > expiresAt) {
        throw new Error('Authentication token expired. Run `claude` to refresh it, then try again.');
      }

      const url = new URL('https://api.anthropic.com/api/oauth/usage');
      const options = {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'anthropic-beta': 'oauth-2025-04-20',
          'Content-Type': 'application/json',
        },
      };

      const req = https.request(url, options, (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            if (res.statusCode !== 200) {
              const msg = typeof parsed.error === 'string'
                ? parsed.error
                : (parsed.message || JSON.stringify(parsed.error || parsed));
              return reject(new Error(`API returned ${res.statusCode}: ${msg}`));
            }
            if (parsed.five_hour?.utilization == null || parsed.seven_day?.utilization == null) {
		    console.error(res.statusCode, data);
              return reject(new Error('Invalid API response format: missing quota data'));
            }
            resolve(parsed);
          } catch (error) {
            reject(new Error(`Failed to parse API response: ${error.message}`));
          }
        });
      });

      req.on('error', reject);
      req.end();
    } catch (error) {
      reject(error);
    }
  });
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
  const now = Date.now();
  const resetTime = new Date(isoString).getTime();
  const diff = Math.max(0, resetTime - now);
  const hours = Math.floor(diff / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  return `${hours}h${minutes}min`;
}

/**
 * @param {string} resetsAt - ISO date string for weekly quota reset
 * @returns {number} Ideal usage percentage based on elapsed time in the week
 */
function computeIdealPercent(resetsAt) {
  const now = Date.now();
  const resetTime = new Date(resetsAt).getTime();
  const SEVEN_DAYS = 7 * 24 * 60 * 60 * 1000;
  const timeRemaining = Math.max(0, resetTime - now);
  return Math.round(((SEVEN_DAYS - timeRemaining) / SEVEN_DAYS) * 100);
}

/**
 * @param {CacheData} data
 */
function printHuman(data) {
  const sessionTime = formatTime(data.session.resetsAt);
  const weeklyTime = formatTime(data.weekly.resetsAt);
  const sessionRemaining = formatRemaining(data.session.resetsAt);

  console.log(`Session quota: ${data.session.quota}% used`);
  console.log(`Resets in ${sessionRemaining} at ${sessionTime.time}\n`);
  console.log(`Weekly quota: ${data.weekly.quota}% used (ideal: ${data.weekly.idealPercent ?? computeIdealPercent(data.weekly.resetsAt)}%)`);
  console.log(`Resets at ${weeklyTime.time} on ${weeklyTime.day} ${new Date(data.weekly.resetsAt).getDate()}`);
}

/**
 * @param {CacheData} data
 */
function printJson(data) {
  console.log(JSON.stringify({
    session: { quota: data.session.quota, resetsAt: data.session.resetsAt },
    weekly: {
      quota: data.weekly.quota,
      resetsAt: data.weekly.resetsAt,
      idealPercent: computeIdealPercent(data.weekly.resetsAt),
    },
  }));
}

/**
 * Main function
 */
async function main() {
  const args = process.argv.slice(2);
  const isJson = args.includes('--json');

  let data = readCache();

  if (!data) {
    try {
      const apiData = await fetchFromApi();
      data = {
        fetchedAt: new Date().toISOString(),
        session: {
          quota: apiData.five_hour.utilization,
          resetsAt: apiData.five_hour.resets_at,
        },
        weekly: {
          quota: apiData.seven_day.utilization,
          resetsAt: apiData.seven_day.resets_at,
          idealPercent: computeIdealPercent(apiData.seven_day.resets_at),
        },
      };
      writeCache(data);
    } catch (error) {
      const msg = error.message;
      const isAuthError = msg.includes('401') || msg.includes('Authentication token expired');
      if (isAuthError) {
        try { fs.unlinkSync(CACHE_FILE); } catch {}
      }
      console.error(`Error: ${error.message}`);
      process.exit(1);
    }
  }

  if (isJson) {
    printJson(data);
  } else {
    printHuman(data);
  }
}

main().catch((error) => {
  console.error(`Error: ${error.message}`);
  process.exit(1);
});
