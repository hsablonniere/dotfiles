/**
 * Statusline Extension
 *
 * Replaces pi's footer with a segmented Powerline status bar
 * inspired by Claude Code, using the same RGB colors:
 *
 *    directory  branch  model:effort  󰆪 ctx%  12.3k 4.5k 
 *
 * Usage: /reload in pi
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// ============================================================
// ANSI helpers (custom RGB colors, not pi theme)
// ============================================================

const RESET = "\x1b[0m";

function ansi(text: string, bgColor: string, fgColor = "rgb(255, 255, 255)"): string {
	const bgV = bgColor.match(/\d+/g);
	const fgV = fgColor.match(/\d+/g);
	if (!bgV || !fgV) return text;
	const bg = `\x1b[48;2;${bgV.join(";")}m`;
	const fg = `\x1b[38;2;${fgV.join(";")}m`;
	return `${RESET}${bg}${fg}${text}${RESET}`;
}

// Powerline
const LEFT_ROUND = "\ue0b6";
const RIGHT_ARROW = "\ue0b0";
const RIGHT_ROUND = "\ue0b4";

// Nerd Font icons
const CTX_ICON = "\u{F01AA}"; // 󰆪
const UPLOAD = "\u{F062}"; //  (arrow up) — upload to LLM (input tokens)
const DOWNLOAD = "\u{F063}"; //  (arrow down) — download from LLM (output tokens)

// ============================================================
// Exact Claude Code statusline palette
// ============================================================

const C = {
	dirBg: "rgb(52, 86, 164)",
	dirFg: "rgb(255, 255, 255)",
	gitBg: "rgb(70, 107, 62)",
	gitFg: "rgb(255, 255, 255)",
	modelBg: "rgb(68, 68, 68)",
	modelFg: "rgb(255, 255, 255)",
	ctxBg: "rgb(217, 119, 87)",
	ctxFg: "rgb(0, 0, 0)",
	ctxDangerBg: "rgb(226, 0, 0)",
	ctxDangerFg: "rgb(255, 255, 255)",
	tokensBg: "rgb(55, 65, 80)",
	tokensFg: "rgb(200, 200, 220)",
};

const DANGER_ZONE = 59; // above this threshold, segment turns red

// ============================================================
// Types
// ============================================================

type TokenUsage = {
	input: number;
	output: number;
};

// ============================================================
// Helpers
// ============================================================

function computeTokens(ctx: ExtensionContext): TokenUsage {
	let input = 0,
		output = 0;
	for (const e of ctx.sessionManager.getBranch()) {
		if (e.type === "message" && "message" in e) {
			const m = e.message as AssistantMessage;
			if (m.role === "assistant" && m.usage) {
				input += m.usage.input ?? 0;
				output += m.usage.output ?? 0;
			}
		}
	}
	return { input, output };
}

function formatTokens(n: number): string {
	if (n < 1000) return `${n}`;
	if (n < 1_000_000) return `${(n / 1000).toFixed(1)}k`;
	return `${(n / 1_000_000).toFixed(1)}M`;
}


/** Shorten model name like Claude Code does. */
function formatModelName(name: string): string {
	// "Sonnet 4.6" → "S46", "Claude 3.5 Sonnet" → "C35"
	const m = name.match(/(\w+)\s+(\d+(?:\.\d+)+)/);
	if (m) {
		const init = m[1][0].toUpperCase();
		const ver = m[2].replace(/\./g, "");
		return `${init}${ver}${name.includes("1M") ? "-1M" : ""}`;
	}
	// "big-pickle" → "BP", "gpt-4o" → "G4"
	const parts = name.split(/[\s-_]+/).filter(Boolean);
	if (parts.length >= 2) {
		return parts.map((w) => w[0].toUpperCase()).join("").slice(0, 6);
	}
	// Fallback
	return name.replace(/[^a-zA-Z0-9]/g, "").slice(0, 4).toUpperCase();
}

/** Abbreviated thinking/effort level. */
function levelShort(level: string): string {
	const map: Record<string, string> = {
		off: "off",
		minimal: "min",
		low: "lw",
		medium: "m",
		high: "h",
		xhigh: "xh",
	};
	return map[level] ?? level;
}

// ============================================================
// Segments Powerline
// ============================================================

interface Seg {
	text: string;
	bg: string;
	fg: string;
}

