# Neovim snippets reference

Ready-made snippets available in every project, listed per language. My own snippets (ported
from WebStorm) are documented in [cheatsheet.md](cheatsheet.md).

Type the prefix, it shows in the completion menu, then `Enter` or `Tab`. `Tab` / `Shift+Tab`
jump between placeholders.

## JavaScript (also available in TypeScript)

| Prefix | Description |
|---|---|
| `#endregion` | Folding Region End |
| `#region` | Folding Region Start |
| `a` | await |
| `ae` | addEventListener |
| `af` | arrow function |
| `afe` | afterEach |
| `aft` | after |
| `aiife` | async immediately-invoked function expression |
| `apa` | await Promise.all |
| `apad` | await Promise.all with destructuring |
| `apm` | await Promise.all map |
| `apply` | The apply() method calls the specified function with a given this value, and arguments provided as an array (or an array-like object). |
| `asf` | async function |
| `ast` | await sleep |
| `ba` | beforeAll |
| `bf` | before |
| `bfe` | beforeEach |
| `bind` | The bind() method creates a new function that, when called, has its this keyword set to the provided value, with a given sequence of arguments preceding any provided when the new function is called. |
| `blur` |  |
| `c` | const statement |
| `ca` | const assignment awaited |
| `cad` | const statement from array destructuring |
| `call` | The call() method calls the function with a given this value and arguments provided individually. |
| `car` | const array |
| `cb` | Node callback |
| `cd` | const statement from destructuring |
| `cda` | const destructuring assignment awaited |
| `cdf` | createDocumentFragment |
| `ce` | console.error |
| `cel` | createElement |
| `cf` | const arrow function assignment |
| `cl` | console.log |
| `cn` | constructor |
| `co` | const object |
| `cod` | console.dir |
| `concat` | The concat() method concatenates the string arguments to the calling string and returns a new string. |
| `cr` | const module = require('module') |
| `cs` | class |
| `csx` | class extends |
| `cv` | console.log a variable |
| `cw` | console.warn |
| `cy` | const assignment yielded |
| `define` | define module |
| `defineProperties` |  |
| `desc` | describe |
| `dowhile` | Do-While Statement |
| `dt` | describe top level |
| `e` | module export |
| `ec` | module export const |
| `ed` | module default export |
| `edf` | module default export function |
| `ef` | export named function |
| `ei` | else if statement |
| `el` | else statement |
| `em` | exports.member |
| `endsWith` | The endsWith() method determines whether a string ends with the characters of a specified string, returning true or false as appropriate. |
| `entries` | The Object.entries() method returns an array of a given object's own enumerable string-keyed property key-value pairs. |
| `error` | Log error to the console |
| `evc` | dom event cancel default and propagation |
| `every` | every |
| `f` | arrow function with body |
| `fan` | anonymous function |
| `fd` | arrow function with destructuring |
| `fdr` | arrow function with destructuring returning destructured |
| `fe` | forEach loop |
| `filter` | filter |
| `find` | find |
| `fn` | named function |
| `focus` | The HTMLElement.focus() method sets focus on the specified element, if it can be focused. The focused element is the element that will receive keyboard and similar events by default. |
| `for` | For Loop |
| `forawaitof` | For-Await-Of Loop |
| `foreach` | For-Each Loop |
| `forin` | For-In Loop |
| `forof` | For-Of Loop |
| `fr` | arrow function with return |
| `fromCharCode` | The static String.fromCharCode() method returns a string created from the specified sequence of UTF-16 code units. |
| `function` | Function Statement |
| `gari0` | generate array of integers starting with 0 |
| `gari` | generate array of integers starting with 1 |
| `gc` | getElementsByClassName |
| `get` | getter |
| `gf` | generator function |
| `gfn` | named generator |
| `gi` | getElementById |
| `gs` | getter + setter |
| `gt` | getElementsByTagName |
| `heac` | appendChild |
| `hecla` | classList.add |
| `heclr` | classList.remove |
| `hect` | classList.toggle |
| `hega` | getAttribute |
| `hera` | removeAttribute |
| `herc` | removeChild |
| `hesa` | setAttribute |
| `ia` | import module as |
| `id` | import module destructured |
| `ifelse` | If-Else Statement |
| `iife` | immediately-invoked function expression |
| `im` | import module |
| `import statement` | Import external module. |
| `includes` | The includes() method performs a case-sensitive search to determine whether one string may be found within another string, returning true or false as appropriate. |
| `indexOf` | The indexOf() method, given one argument: a substring to search for, searches the entire calling string, and returns the index of the first occurrence of the specified substring. Given a second argument: a number, the method returns the first occurrence of the specified substring at an index greater than or equal to the specified number. |
| `innerText` | The innerText property of the HTMLElement interface represents the rendered text content of a node and its descendants. |
| `iof` | instanceof |
| `isFinite` | The Number.isFinite() method determines whether the passed value is a finite number, that is, it checks that a given value is a number, and the number is neither positive Infinity, negative Infinity, nor NaN. |
| `isNaN` | The Number.isNaN() method determines whether the passed value is the number value NaN, and returns false if the input is not of the Number type. It is a more robust version of the original, global isNaN() function. |
| `itd` | it with a callback |
| `its` | it synchronous |
| `itt` | it.todo |
| `jp` | JSON.parse() |
| `js` | JSON.stringify() |
| `l` | let statement |
| `la` | let assignment awaited |
| `lastIndexOf` | The lastIndexOf() method, given one argument: a substring to search for, searches the entire calling string, and returns the index of the last occurrence of the specified substring. Given a second argument: a number, the method returns the last occurrence of the specified substring at an index less than or equal to the specified number. |
| `lif` | let and if statement |
| `localeCompare` | The localeCompare() method returns a number indicating whether a reference string comes before, or after, or is the same as the given string in sort order. In implementations with Intl.Collator API support, this method simply calls Intl.Collator. |
| `ly` | let assignment yielded |
| `m` | method |
| `map` | map |
| `match` | The match() method retrieves the result of matching a string against a regular expression. |
| `matchAll` | The matchAll() method returns an iterator of all results matching a string against a regular expression, including capturing groups. |
| `me` | module.exports |
| `mec` | module as class |
| `new` | New Statement |
| `normalize` | The normalize() method returns the Unicode Normalization Form of the string. |
| `np` | new Promise |
| `oa` | Object.assign |
| `oc` | Object.create |
| `od` | Object.defineProperty |
| `oe` | Object.entries |
| `og` | Object.getOwnPropertyDescriptor |
| `ok` | Object.keys |
| `on` | event handler |
| `ov` | Object.values |
| `p` | Promise |
| `pa` | Promise.all |
| `parseFloat` | The Number.parseFloat() method parses an argument and returns a floating point number. If a number cannot be parsed from the argument, it returns NaN. |
| `parseInt` | The Number.parseInt() method parses a string argument and returns an integer of the specified radix or base. |
| `pc` | Promise.catch |
| `pe` | process.env |
| `prj` | Promise.reject |
| `proto` | prototype method |
| `prs` | Promise.resolve |
| `pt` | Promise.then |
| `push` | The push() method adds one or more elements to the end of an array and returns the new length of the array. |
| `qs` | querySelector |
| `qsa` | querySelectorAll |
| `r` | return |
| `ra` | return new array |
| `reduce` | reduce |
| `rel` | removeEventListener |
| `repeat` | The repeat() method constructs and returns a new string which contains the specified number of copies of the string on which it was called, concatenated together. |
| `replace` | The replace() method returns a new string with one, some, or all matches of a pattern replaced by a replacement. The pattern can be a string or a RegExp, and the replacement can be a string or a function called for each match. If pattern is a string, only the first occurrence will be replaced. The original string is left unchanged. |
| `replaceAll` | The replaceAll() method returns a new string with all matches of a pattern replaced by a replacement. The pattern can be a string or a RegExp, and the replacement can be a string or a function to be called for each match. The original string is left unchanged. |
| `reverse` | The reverse() method reverses an array in place and returns the reference to the same array, the first array element now becoming the last, and the last array element becoming the first. In other words, elements order in the array will be turned towards the direction opposite to that previously stated. |
| `rf` | return arrow function |
| `rn` | return null |
| `ro` | return new object |
| `rp` | return promise |
| `rq` | require |
| `search` | The search() method executes a search for a match between a regular expression and this String object. |
| `set` | setter |
| `setDate` | The setDate() method changes the day of the month of a given Date instance, based on local time. |
| `setinterval` | Set Interval Function |
| `setTime` | The setTime() method sets the Date object to the time represented by a number of milliseconds since January 1, 1970, 00:00:00 UTC. |
| `settimeout` | Set Timeout Function |
| `sim` | setImmediate |
| `slice` | The slice() method extracts a section of a string and returns it as a new string, without modifying the original string. |
| `some` | some |
| `sort` | The sort() method sorts the elements of an array in place and returns the reference to the same array, now sorted. The default sort order is ascending, built upon converting the elements into strings, then comparing their sequences of UTF-16 code units values. |
| `splice` | The splice() method changes the contents of an array by removing or replacing existing elements and/or adding new elements in place. To access part of an array without modifying it, see slice(). |
| `split` | The split() method takes a pattern and divides a String into an ordered list of substrings by searching for the pattern, puts these substrings into an array, and returns the array. |
| `startsWith` | The startsWith() method determines whether a string begins with the characters of a specified string, returning true or false as appropriate. |
| `substring` | The substring() method returns the part of the string between the start and end indexes, or to the end of the string. |
| `switch` | Switch Statement |
| `t` | this |
| `ta` | ternary assignment |
| `tc` | try/catch |
| `tcf` | try/catch/finally |
| `te` | ternary |
| `tf` | try/finally |
| `tn` | throw new Error |
| `to` | typeof |
| `toDateString` |  |
| `toFixed` | The toFixed() method formats a number using fixed-point notation. |
| `toJSON` | The toJSON() method returns a string representation of the Date object. |
| `toLocaleLowerCase` | The toLocaleLowerCase() method returns the calling string value converted to lower case, according to any locale-specific case mappings. |
| `toLocaleString` | The toLocaleString() method returns a string with a language-sensitive representation of this number. In implementations with Intl.NumberFormat API support, this method simply calls Intl.NumberFormat. |
| `toLocaleUpperCase` | The toLocaleUpperCase() method returns the calling string value converted to upper case, according to any locale-specific case mappings. |
| `toLowerCase` | The toLowerCase() method returns the calling string value converted to lower case. |
| `toString` | The toString() method returns a string representing the specified string value. |
| `toUpperCase` | The toUpperCase() method returns the calling string value converted to uppercase (the value will be converted to a string if it isn't one). |
| `trycatch` | Try-Catch Statement |
| `uss` | use strict |
| `v` | var statement |
| `va` | var assignment |
| `valueOf` | The valueOf() method returns the primitive value of a String object. |
| `values` | The Object.values() method returns an array of a given object's own enumerable string-keyed property values. |
| `warn` | Log warning to the console |
| `while` | While Statement |
| `wid` | while iteration decrementing |
| `wrap selection in arrow function` | wraps text in arrow function |
| `wrap selection in async arrow function` | wraps text in arrow function |
| `y` | yield |

## TypeScript only

| Prefix | Description |
|---|---|
| `#endregion` | Folding Region End |
| `#region` | Folding Region Start |
| `class` | Class Definition |
| `ctor` | Constructor |
| `dowhile` | Do-While Statement |
| `error` | Log error to the console |
| `for` | For Loop |
| `forawaitof` | For-Await-Of Loop |
| `foreach =>` | For-Each Loop using => |
| `forin` | For-In Loop |
| `forof` | For-Of Loop |
| `function` | Function Statement |
| `get` | Property getter |
| `if` | If Statement |
| `iface` | Interface Definition |
| `ifelse` | If-Else Statement |
| `import statement` | Import external module. |
| `log` | Log to the console |
| `new` | New Statement |
| `private method` | Private Method Definition |
| `prop` | Define a full property |
| `public method` | Public Method Definition |
| `ref` | Triple-slash reference |
| `set` | Property setter |
| `settimeout` | Set Timeout Function |
| `switch` | Switch Statement |
| `throw` | Throw Exception |
| `trycatch` | Try-Catch Statement |
| `warn` | Log warning to the console |
| `while` | While Statement |

## HTML

| Prefix | Description |
|---|---|
| `a` | HTML - Defines a hyperlink |
| `abbr` | HTML - Defines an abbreviation |
| `address` | HTML - Defines an address element |
| `area` | HTML - Defines an area inside an image map |
| `article` | HTML - Defines an article |
| `aside` | HTML - Defines content aside from the page content |
| `audio` | HTML - Defines sounds content |
| `b` | HTML - Defines bold text |
| `base` | HTML - Defines a base URL for all the links in a page |
| `bdi` | HTML - Used to isolate text that is of unknown directionality |
| `bdo` | HTML - Defines the direction of text display |
| `big` | HTML - Used to make text bigger |
| `blockquote` | HTML - Defines a long quotation |
| `body` | HTML - Defines the body element |
| `br` | HTML - Inserts a single line break |
| `button` | HTML - Defines a push button |
| `canvas` | HTML - Defines graphics |
| `caption` | HTML - Defines a table caption |
| `cite` | HTML - Defines a citation |
| `code` | HTML - Defines computer code text |
| `col` | HTML - Defines attributes for table columns |
| `colgroup` | HTML - Defines group of table columns |
| `command` | HTML - Defines a command button [not supported] |
| `copyright` | Snippet to put copyright |
| `datalist` | HTML - Defines a dropdown list |
| `date` | Put the date in (Y-m-D) format |
| `dateDMY` | Put date in (DD/MM/YY) format |
| `dateMDY` | Put the date in (m/D/Y) format |
| `datetime` | I give you back the time and date (Y-m-d H:M) |
| `dd` | HTML - Defines a definition description |
| `del` | HTML - Defines deleted text |
| `details` | HTML - Defines details of an element |
| `dfn` | HTML - Defines a definition term |
| `dialog` | HTML - Defines a dialog (conversation) |
| `diso` | ISO date time stamp |
| `div#` | HTML - Defines a section in a document |
| `div.#` | HTML - Defines a section in a document |
| `div.` | HTML - Defines a section in a document |
| `div` | HTML - Defines a section in a document |
| `dl` | HTML - Defines a definition list |
| `doctype` | HTML - Defines the document type |
| `dt` | HTML - Defines a definition term |
| `em` | HTML - Defines emphasized text |
| `embed` | HTML - Defines external interactive content ot plugin |
| `fieldset` | HTML - Defines a fieldset |
| `figcaption` | HTML - Defines a caption for a figure |
| `figure` | HTML - Defines a group of media content, and their caption |
| `footer` | HTML - Defines a footer for a section or page |
| `form` | HTML - Defines a form |
| `h1` | HTML - Defines header 1 |
| `h2` | HTML - Defines header 2 |
| `h3` | HTML - Defines header 3 |
| `h4` | HTML - Defines header 4 |
| `h5` | HTML - Defines header 5 |
| `h6` | HTML - Defines header 6 |
| `head` | HTML - Defines information about the document |
| `header` | HTML - Defines a header for a section of page |
| `hgroup` | HTML - Defines information about a section in a document |
| `hr` | HTML - Defines a horizontal rule |
| `html5` | HTML - Defines a template for a html5 document |
| `html` | HTML - Defines an html document |
| `i` | HTML - Defines italic text |
| `iframe` | HTML - Defines an inline sub window |
| `img` | HTML - Defines an image |
| `input` | HTML - Defines an input field |
| `ins` | HTML - Defines inserted text |
| `kbd` | HTML - Defines keyboard text |
| `keygen` | HTML - Defines a generated key in a form |
| `label` | HTML - Defines an inline window |
| `legend` | HTML - Defines a title in a fieldset |
| `li` | HTML - Defines a list item |
| `link` | HTML - Defines a resource reference |
| `main` | HTML - Defines an image map |
| `map` | HTML - Defines an image map |
| `mark` | HTML - Defines marked text |
| `menu` | HTML - Defines a menu list |
| `menuitem` | HTML - Defines a menu item [firefox only] |
| `meta` | HTML - Defines meta information |
| `meter` | HTML - Defines measurement within a predefined range |
| `nav` | HTML - Defines navigation links |
| `noscript` | HTML - Defines a noscript section |
| `object` | HTML - Defines an embedded object |
| `ol#` | HTML - Defines an ordered list |
| `ol.#` | HTML - Defines an ordered list |
| `ol.` | HTML - Defines an ordered list |
| `ol` | HTML - Defines an ordered list |
| `optgroup` | HTML - Defines an option group |
| `option` | HTML - Defines an option in a drop-down list |
| `output` | HTML - Defines some types of output |
| `p#` | HTML - Defines a paragraph |
| `p.#` | HTML - Defines a paragraph |
| `p.` | HTML - Defines a paragraph |
| `p` | HTML - Defines a paragraph |
| `param` | HTML - Defines a parameter for an object |
| `pre` | HTML - Defines preformatted text |
| `progress` | HTML - Defines progress of a task of any kind |
| `q` | HTML - Defines a short quotation |
| `rp` | HTML - Used in ruby annotations to define what to show browsers that do not support the ruby element |
| `rt` | HTML - Defines explanation to ruby annotations |
| `ruby` | HTML - Defines ruby annotations |
| `s` | HTML - Used to define strikethrough text |
| `samp` | HTML - Defines sample computer code |
| `script` | HTML - Defines a script |
| `section` | HTML - Defines a section |
| `select` | HTML - Defines a selectable list |
| `small` | HTML - Defines small text |
| `source` | HTML - Defines media resource |
| `span` | HTML - Defines a section in a document |
| `strong` | HTML - Defines strong text |
| `style` | HTML - Defines a style definition |
| `sub` | HTML - Defines sub-scripted text |
| `summary` | HTML - Defines a visible heading for the detail element [limited support] |
| `sup` | HTML - Defines super-scripted text |
| `table` | HTML - Defines a table |
| `tbody` | HTML - Defines a table body |
| `td` | HTML - Defines a table cell |
| `textarea` | HTML - Defines a text area |
| `tfoot` | HTML - Defines a table footer |
| `th` | HTML - Defines a table header |
| `thead` | HTML - Defines a table head |
| `time` | I give you back the time (H:M) |
| `timeHMS` | I give you back the time (H:M:S) |
| `title` | HTML - Defines the document title |
| `tr` | HTML - Defines a table row |
| `track` | HTML - Defines a table row |
| `u` | HTML - Used to define underlined text |
| `ul#` | HTML - Defines an unordered list |
| `ul.#` | HTML - Defines an unordered list |
| `ul.` | HTML - Defines an unordered list |
| `ul` | HTML - Defines an unordered list |
| `uuid` | A Version 4 UUID |
| `var` | HTML - Defines a variable |
| `video` | HTML - Defines a video |

## CSS

| Prefix | Description |
|---|---|
| `!` | !important |
| `ai` | initial value: stretch |
| `aib` | align-items: baseline |
| `aic` | align-items: center |
| `aife` | align-items: flex-end |
| `aifs` | align-items: flex-start |
| `ais` | align-items: stretch |
| `ani` | animation: name duration timing-function delay direction count fill-mode play-state |
| `anide` | animation-delay |
| `anidi` | initial value: normal |
| `anidu` | animation-duratuion |
| `anifm` | initial value: none |
| `aniic` | initial value: 1 |
| `anin` | animation-name |
| `anips` | initial value: running |
| `anitf` | initial value: ease |
| `as` | initial value: auto |
| `bg` | background: image position/size repeat attachment box box |
| `bga` | initial value: scroll |
| `bgc` | background-color |
| `bgcl` | initial value: border-box |
| `bgi` | background-image |
| `bgo` | initial value: padding-box |
| `bgp` | background-position |
| `bgr` | initial value: repeat |
| `bgrn` | background-repeat: no-repeat |
| `bgrr` | background-repeat: repeat |
| `bgrx` | background-repeat: repeat-x |
| `bgry` | background-repeat: repeat-y |
| `bgs` | background-size |
| `bor` | border |
| `borb` | border-bottom |
| `borc` | border-color |
| `borl` | border-left |
| `born` | border: none |
| `borr` | border-right |
| `bors` | border-style |
| `bort` | border-top |
| `borw` | border-width |
| `bos` | box-shadow: x-offset y-offset blur spread color |
| `bot` | bottom |
| `boz` | initial value: content-box |
| `br` | border-radius |
| `clr` | clear |
| `col` | color |
| `con` | content |
| `cur` | initial value: auto |
| `curd` | cursor: default |
| `curp` | cursor: pointer |
| `dis` | display |
| `disb` | display: block |
| `disf` | display: flex |
| `disi` | display: inline-block |
| `disn` | display: none |
| `ff` | font-family |
| `fl` | float |
| `fld` | initial value: row |
| `fldc` | flex-direction: column |
| `fldr` | flex-direction: row |
| `fle` | flex (alt) |
| `flex` | flex: grow shrink basis |
| `flf` | flex-flow |
| `fll` | float: left |
| `fln` | float: none |
| `flr` | float: right |
| `flw` | initial value: nowrap |
| `fst` | font-style |
| `fsti` | font-style: italic |
| `fstn` | font-style: normal |
| `fsto` | font-style: oblique |
| `ft` | font: [weight style variant stretch] size/line-height family |
| `fw` | font-weight |
| `fwb` | font-weight: bold |
| `fwl` | font-weight: light |
| `fwn` | font-weight: normal |
| `fz` | font-size |
| `hei` | height |
| `i` | !important (alt) |
| `imp` | @import |
| `inc` | @include |
| `jc` | initial value: flex-start |
| `jcc` | justify-content: center |
| `jcfe` | justify-content: flex-end |
| `jcfs` | justify-content: flex-start |
| `jcsa` | justify-content: space-around |
| `jcsb` | justify-content: space-between |
| `key` | @keyframes |
| `lef` | left |
| `lh` | line-height |
| `lis` | list-style: type position image |
| `lisp` | initial value: outside |
| `list` | initial value: disc |
| `listc` | list-style-type: circle |
| `listd` | list-style-type: disc |
| `listlr` | list-style-type: lower-roman |
| `listn` | list-style-type: none |
| `lists` | list-style-type: square |
| `listur` | list-style-type: upper-roman |
| `ls` | letter-spacing |
| `lsn` | letter-spacing: normal |
| `mah` | max-height |
| `mar` | margin |
| `mara` | margin: 0 auto |
| `marb` | margin-bottom |
| `marl` | margin-left |
| `marr` | margin-right |
| `mart` | margin-top |
| `maw` | max-width |
| `med` | @media |
| `mih` | min-height |
| `miw` | min-width |
| `mix` | @mixin |
| `opa` | opacity |
| `ov` | overflow |
| `ova` | overflow: auto |
| `ovh` | overflow: hidden |
| `ovs` | overflow: scroll |
| `ovv` | overflow: visible |
| `pad` | padding |
| `padb` | padding-bottom |
| `padl` | padding-left |
| `padr` | padding-right |
| `padt` | padding-top |
| `pos` | position |
| `posa` | position absolute |
| `posf` | position fixed |
| `posr` | position relative |
| `poss` | position sticky |
| `rig` | right |
| `ta` | text-align |
| `tac` | text-align: center |
| `tal` | text-align: left |
| `tar` | text-align: right |
| `td` | text-decoration |
| `tdl` | text-decoration: line-through |
| `tdn` | text-decoration: none |
| `tdu` | text-decoration: underline |
| `ti` | text-indent |
| `top` | top |
| `ts` | text-shadow: x-offset y-offset blur spread color |
| `tt` | text-transform |
| `va` | vertical-align |
| `vab` | vertical-align: bottom |
| `vam` | vertical-align: middle |
| `vat` | vertical-align: top |
| `vis` | visibility |
| `vish` | visibility: hidden |
| `visv` | visibility: visible |
| `wb` | word-break |
| `wid` | width |
| `wida` | width: auto |
| `ws` | white-space |
| `wsn` | white-space: nowrap |
| `wsp` | white-space: pre |
| `ww` | word-wrap |
| `zi` | z-index |

## All file types

| Prefix | Description |
|---|---|
| `copyright` | Snippet to put copyright |
| `date` | Put the date in (Y-m-D) format |
| `dateDMY` | Put date in (DD/MM/YY) format |
| `dateMDY` | Put the date in (m/D/Y) format |
| `datetime` | I give you back the time and date (Y-m-d H:M) |
| `diso` | ISO date time stamp |
| `time` | I give you back the time (H:M) |
| `timeHMS` | I give you back the time (H:M:S) |
| `uuid` | A Version 4 UUID |
