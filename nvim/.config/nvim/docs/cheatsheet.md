# Neovim cheatsheet

Personal notes for this config, especially the habits that replace my
WebStorm shortcuts. `<leader>` is `Space`.

Lost? Press a prefix key (`Space`, `g`, `z`, `[`, `]`...) and wait: a menu lists every
possible continuation. `Space s k` searches all keymaps.

## Search (Snacks picker)

The "project" is the git root of the current file, or the working directory outside a repo.

| Keys | Action | WebStorm habit it replaces |
|---|---|---|
| `Space Space` | Files in the project | `Alt+é` (GotoFile) |
| `Space s f` | Files in the project (same as above) | |
| `Space s g` | Live grep in the project | `Ctrl+Shift+F` (Find in Path) |
| `Space s c` | Classes and interfaces in the project (LSP) | `Alt+&` (GotoClass) |
| `Space s S` | Symbols in the project (LSP) | `Alt+"` (GotoSymbol) |
| `Space s s` | Symbols in the current file (LSP) | |
| `Space s a` | Actions (all commands) | `Alt+Z` (GotoAction) |
| `Space s b` | Open buffers | |
| `Space s r` | Resume the last search where it was left | |
| `Space s .` | Recently opened files | |
| `Space s h` | Neovim help | |
| `Space s k` | All keymaps | |

`:lua Snacks.picker()` alone opens a menu of every available picker.

Class and symbol searches need a language server attached to the buffer, they stay empty
otherwise.

### Inside a picker

| Keys | Action |
|---|---|
| type | Fuzzy filter |
| `Enter` | Open |
| `Ctrl+V` | Open in a vertical split |
| `Ctrl+S` | Open in a horizontal split |
| `Ctrl+T` | Open in a new tab |
| `Tab` | Select several items (then `Enter` opens them all) |
| `Ctrl+Q` | Send the results to the quickfix list |
| `Alt+H` | Show / hide hidden files |
| `Alt+I` | Show / hide git-ignored files |
| `Alt+P` | Show / hide the preview |
| `Esc` | Close |

## File explorer (neo-tree)

`Alt+A` opens the file tree in a sidebar on the right, unfolded down to the current file.
`q` closes it. Git-ignored files and `.git` are hidden.

| Keys (in the explorer) | Action |
|---|---|
| `Enter` | Open the file, expand / collapse the folder |
| `→` | Open a closed folder, or go to the first item of an open one |
| `←` | Close an open folder, or go to the parent folder |
| `Space` | Expand / collapse the folder |
| `s` / `S` | Open in a vertical / horizontal split |
| `P` | Preview the file without leaving the explorer |
| `/` | Fuzzy filter the tree |
| `a` | Create a file (end with `/` for a folder) |
| `r` | Rename (imports are updated through the language server) |
| `d` | Delete |
| `c` / `m` | Copy / move to another path (a move updates imports too) |
| `y` / `x` / `p` | Copy / cut / paste |
| `H` | Show / hide hidden and git-ignored files |
| `Backspace` / `.` | Go up to the parent folder / make the folder under the cursor the root |
| `z` | Collapse all folders |
| `?` | Help with all keys |

## Outline (neo-tree)

`Alt+Shift+A` opens the structure of the current file (language server symbols) in
a sidebar on the left, fully unfolded. Needs a language server attached
to the buffer. Imports and local variables show too (no finer filtering).

| Keys (in the outline) | Action |
|---|---|
| `Enter` / `o` | Jump to the symbol |
| `→` / `←` | Same tree navigation as the file explorer |
| `/` | Fuzzy filter the symbols |
| `q` | Close |

## Code intelligence (LSP)

Native Neovim defaults, available when a language server is attached to the buffer (its name
shows at the right of the tabline, e.g. `luals`, `tsc`). All in normal mode, cursor on a symbol.

