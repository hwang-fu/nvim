# Keybindings and Commands Reference

Summary of every custom keybinding and plugin command in this config.
Compiled 2026-08-01 (post plugin-audit session: blink.cmp, oil.nvim,
live-preview, lazygit float, diffview); updated 2026-08-14 (OCaml
session: ocaml.nvim, utop REPL float, earlybird debugging, ocamllsp
settings repair; later same day: oil sidebar, treesitter textobjects,
which-key, and the lisp cluster - parinfer-rust, rainbow-delimiters,
conjure, slimv). `<leader>` is Space; `<localleader>` is backslash;
comma is slimv's.
Each section names the file where the bindings are defined - the
comments there carry the full rationale.

ASCII-only, like the rest of the config.

## Core editing (lua/hwangfu/keymappings/: editor / mouse / navigation .lua)

| Key | Mode | Action |
|-----|------|--------|
| Ctrl-S | n, i, v | Save (visual variant exits selection first) |
| Ctrl-Q | n | Quit window (i/v: error tells you to Esc first) |
| Ctrl-C / Ctrl-D | v | Yank selection to system clipboard |
| Ctrl-X | v | Cut selection to system clipboard |
| Ctrl-A | n, i | Select all |
| Ctrl-U | n | Undo |
| Ctrl-Z | n, i | Undo (from insert: exits insert and reverts the whole typed chunk) |
| Ctrl-R | n | Substitute char under cursor across file (pre-fills :%s) |
| Ctrl-R | v | Substitute the visual selection across file |
| Ctrl-/ (or Ctrl-_) | n, v | Toggle comment (delegates to built-in gc) |
| Ctrl-L | v | Toggle comment (older alias, same gc) |
| Shift-arrows | n | Enter visual mode and extend selection |
| Ctrl-Up / Ctrl-Down | n, i | Scroll viewport (v: extend selection by line) |
| Ctrl-Left / Ctrl-Right | n, i, v | Word motion (v extends) |
| Alt-Up / Alt-Down | n | Move line up / down with re-indent |
| ]b / [b | n | Next / previous buffer |
| \<leader\>bd | n | Close buffer |
| Ctrl-T | n | Toggle the oil sidebar at buffer's directory (35-col left split since 2026-08-14) |
| Ctrl-LeftClick | n | Jump to definition (LSP); clicked at the definition itself: list references instead (VSCode-style, 2026-08-15); non-LSP buffers fall back to ctags quietly. Back: Ctrl-O |

Note: Ctrl-R shadows built-in redo (use `:redo`); insert-mode Ctrl-R keeps
the built-in insert-register behavior.

## Structural editing - nvim-treesitter-textobjects (spec in lua/hwangfu/plugins/spec/textobjects.lua)

Syntax-aware text objects (visual + operator-pending) and motions
(normal + visual + operator-pending), added 2026-08-14. Works in every
treesitter language here EXCEPT erlang (no upstream queries - the maps
quietly no-op there).

| Key | Action |
|-----|--------|
| af / if | A function / inner function (vaf selects whole def linewise, dif deletes just the body) |
| ac / ic | A class / inner class ("class" = struct / impl / module in class-less languages) |
| aa / ia | A parameter incl. separating comma / just the parameter |
| ]f / [f | Next / previous function start |
| ]F / [F | Next / previous function end |
| ]] / [[ | Next / previous class start (overrides built-in section motions) |

]c / [c remain gitsigns hunk navigation. Motions set the jumplist, so
Ctrl-O walks back after an overshoot.

## Keymap discovery - which-key.nvim (spec in lua/hwangfu/plugins/spec/which_key.lua)

Added 2026-08-14. Pause after any mapped prefix (Space, backslash, ],
[, g, z, ...) and a popup lists every continuation with its
description; leader namespaces show group labels (+git hunks, +find /
telescope, +crates, ...). Buffer-local maps appear only where they
exist. Complements `<leader>fk` (telescope keymap search) and this
file - no keys of its own.

## Completion - blink.cmp (lua/hwangfu/completion.lua)

Popup opens as you type; docs float after 200ms; first item preselected
but not inserted.

| Key | Action |
|-----|--------|
| Down / Up, Ctrl-N / Ctrl-P | Move through the menu |
| Ctrl-Space | Open the menu on demand |
| Enter | Accept highlighted (or first) suggestion |
| Ctrl-F / Ctrl-B | Scroll the documentation window |
| Esc | Menu open: dismiss, stay in insert. Menu closed: leave insert |
| Tab / S-Tab | Jump between snippet placeholders (vim.snippet) |

Cmdline (`:` and `/`) has the same popup: Tab shows/cycles, arrows
navigate, Enter accepts and runs.

## LSP (lua/hwangfu/lsp/init.lua + helpers.lua; buffer-local on attach)

| Key | Action |
|-----|--------|
| K | Hover docs (press K again to enter the popup, q closes) |
| Ctrl-K | Signature help (works in insert mode) |
| gd / gD | Go to definition / declaration |
| gt / gi | Go to type definition / implementation |
| \<leader\>rn | Rename symbol everywhere |
| \<leader\>ca | Code action |
| gl | Line diagnostics float |
| grr / grn / gra / gri | Neovim 0.11 built-ins: references / rename / action / impl |
| [d / ]d | Previous / next diagnostic (built-in) |

Format-on-save runs automatically per-language (lua/hwangfu/lsp/format.lua).
Language extras:

- Rust (rustaceanvim): `:RustLsp <verb>` - expandMacro, explainError,
  openDocs, runnables, debuggables, parentModule, ... plus custom
  `:RustFormat`. K is overridden to `:RustLsp hover actions`.
- Haskell (haskell-tools): `:Haskell <subcommand>` - hover, hls evalAll,
  repl toggle, projectFile, ... K overridden to Hoogle-aware hover.
  Telescope extension: `:Telescope ht ...`.
- Elixir (elixir-tools): `:Mix <task>`, `:ElixirFromPipe`, `:ElixirToPipe`,
  `:ElixirExpandMacro`, `:ElixirRestart`, `:ElixirOutputPanel`,
  projectionist `:E*` commands.
- OCaml (ocaml.nvim): `:OCaml*` commands for the Merlin features standard
  LSP cannot reach - see the OCaml section below for the keymap table.
  Unlike the three above, the plugin does NOT own the LSP client; ocamllsp
  stays native, with inlay hints (let bindings, pattern variables, function
  params) and type-signature codelenses enabled.

## Telescope (lua/hwangfu/telescope.lua)

| Key | Picker |
|-----|--------|
| \<leader\>ff | Find files by name |
| \<leader\>fg | Live grep project contents |
| \<leader\>fs | Grep word under cursor |
| \<leader\>fb | Open buffers |
| \<leader\>fr | Recent files |
| \<leader\>fd | Project diagnostics |
| \<leader\>fh | Neovim help |
| \<leader\>fk | Search every keymap (discovery tool) |

All pickers also via `:Telescope <picker> [key=value ...]`; bare
`:Telescope` lists every picker. Inside the popup: Ctrl-N/P move, Enter
opens, Ctrl-X/Ctrl-V/Ctrl-T open in split/vsplit/tab, Ctrl-U/D scroll
preview, Ctrl-C closes, Ctrl-/ shows telescope's own mappings.

## Git

Three layers: gitsigns edits hunks in the buffer, lazygit acts on the
repo, diffview inspects changesets and history.

### gitsigns (spec in lua/hwangfu/plugins/spec/gitsigns.lua; buffer-local in git repos)

| Key | Action |
|-----|--------|
| ]c / [c | Next / previous hunk |
| \<leader\>hs | Stage hunk (toggles; visual: selected lines) |
| \<leader\>hr | Reset hunk to index (visual: selected lines) |
| \<leader\>hS / \<leader\>hR | Stage / reset entire buffer |
| \<leader\>hp / \<leader\>hi | Preview hunk float / inline |
| \<leader\>hb | Blame line (full commit message) |
| \<leader\>hd / \<leader\>hD | Diff split vs index / vs HEAD~ |
| \<leader\>hq / \<leader\>hQ | Buffer / all-repo hunks to quickfix |
| \<leader\>tb | Toggle inline blame virtual text |
| \<leader\>tw | Toggle word diff |
| ih | Hunk text object (vih, dih, ...) |

Every action is also `:Gitsigns <subcommand>`. Command-only extras:
blame (whole-buffer view), show [rev], show_commit, change_base /
reset_base, setloclist, toggle_signs / toggle_numhl / toggle_linehl,
refresh, attach / detach. Full annotated list in the gitsigns spec
comment.

### lazygit float (lua/hwangfu/git.lua)

| Key | Action |
|-----|--------|
| \<leader\>gg | Open lazygit in a float, rooted at the buffer's repo |

Inside, lazygit's own keys apply (`?` for the full list): q quits (and
collapses the float - do not `:q` the window), space stages/checks out,
c commit, A amend, P/p push/pull, panels via h/l or 1-5. Full quick
reference in git.lua's header. Escape hatch: `Ctrl-\ Ctrl-N` to leave
terminal mode, `i` to resume.

### diffview (spec in lua/hwangfu/plugins/spec/diffview.lua)

| Key | Action |
|-----|--------|
| \<leader\>gd | `:DiffviewOpen` - working tree vs INDEX (staged drops out) |
| \<leader\>gh | `:DiffviewFileHistory %` - current file's history |
| \<leader\>gH | `:DiffviewFileHistory` - whole-repo history |

In a diffview tab: Tab / S-Tab cycle files, g? help, q leaves. Commands:
`:DiffviewOpen [rev] [-- paths]` (ranges like `main...HEAD` work),
`:[range]DiffviewFileHistory [paths]` (visual range = line-evolution
view), `:DiffviewToggleFiles`, `:DiffviewFocusFiles`, `:DiffviewRefresh`,
`:DiffviewLog`.

## File explorer - oil.nvim (spec in lua/hwangfu/plugins/spec/oil.lua; sidebar in lua/hwangfu/explorer.lua)

Ctrl-T (global) toggles a 35-column left SIDEBAR (2026-08-14; previously
full-window) listing the current buffer's directory. Sidebar behavior:
Enter on a folder replaces the listing in place (oil is one directory
per buffer by design and cannot expand a tree inline - accepted
trade-off vs switching to nvim-tree); Enter on a file opens it in the
MAIN window and closes the sidebar. Listings are still buffers you edit
like text; `:w` applies the operations (create by typing names,
`newdir/` for folders, rename in place, dd deletes - PERMANENTLY, yy+p
copies). Buffer-local:

| Key | Action |
|-----|--------|
| Enter | Open entry (see sidebar behavior above); on the `../` first row: go up one directory (NERDTree-style, added 2026-08-14) |
| - or .. | Go up one directory |
| _ | Listing of nvim's cwd |
| ` | :cd into the viewed directory |
| Ctrl-T / Ctrl-C | Close the sidebar (or a full-window listing) |
| Ctrl-H | Open entry in horizontal split |
| Ctrl-P | Preview entry in a float |
| Ctrl-L | Refresh from disk |
| g. | Toggle hidden dotfiles |
| gs / gx | Change sort / open with system handler |
| g? | Oil's full key help |

(Oil's default Ctrl-S vsplit is disabled so Ctrl-S stays "save".)

## Markdown and preview

| Key | Action |
|-----|--------|
| \<leader\>mp | `:LivePreview start` - browser preview (md/HTML/adoc/SVG) |
| \<leader\>ms | `:LivePreview close` - stop the preview server |
| \<leader\>mt | `:LivePreview pick` - telescope picker of previewable files |
| \<leader\>mr | `:MarkdownRender toggle` - in-buffer render (render-markdown) |

`:MarkdownRender` subcommands: enable / disable / toggle, buf_enable /
buf_disable / buf_toggle, set [true|false], set_buf, preview, expand,
contract, log, debug, config. (Renamed from upstream's :RenderMarkdown.)
`:LivePreview help` lists its subcommands. Server: 127.0.0.1:5500.

## Rust dependencies - crates.nvim (lua/hwangfu/crates.lua; Cargo.toml only)

| Key | Action |
|-----|--------|
| \<leader\>cv / cf / cd | Versions / features / dependencies popup |
| \<leader\>cu / cU | Update / upgrade crate (visual: all selected) |
| \<leader\>ct | Toggle inline latest-version info |
| \<leader\>cr | Reload crates.io data |
| \<leader\>cx / cX | Expand to inline table / extract into table |
| \<leader\>cD / cC / cH / cR | Open docs.rs / crates.io / homepage / repository |

Completion, hover (K) and code actions (\<leader\>ca) ride the LSP layer.

## OCaml - ocaml.nvim + utop REPL (spec in plugins/spec/ocaml.lua; REPL in lua/hwangfu/repl.lua)

Buffer-local to OCaml buffers. `<localleader>` is backslash, so the keys
below read as typed: `\c` means backslash then c.

| Key | Action |
|-----|--------|
| \c | Construct: fill the typed hole under the cursor from valid substitutions |
| \n / \p | Jump to next / previous typed hole |
| \s | Switch between .ml and .mli |
| \i | Infer the interface of the matching .ml (run from the .mli buffer) |
| \t | Type-enclosing session; then Up/Down grow/shrink the expression, Right/Left raise/lower type verbosity |
| \j | Syntax-aware jump (fun / let / match / module targets) |
| \pn / \pp | Next / previous phrase (top-level item) |
| \r | Toggle the project-scoped utop REPL float |

(\p waits timeoutlen before firing since it prefixes \pn / \pp - upstream's
default, kept as-is.)

Command-only extras: `:OCamlTypeExpression <expr>`,
`:OCamlFindIdentifierDefinition` / `:OCamlFindIdentifierDeclaration` /
`:OCamlDocumentIdentifier <ident>`, and type-based search
`:OCamlSearchDefinition` / `:OCamlSearchDeclaration <type>`
(e.g. "int -> string").

The REPL float runs `dune utop .` at the project root (project libraries
loaded) or plain `utop` outside a project. Toggling it away only hides the
window - the session keeps running per project; utop ends with `#quit` or
Ctrl-D. Escape hatch: `Ctrl-\ Ctrl-N` leaves terminal mode, `i` resumes.

## Lisp family (specs in lua/hwangfu/plugins/spec/lisp.lua; added 2026-08-14)

Four plugins, no overlap. parinfer-rust (parens follow indentation in
clojure / scheme / lisp / racket / fennel / dune and friends;
:ParinferOff / :ParinferOn when pasting oddly-indented code) and
rainbow-delimiters (depth-colored parens in the lisp filetypes) have NO
keybindings. The two below do:

### conjure - eval from buffer (clojure, fennel, racket, scheme buffers)

| Key | Action |
|-----|--------|
| \ee | Eval expression under cursor (result inline) |
| \er | Eval root form under cursor |
| \eb | Eval whole buffer |
| \e! | Eval form and replace it with the result |
| \ew | Eval word under cursor |
| \E | Eval visual selection |
| \ls / \lv | Open conjure log in split / vsplit |
| gd | Conjure go-to-definition (falls back to LSP) |
| K | Conjure doc lookup (shadows LSP hover here) |

Clojure needs an nREPL running per project (conjure auto-connects via
.nrepl-port). Fennel evaluates in-process (nfnl client); racket and
scheme run stdio REPLs conjure manages itself.

### slimv - SLIME for Common Lisp (lisp buffers; leader is COMMA)

Slimv's maps are GLOBAL once loaded - the comma namespace is
effectively reserved for it. First eval auto-starts an sbcl+swank
server. Essentials (full list: :help slimv-keyboard):

| Key | Action |
|-----|--------|
| ,c | Connect to swank server |
| ,d / ,e | Eval defun / eval current expression |
| ,b | Eval buffer |
| ,i | Inspect object under cursor |
| ,s / ,h | Describe symbol / HyperSpec lookup |
| ,g | Set current package |
| ,y | Interrupt evaluation |
| ,, | Slimv menu (all commands, tab-completable) |

## Debugging - nvim-dap (lua/hwangfu/dap.lua; loads on first use)

| Key                   | Action                                                     |
| --------------------- | ---------------------------------------------------------- |
| F5                    | Start / continue (Rust-aware: routes through rustaceanvim) |
| Shift-F5              | Terminate session                                          |
| F6                    | Pause                                                      |
| F7                    | Toggle dap-ui panel                                        |
| F8                    | `:RustLsp debuggables` - pick a cargo target to debug      |
| F9 / Shift-F9         | Toggle breakpoint / conditional breakpoint                 |
| F10 / F11 / Shift-F11 | Step over / into / out                                     |

OCaml sessions use ocamlearlybird (installed via opam, not mason) and
debug BYTECODE only: give the executable stanza `(modes byte exe)`, run
`dune build`, then F5. The launch config globs `_build/**/*.bc` - one
match runs directly, several offer a numbered choice, none prompts for a
path.

## FHIR - fhir.nvim (spec in lua/hwangfu/plugins/spec/fhir.lua; FHIR buffers)

gd goto reference, gr find usages, \<leader\>fo outline, \<leader\>fe eval,
gl diagnostics, ga fix.

## Everything else

- vim-surround (plugin defaults): `ys{motion}{char}` add, `cs{old}{new}`
  change, `ds{char}` delete, visual `S{char}` wrap.
- `:ToggleWS` - toggle whitespace visualization for this window
  (lua/hwangfu/init.lua).
- `:Lazy` - plugin manager UI; `:Lazy sync` install/update.
- `:Mason`, `:MasonInstall`, `:MasonUpdate` - external tool binaries
  (currently just the codelldb debug adapter).
- `:TSInstall <lang>` / `:TSUpdate` - treesitter parsers.
- Colorschemes switch automatically per filetype (lua/hwangfu/colors.lua);
  no keybinding. Two groups since 2026-08: web/markup (html/htmlangular/
  css/scss) gets 256_noir; everything else - code, structured config, and
  markdown alike - gets dracula with a dark-green background. (Markdown
  previously had its own look via the local green.vim theme.)
