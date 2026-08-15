# Lisp family (specs in lua/hwangfu/plugins/spec/lisp.lua; added 2026-08-14)

Four plugins, no overlap. parinfer-rust (parens follow indentation in
clojure / scheme / lisp / racket / fennel / dune and friends;
:ParinferOff / :ParinferOn when pasting oddly-indented code) and
rainbow-delimiters (depth-colored parens in the lisp filetypes) have NO
keybindings. The two below do:

## conjure - eval from buffer (clojure, fennel, racket, scheme buffers)

| Key | Action |
|-----|--------|
| `\ee` | Eval expression under cursor (result inline) |
| `\er` | Eval root form under cursor |
| `\eb` | Eval whole buffer |
| `\e!` | Eval form and replace it with the result |
| `\ew` | Eval word under cursor |
| `\E` | Eval visual selection |
| `\ls` / `\lv` | Open conjure log in split / vsplit |
| `gd` | Conjure go-to-definition (falls back to LSP) |
| `K` | Conjure doc lookup (shadows LSP hover here) |

Clojure needs an nREPL running per project (conjure auto-connects via
.nrepl-port). Fennel evaluates in-process (nfnl client); racket and
scheme run stdio REPLs conjure manages itself.

## slimv - SLIME for Common Lisp (lisp buffers; leader is COMMA)

Slimv's maps are GLOBAL once loaded - the comma namespace is
effectively reserved for it. First eval auto-starts an sbcl+swank
server. Essentials (full list: :help slimv-keyboard):

| Key | Action |
|-----|--------|
| `,c` | Connect to swank server |
| `,d` / `,e` | Eval defun / eval current expression |
| `,b` | Eval buffer |
| `,i` | Inspect object under cursor |
| `,s` / `,h` | Describe symbol / HyperSpec lookup |
| `,g` | Set current package |
| `,y` | Interrupt evaluation |
| `,,` | Slimv menu (all commands, tab-completable) |