function buildSegments(
	dirName: string,
	gitBranch: string | null,
	modelAbbr: string,
	lvlAbbr: string,
	ctxPct: number | null,
	tokens: TokenUsage,
): Seg[] {
	const segs: Seg[] = [];

	// 1. Directory name
	segs.push({ text: ` ${dirName} `, bg: C.dirBg, fg: C.dirFg });

	// 2. Git branch (if available)
	if (gitBranch) {
		segs.push({ text: ` ${gitBranch} `, bg: C.gitBg, fg: C.gitFg });
	}

	// 3. Model:effort
	const label = lvlAbbr && lvlAbbr !== "off"
		? ` ${modelAbbr}:${lvlAbbr} `
		: ` ${modelAbbr} `;
	segs.push({ text: label, bg: C.modelBg, fg: C.modelFg });

	// 4. Context %
	if (ctxPct !== null) {
		const danger = ctxPct > DANGER_ZONE;
		segs.push({
			text: ` ${CTX_ICON} ${ctxPct}% `,
			bg: danger ? C.ctxDangerBg : C.ctxBg,
			fg: danger ? C.ctxDangerFg : C.ctxFg,
		});
	}

	// 5. Tokens (input / output)
	if (tokens.input > 0 || tokens.output > 0) {
		const tIn = tokens.input > 0 ? `${UPLOAD}${formatTokens(tokens.input)}` : "";
		const tOut = tokens.output > 0 ? `${DOWNLOAD}${formatTokens(tokens.output)}` : "";
		const sep = tIn && tOut ? " " : "";
		segs.push({
			text: ` ${tIn}${sep}${tOut} `,
			bg: C.tokensBg,
			fg: C.tokensFg,
		});
	}

	return segs;
}

function renderSegments(segs: Seg[]): string {
	if (segs.length === 0) return "";

	const capL = ansi(LEFT_ROUND, "rgb(0,0,0)", segs[0].bg);

	const middle = segs.map((seg, i) => {
		const body = ansi(seg.text, seg.bg, seg.fg);
		if (i === 0) return body;
		const arrow = ansi(RIGHT_ARROW, seg.bg, segs[i - 1].bg);
		return arrow + body;
	});

	const capR = ansi(RIGHT_ROUND, "rgb(0,0,0)", segs[segs.length - 1].bg);

	return [capL, ...middle, capR].join("");
}

// ============================================================
// Extension
// ============================================================

export default function statuslineExtension(pi: ExtensionAPI) {
	let tuiRef: { requestRender: () => void } | null = null;

	function render(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;
		refreshFooter(ctx);
	}

	function refreshFooter(ctx: ExtensionContext) {
		ctx.ui.setFooter((tui, _theme, footerData) => {
			tuiRef = tui;
			const unsubBranch = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: () => {
					unsubBranch();
					tuiRef = null;
				},
				invalidate() {},
				render(width: number): string[] {
					// Directory (last segment of cwd)
					const cwd = process.cwd();
					const dirName = cwd.split("/").filter(Boolean).pop() ?? cwd;

					// Git branch (reactive via footerData)
					const gitBranch = footerData.getGitBranch();

					// Model
					const model = ctx.model;
					const modelAbbr = model
						? formatModelName(model.name ?? model.id ?? "?")
						: "?";

					// Thinking/effort level
					const lvl = pi.getThinkingLevel();
					const lvlAbbr = levelShort(typeof lvl === "string" ? lvl : "off");

					// Context usage percentage
					let ctxPct: number | null = null;
					try {
						const usage = ctx.getContextUsage();
						if (usage && typeof usage.percent === "number") {
							ctxPct = Math.round(usage.percent);
						}
					} catch {
						// Silently ignore if getContextUsage is not available
					}

					// Token counts
					const tokens = computeTokens(ctx);

					// Build segments
					const segs = buildSegments(dirName, gitBranch, modelAbbr, lvlAbbr, ctxPct, tokens);
					const line = renderSegments(segs);

					// Truncate if line exceeds terminal width
					const dw = visibleWidth(line);
					return dw > width ? [truncateToWidth(line, width)] : [line + RESET];
				},
			};
		});
	}

	function rerender() {
		if (tuiRef) tuiRef.requestRender();
	}

	// --- Events ---

	pi.on("session_start", (_event, ctx) => {
		render(ctx);
	});

	pi.on("turn_start", (_event, ctx) => {
		rerender();
	});

	pi.on("turn_end", (_event, _ctx) => {
		rerender();
	});

	pi.on("agent_end", (_event, _ctx) => {
		rerender();
	});

	pi.on("model_select", (_event, ctx) => {
		render(ctx);
	});

	pi.on("thinking_level_select", (_event, ctx) => {
		render(ctx);
	});

	pi.on("session_shutdown", (_event, ctx) => {
		tuiRef = null;
		if (ctx.hasUI) ctx.ui.setFooter(undefined);
	});
}
