// Keyboard navigation helpers, driven from keys.json:
// - "tab-prev" / "tab-next": move the shown tab one position left or right.
// - "space-<n>": show the n-th top-level space, skipping git worktree spaces
//   (folders under ~/.herdr/worktrees/), so numbers match the main spaces.
// - "panel-files" / "panel-changes": toggle the right side panel on that tab.
// - "focus": toggle full screen: zoom the focused pane and hide sidebar, tab bar and status bar.
// Key commands only reach shown copies, so this mod docks as an empty block.
import { View, div } from "gpui-kit";
import { spaces, panes, run, nextCommand, layout } from "herdr";

const WORKTREES = "/.herdr/worktrees/";
const CHROME = ["sidebar", "tabs"];

export default class Nav extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      for (;;) {
        const command = await nextCommand();
        if (command === "tab-prev") this.moveTab(-1);
        else if (command === "tab-next") this.moveTab(1);
        else if (command.startsWith("panel-")) this.togglePanel(command.slice(6));
        else if (command === "focus") this.toggleFocus();
        else if (command.startsWith("space-")) this.showSpace(Number(command.slice(6)));
      }
    });
  }

  toggleFocus() {
    this.focusMode = !this.focusMode;
    for (const id of CHROME) run(this.focusMode ? "layout.hide" : "layout.show", { id });
    const zoomed = panes().some((p) => p.focused && p.zoomed);
    if (this.focusMode !== zoomed) run("pane.zoom", {});
  }

  togglePanel(id) {
    const find = (node, wanted) => node?.id === wanted ? node : (node?.children ?? []).map((c) => find(c, wanted)).find(Boolean) ?? null;
    const root = layout(), panel = find(root, "panel"), body = find(root, "panel-body");
    if (panel && !panel.hidden && body?.active === id) run("layout.hide", { id: "panel" });
    else { run("layout.select", { stack: "panel-body", child: id }); run("layout.show", { id: "panel" }); }
  }

  moveTab(delta) {
    const space = spaces().find((s) => s.active);
    const tab = space?.tabs.find((t) => t.active);
    if (!tab) return;
    const index = tab.index + delta;
    if (index < 1 || index > space.tabs.length) return;
    run("tab.move", { id: tab.id, index });
  }

  showSpace(n) {
    const main = spaces().filter((s) => s.machine === null && !s.folder.includes(WORKTREES));
    const space = main[n - 1];
    if (space) run("space.select", { id: space.id });
  }

  render() {
    return div().id("nav").size_0();
  }
}
