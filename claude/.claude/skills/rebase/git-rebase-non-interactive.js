#!/usr/bin/env node

const { execSync } = require('child_process');

const target = process.argv[2];

if (!target) {
  console.error('Usage: git-rebase-non-interactive.js <target> << EOF');
  console.error('Example: ./git-rebase-non-interactive.js HEAD~5 << \'EOF\'');
  console.error('pick abc123 First commit');
  console.error('drop def456 Remove this');
  console.error('EOF');
  process.exit(1);
}

let todo = '';

process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => todo += chunk);
process.stdin.on('end', () => {
  // Échappe les single quotes pour le shell: ' devient '"'"'
  const escaped = todo.replace(/'/g, "'\"'\"'");

  execSync(`git rebase -i ${target}`, {
    stdio: 'inherit',
    env: {
      ...process.env,
      GIT_SEQUENCE_EDITOR: `printf '%s' '${escaped}' >`
    }
  });
});