| Keys | Action |
|---|---|
| `K` | Documentation popup. Press `K` again to jump into it and scroll, `q` to close |
| `gd` | Go to definition (`Ctrl+O` to jump back). `Ctrl+]` works too |
| `grn` | Rename the symbol everywhere |
| `gra` | Code actions, quick fixes |
| `grr` | Usages (picker), without the declaration and the import lines |
| `grR` | All references (picker), imports included |
| `gri` | Implementations (picker) |
| `grt` | Type definition (picker) |
| `gO` | Symbols of the current file |
| `[d` / `]d` | Previous / next diagnostic |
| `Space d` | Full message of the diagnostic under the cursor |
| `Space s d` | All diagnostics of the project (picker, like WebStorm's Problems) |
| `Space t h` | Toggle inlay hints (inferred types and parameter names shown inline) |
| `Ctrl+S` (insert mode) | Signature of the function being called |

Pickers jump directly when there is a single result.

While a server is working (indexing a project...), its name in the tabline shows `…` or a
percentage, e.g. `tsc 45%`.

Language servers are installed by mason (`:Mason` to see them), except `rust-analyzer`
(`rustup component add rust-analyzer`).

## Completion (blink.cmp)

The menu opens on `Ctrl+Space` only, never while typing, with LSP items, file paths, snippets and words of the buffer. The
documentation of the selected item shows next to it, and a grey preview in the code.

| Keys (insert mode) | Action |
|---|---|
| `Enter` / `Tab` | Accept the selected item (the first one by default) |
| `Ctrl+N` / `Ctrl+P`, `↓` / `↑` | Next / previous item |
| `Ctrl+Space` | Open the menu |
| `Ctrl+E` | Close the menu |
| `Tab` / `Shift+Tab` | Next / previous snippet placeholder (menu closed) |

While typing function arguments, the signature shows with the current parameter highlighted.

## Snippets

Type the prefix, then accept it from the completion menu. Placeholders are filled in order with
`Tab`. Hundreds of ready-made snippets are listed in [snippets.md](snippets.md).

My own snippets, ported from my WebStorm live templates. They live in `../snippets/` (VS Code
format, one JSON file per language).

### JavaScript and TypeScript

| Prefix | Expands to |
|---|---|
| `log` | `console.log()` |
| `logj` | `console.log(JSON.stringify(…, null, '  '))` |
| `if` | `if (cond) { }` |
| `rt` | `return ` |
| `aa` | Arrow function with an expression body `(args) => ` |
| `aaa` | Arrow function with a block body `(args) => { }` |
| `ff` | Named function `function name (args) { }` |
| `i` | `import '…';` |
| `ii` | `import { names } from '…';` |
| `z` | `.then()` |
| `pp` | `.then(console.log).catch(console.error)` |
| `.sub` | `.subscribe((param) => {})` |
| `dqs` / `dqsa` | `document.querySelector('…')` / `querySelectorAll('…')` |
| `dce` | `document.createElement('tag');` |
| `rrd` | Random string `Math.random().toString(36).slice(2)` |
| `dd` | `describe('label', () => { })` |
| `it` | `it('label', () => { })` |
| `test` | `test('name', () => { });` |
| `wc` | Lit component: class, properties, render, styles, `customElements.define` |
| `iff` | Lit ternary block `` ${cond ? html`…` : ''} `` |
| `i18n` | Translation entry `` 'component.key': `value`, `` |
| `i18nn` | Translation entry with params `` 'component.key': ({ params }) => `value`, `` |
| `hi18n` | Translation call in a template `${i18n('component.key')}` |
| `smod` | `<script type="module" src="…"></script>` |
| `jj` | Inline JSDoc type `/** @type {…} */` (JavaScript only) |
| `td` | JSDoc typedef import `@typedef {import('path').Var} Var` (JavaScript only) |

`wc`: the tag name is a separate placeholder, `my-component` by default. WebStorm derived it from
the class name, VS Code snippets in Neovim cannot.

`hi18n` is WebStorm's HTML `i18n` template, renamed because it clashes with the JavaScript one.

### HTML

| Prefix | Expands to |
|---|---|
| `!` | HTML5 page skeleton with a title |
| `smod`, `iff`, `hi18n` | Same as in JavaScript |

### CSS

| Prefix | Expands to |
|---|---|
| `vv` | `var(--…)` |
| `cc` | `calc(…)` |
| `dg` | `display: grid;` |

### Everywhere

| Prefix | Expands to |
|---|---|
| `Lorem` | A long lorem ipsum paragraph |
| `:tools` | 🛠️ emoji |

## Syntax (Treesitter)

Precise syntax highlighting, including HTML and CSS inside Lit `html` and `css` tagged templates.
The parser of a new language is installed automatically the first time a file of that language
is opened. `:TSUpdate` updates parsers (done automatically when the plugin updates).

| Keys | Action |
|---|---|
| `Alt+E` | Select the syntax node under the cursor, again to grow to the parent node (word, expression, statement, function...), like WebStorm |
| `Alt+Shift+E` | Shrink the selection back to the child node |
| `v` then `an` / `in` | Same, native keys (`an` grows, `in` shrinks) |
| `za` | Toggle the fold under the cursor (function, class, block) |
| `zc` / `zo` | Close / open the fold under the cursor |
| `zM` / `zR` | Close / open all folds |

Very large files open without treesitter, language servers and other slow features.

Files open fully unfolded. The signature of the current function or class stays pinned at the
top of the window while scrolling (up to 5 lines). HTML and JSX tags are closed and renamed
automatically.

## Go to line

Replaces `Alt+'` (GotoLine). Native, no plugin.

| Keys | Action |
|---|---|
| `42G` | Go to line 42 |
| `:42` then `Enter` | Go to line 42 |
| `7\|` | Go to column 7 of the current line |
| `gg` / `G` | First / last line |

## Editing

| Keys | Action |
|---|---|
| `Space t w` | Toggle line wrap |
| `Alt+Shift+↑` / `Alt+Shift+↓` | Move the line or the selection up / down (normal, visual, insert mode) |
| `Alt+Shift+←` / `Alt+Shift+→` | Decrease / increase the indentation of the line or the selection |
| `Space f` | Format the file, or the selection in visual mode |
| `gcc` or `Ctrl+Shift+C` | Comment / uncomment the line (like WebStorm's `Ctrl+/`) |
| `gc` or `Ctrl+Shift+C` (visual mode) | Comment / uncomment the selection |
| `gc` + motion | Comment / uncomment a text object: `gcip` paragraph, `gc3j` 4 lines... |
| `u` / `Ctrl+R` | Undo / redo |
| `Space u` | Undo tree: every past state of the file, even undone branches, `Enter` to go back to one |

Undo history survives closing the file.

Files are saved automatically 1 second after the last change. They are never formatted
automatically, only with `Space f` (replaces WebStorm's `Alt+Shift+G`).

Indentation is detected from the file content (or `.editorconfig`), 2 spaces for new files.
`:GuessIndent` re-runs the detection.

Formatter per language:

| Language | Formatter |
|---|---|
| JS, TS, JSON, CSS, SCSS, GraphQL | oxfmt, Biome or Prettier, the first one configured in the project |
| HTML, YAML, Markdown | Prettier, if configured in the project |
| Lua | stylua (style in `.stylua.toml`) |
| Shell | shfmt |
| Fish | fish_indent |
| Python | ruff (sort imports, then format) |
| Rust | rustfmt |
| Anything else | The language server's formatting, when it has one (TOML with taplo...) |

Web formatters run only in projects that have their config file (`.prettierrc`, `biome.json`,
`.oxfmtrc.json`...), from the project's `node_modules` when installed there. Elsewhere,
`Space f` does nothing and says so, repos that do not use them never get reformatted.

### Surround

| Keys | Action |
|---|---|
| `(` `[` `{` `` ` `` `*` (visual mode) | Wrap the selection, like VS Code. `*` makes Markdown bold (`**text**`) |
| `sa` + motion + character | Add around a text object: `saiw"` quotes a word, `sa$)` wraps to the end of line |
| `sd` + character | Delete around the cursor: `sd(` removes the parentheses, `sd*` the Markdown bold |
| `sr` + old + new | Replace around the cursor: `sr"'` turns `"…"` into `'…'` |

Opening brackets add inner spaces (`sa(` gives `( text )`), closing ones do not (`sa)` gives
`(text)`). `s` alone no longer replaces a character in normal mode (`cl` does it).

### Auto-closing brackets

In insert mode, typing `(`, `[` or `{` adds the closing one and leaves the cursor between the two.
Quotes are not paired (it would get in the way in prose: `l'`, `don't`).

| Keys (insert mode) | Action |
|---|---|
| `)` `]` `}` before the same closing character | Jump over it instead of typing a second one |
| `Backspace` between a pair | Delete both characters |

### Text objects

Used after an action: `d` delete, `c` change, `y` copy, `v` select. `i` = inside, `a` = around.

| Keys | Target |
|---|---|
| `iw` / `aw` | Word (native) |
| `i"` / `a"`, `i(` / `a(`, `i{` / `a{`... | Inside / around quotes, brackets (native) |
| `ip` / `ap` | Paragraph (native) |
| `it` / `at` | HTML tag content / whole tag (native) |
| `if` / `af` | Function body / whole function |
| `ic` / `ac` | Class body / whole class |
| `ia` / `aa` | Argument / argument with its comma |

Examples: `daf` deletes the function under the cursor, `cia` changes an argument, `yi"` copies a
string, `vac` selects the class. From outside, the code ones target the next one on the line.

### Multiple cursors

| Keys | Action |
|---|---|
| `Alt+R` | Add a cursor on the next occurrence of the word or selection (like WebStorm/VS Code) |
| `Alt+Shift+R` | Remove the last added cursor |
| `Ctrl+click` | Add a cursor where you click |
| `Esc` | Back to a single cursor |

With several cursors, any command applies to all of them (`ciw`, `A`, `dd`, `^`, insert mode...).
Text typed in insert mode shows at the main cursor only, and is copied to the other cursors on
`Esc`.

Native column editing: `Ctrl+V` selects a block, then `I` inserts before it, `A` after it (`$A`
at the end of each line), `c` replaces it. The text is copied to every line on `Esc`.

Native alternative, often quicker: `*` searches the word under the cursor, `cgn` changes the
next occurrence, then `.` repeats on the following one and `n` skips one. `:%s/old/new/g`
replaces everywhere with a live preview (add `c` to confirm each one).

## Open files (buffers)

Every opened file stays open in the background, the list is not displayed: use `Space s b` to
pick one. The tabline at the top shows the project name (blue block) and the active branch (green arrow), like the starship
prompt. Each split holding a file has a bar on top with its file: file name in blue in the focused
split, faded in the others. It shows the path inside the project (relative to the git root) with the file name in
bold, preceded by its file icon, `+` when modified, `RO` when read-only. Long paths are shortened fish style from the left
(`s/c/app.js`).

| Keys | Action |
|---|---|
| `Tab` / `Shift+Tab` | Next / previous open file |
| `Space b n` / `Space b p` | Same |
| `Ctrl+^` | Back and forth between the last two files |
| `Space s b` | Pick an open file (picker) |
| `Space b d` | Close the current file, keeping the splits (the previous file takes its place) |
| `:bd` | Close the current file, and its split if it was in one |

Vim tabs (tabpages) are something else: each holds its own window layout, like a virtual
desktop. `:tabnew file` or `Ctrl+T` in a picker opens one, `gt` / `gT` switch, `:tabclose` closes.

## Sessions

Started without arguments in a folder (`nvim`), Neovim reopens the files, splits and tabs left
there last time, like an IDE project. The session is saved when quitting, only if Neovim was
started without arguments: `nvim file` for a quick edit never overwrites it. Quitting after
closing every file deletes the session, the next `nvim` starts empty.

## Splits (windows)

`Space w` replaces Vim's `Ctrl+W` prefix (taken by the terminal), with its main commands. Wait
after `Space w` to see them all in the menu.

| Keys | Action |
|---|---|
| `Space w v` / `Space w s` | Split vertically (side by side) / horizontally |
| `Ctrl+H` / `Ctrl+J` / `Ctrl+K` / `Ctrl+L` | Go to the left / lower / upper / right split |
| `Space w h/j/k/l` | Same |
| `Space w w` | Next split, cycling |
| `Space w q` | Close the split |
| `Space w o` | Keep only the current split |
| `Space w =` | Equalize split sizes |
| `Space w x` | Swap with the next split |
| `Space w H` / `Space w L` | Move the split to the far left / right |
| `Ctrl+V` / `Ctrl+S` in a picker, `s` / `S` in the explorer | Open the file in a vertical / horizontal split |

`Esc` in normal mode clears the search highlight (Vim's `Ctrl+L` did it, now used for splits).

## Reading the screen

Tabline (top): project name and active branch. Bar of each split: its file, see [Open files](#open-files-buffers).

Indentation guides mark each level, the scope under the cursor is highlighted. Notifications
(LSP, formatters, plugins) pop up in the top right corner and fade out,
`:lua Snacks.notifier.show_history()` lists the past ones.

Right of the tabline (top), after the dots, blocks with arrows like the starship prompt (blues getting darker
toward the edge, the mode in its color at the very right), from left to right. There is no statusline
at the bottom.

```
 2e5w 12 luals 42:7 37% N
```

| Part | Meaning |
|---|---|
| `@q` | Recording a macro into register `q` (red, only while recording) |
| `12` | Keys typed so far in a pending command (here `12` of `12j`), only while typing |
| `N` | Mode: `N`ormal, `I`nsert, `V`isual, `L` visual line, `B` visual block, `R`eplace, `C`ommand, `T`erminal, `O`perator pending, `S`elect |
| `2e5w` | Diagnostics in the current file: errors, warnings, info, hints |
| `luals` | Language servers attached to the current file |
| `42:7 37%` | Line, column, position in the file |

When the screen is too narrow, parts are hidden in this order: percentage, pending keys,
language servers.

Git block of the tabline (branch, short commit hash, then status like `M3S1?2`), same as the
starship prompt. Status symbols (counts are files, not lines):

| Symbol | Meaning |
|---|---|
| `` | Merge conflicts |
| `D` | Deleted |
| `R` | Renamed |
| `M` | Modified, not staged |
| `S` | Staged |
| `?` | Untracked |
| `` / `` | Commits ahead / behind the remote |

Line numbers: the cursor line shows its real number, other lines show their distance to the
cursor (handy for `5j`, `3dk`). All numbers are absolute in insert mode and in unfocused
windows.
