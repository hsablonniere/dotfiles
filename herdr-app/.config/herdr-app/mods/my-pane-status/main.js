// Starship-like powerline status for a shell pane, drawn as the pane's bottom header:
//   { "tab": "active", "pane": { "header": { "content": { "mod": "my-pane-status" }, "height": 26, "position": "bottom", "reveal": "always" } } }
// Shown under every terminal pane (shell, agent, TUI). Agent panes add the model, context and cache
// pills that Claude's statusline.js writes in <terminal>.agent.json.
// The data comes from fish: scripts/herdr-status.sh writes <terminal>.json in
// $XDG_RUNTIME_DIR/herdr-status at every prompt and this mod watches that folder.
// Rounded pills in the terminal font, same segments and colors as the `statusbar` profile of starship.toml.
// Props from the app: { pane, terminal }.
import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { panes, props, exec, home, readTextFile, watchFolder, settings, theme } from "herdr";

const LOCK = "mods/my-pane-status/lock.svg";
const C = { dir: "#3456a4", git: "#466b3e", node: "#339933", sudo: "#e2e200", op: "#293f71", status: "#e20000", duration: "#ad3c9e" };
const CAP_LEFT = "", CAP_RIGHT = "", ARROW_RIGHT = "", ARROW_LEFT = "";

function folder(cwd) {
  const h = home();
  return cwd === h ? "~" : cwd.startsWith(h + "/") ? "~" + cwd.slice(h.length) : cwd;
}

// Same order and symbols as starship's git_status.
function gitText(g) {
  const parts = [g.branch || "HEAD", g.hash];
  let s = "";
  if (g.conflicted) s += `${g.conflicted}`;
  if (g.deleted) s += `D${g.deleted}`;
  if (g.renamed) s += `R${g.renamed}`;
  if (g.modified) s += `M${g.modified}`;
  if (g.staged) s += `S${g.staged}`;
  if (g.untracked) s += `?${g.untracked}`;
  if (g.ahead && g.behind) s += `${g.behind}${g.ahead}`;
  else if (g.ahead) s += `${g.ahead}`;
  else if (g.behind) s += `${g.behind}`;
  if (s) parts.push(s);
  return parts.filter(Boolean).join(" ");
}

export default class PaneStatus extends View {
  init(_props, cx) {
    this.data = null;
    this.agent = null;
    cx.spawn(async (cx) => {
      const r = await exec("sh", ["-c", 'd="${XDG_RUNTIME_DIR:-/tmp}/herdr-status"; mkdir -p "$d" && printf %s "$d"']);
      const dir = r.stdout.trim();
      if (!dir) return;
      for (;;) {
        const t = props()?.terminal;
        const text = t ? await readTextFile(`${dir}/${t}.json`) : null;
        try { this.data = text ? JSON.parse(text) : null; } catch (_e) { this.data = null; }
        const agentText = t ? await readTextFile(`${dir}/${t}.agent.json`) : null;
        try { this.agent = agentText ? JSON.parse(agentText) : null; } catch (_e) { this.agent = null; }
        cx.notify();
        await watchFolder(dir);
      }
    });
  }

  me() {
    return panes().find((p) => p.pane === props()?.pane);
  }

  pill(text, bg, fg = "#ffffff", bold = false, icon = null) {
    return h_flex().flex_none().items_center().gap(5).px(8).py(1).rounded(6).bg(bg).text_color(fg).when(bold, (el) => el.font_bold())
      .when(Boolean(icon), (el) => el.child(svg(icon).size(12).flex_none()))
      .child(text);
  }

  // Same bar for every terminal pane: directory, git and node, then what Claude adds for an agent
  // (model, effort, context, cache). Only a plain shell on the main screen also shows the last
  // command's status, duration, sudo and 1Password, which would be stale under a running program.
  render() {
    const p = this.me();
    if (!p?.terminal || !p.cwd) return div();
    // `app` stays set after an agent exits, so it only counts while the foreground program is not a shell
    const agent = Boolean(p.program?.agent || (p.app && !p.program?.shell));
    const plainShell = !agent && p.program?.shell && p.scroll !== null;

    // Shell data of a previous directory is ignored until fish writes the new one.
    const d = this.data?.cwd === p.cwd ? this.data : null;
    const a = agent ? this.agent : null;
    const dir = a?.dir ?? d?.dir ?? folder(p.cwd);
    const readonly = a ? a.readonly : d?.readonly;
    const git = a?.git ?? (d ? d.git : p.branch ? { branch: p.branch } : null);

    const left = [{ text: dir, bg: C.dir, icon: readonly ? LOCK : null }];
    if (git) left.push({ text: gitText(git), bg: C.git });
    if (d?.node) left.push({ text: d.node, bg: C.node });
    for (const s of a?.sections ?? []) left.push({ text: s.text, bg: s.bg, fg: s.fg });

    const right = [];
    if (plainShell && d) {
      if (d.code) right.push({ text: `\u{f1398}${d.signal ? " " + d.signal : ""}`, bg: C.status });
      if (d.duration) right.push({ text: d.duration, bg: C.duration });
      if (d.sudo) right.push({ text: "sudo", bg: C.sudo, fg: "#000000", bold: true });
      if (d.op) right.push({ text: "1Password", bg: C.op });
    }

    const row = h_flex().id(`pane-status-${p.pane}`).size_full().px(3.5).gap(6).items_center().border_t(1).border_color(theme().border)
      .font_family(settings().font_family ?? "JetBrains Mono").text_size(12).whitespace_nowrap().overflow_hidden();
    for (const s of left) row.child(this.pill(s.text, s.bg, s.fg, false, s.icon));
    row.child(div().flex_1());
    for (const s of right) row.child(this.pill(s.text, s.bg, s.fg, s.bold));
    return row;
  }
}
