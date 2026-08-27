# Lisp

*All four plugins are defined in `lua/jwa/plugins/spec/lisp.lua`.*

Three plugins cover the Lisp family. One of them has no keys at all: rainbow-delimiters colors parentheses by nesting depth - display only. Nothing edits your code on its own: parinfer-rust (which auto-balanced parens from indentation) was removed 2026-08-27 by choice, so parentheses are typed and deleted by hand, and the only automatic change is cljfmt's whitespace-only formatting on save.

## Conjure - evaluate from the buffer

Active in Clojure, Fennel, Racket, and Scheme buffers. Results appear inline as virtual text.

Each key also exists as a buffer-local command in these files - the Command column. `:ConjureEval <code>` additionally evaluates any text typed on the command line.

| Key | Command | Action |
|-----|---------|--------|
| `\ee` | `:ConjureEvalCurrentForm` | Evaluate the expression under the cursor |
| `\er` | `:ConjureEvalRootForm` | Evaluate the top-level form under the cursor |
| `\eb` | `:ConjureEvalBuf` | Evaluate the whole buffer |
| `\e!` | `:ConjureEvalReplaceForm` | Evaluate the form and replace it with its result |
| `\ew` | `:ConjureEvalWord` | Evaluate the word under the cursor - useful to inspect a value |
| `\E` | `:ConjureEvalVisual` | Evaluate the visual selection |
| `\ls` / `\lv` | `:ConjureLogSplit` / `:ConjureLogVSplit` | Open conjure's log in a split / vsplit |
| `gd` | `:ConjureDefWord` | Conjure's go-to-definition, falling back to the LSP |
| `K` | `:ConjureDocWord` | Conjure's documentation lookup (it shadows LSP hover in these buffers) |

Clojure evaluation needs an nREPL server running in the project; conjure connects on its own through the `.nrepl-port` file. Fennel evaluates inside Neovim with no external process, and Racket and Scheme use REPL processes conjure manages itself.

Clojure gets much more than the table above - tests, namespace refreshing, tap inspection, exception views - all documented on its own page: [clojure](clojure.md). Fennel also has its own page, [fennel](fennel.md), covering the full key set and its no-process evaluation model.

## Slimv - SLIME for Common Lisp

Active in Lisp buffers, with all commands under the **comma** key - that namespace effectively belongs to slimv. The first evaluation starts an sbcl+swank server automatically.

| Key | Action |
|-----|--------|
| `,c` | Connect to the swank server |
| `,d` / `,e` | Evaluate the current defun / the current expression |
| `,b` | Evaluate the buffer |
| `,i` | Inspect the object under the cursor |
| `,s` / `,h` | Describe the symbol / look it up in the HyperSpec |
| `,g` | Set the current package |
| `,y` | Interrupt a running evaluation |
| `,,` | Open slimv's menu of every command, tab-completable |

Unlike conjure, slimv's keys have no per-key command equivalents; its two commands are `:Lisp <code>` and `:Eval <code>`, both evaluating the text you type. The full key list is in `:help slimv-keyboard`.

> [!NOTE]
> Racket and Scheme REPL processes do not auto-start when a file opens (their startup output used to pop the log float over the fresh buffer, duplicating the language server diagnostics). Start one deliberately with `\cs` in the buffer; evaluating without a REPL leaves a `; No REPL running` breadcrumb. Clojure differs: connecting to an already-running nREPL is free, so that stays automatic.
