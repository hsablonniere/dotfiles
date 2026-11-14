// Keyboard navigation helpers, driven from keys.json:
// - "tab-prev" / "tab-next": move the shown tab one position left or right.
// - "space-<n>": show the n-th top-level space, skipping git worktree spaces
//   (folders under ~/.herdr/worktrees/), so numbers match the main spaces.
// Key commands only reach shown copies, so this mod docks as an empty block.
import { View, div } from "gpui-kit";
import { spaces, run, nextCommand } from "herdr";

const WORKTREES = "/.herdr/worktrees/";

export default class Nav extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      for (;;) {
        const command = await nextCommand();
        if (command === "tab-prev") this.moveTab(-1);
        else if (command === "tab-next") this.moveTab(1);
        else if (command.startsWith("space-")) this.showSpace(Number(command.slice(6)));
      }
    });
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
