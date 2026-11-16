// Tell scripts/herdr-pin.sh which opencode session to resume when this
// terminal is pinned. Does nothing outside a pinned Herdr terminal.
import { execFile } from "node:child_process";
import os from "node:os";
import path from "node:path";

const script = path.join(os.homedir(), "dotfiles", "scripts", "herdr-pin.sh");
const childSessions = new Set();
let lastSessionID;

function pin(sessionID) {
  if (!sessionID || sessionID === lastSessionID || childSessions.has(sessionID)) return;
  lastSessionID = sessionID;
  execFile(script, ["--set", "opencode", "--session", sessionID], () => {});
}

export const HerdrPinPlugin = async () => {
  if (!process.env.HC_TERMINAL_ID) return {};
  return {
    "chat.message": async ({ sessionID }) => pin(sessionID),
    event: async ({ event }) => {
      const info = event?.properties?.info;
      if (info?.id && info.parentID) childSessions.add(info.id);
    },
  };
};
