# Fennel

*REPL keys from conjure and structural editing from parinfer (`lua/jwn/plugins/spec/lisp.lua`); static analysis from fennel-ls (`lua/jwn/lsp/servers/fennel_ls.lua`).*

The same two-engine split as [clojure](clojure.md): fennel-ls reads the code statically (diagnostics, completion), conjure evaluates it live. The localleader is backslash, so `\ee` means: press backslash, then `e`, then `e`. Throughout this page, "a Fennel file" means anything Neovim detects as the fennel filetype - `.fnl`.

All common [LSP keys](lsp.md) apply. Conjure shadows two of them in Fennel files: `gd` and `K` go through conjure first, falling back to the LSP.

## No REPL to start

This is where Fennel differs from Clojure, in the best way: there is nothing to launch. Fennel compiles to Lua, and conjure's fennel client evaluates it **inside Neovim's own Lua runtime** - zero external processes, zero connection steps, working the moment a `.fnl` file opens.

The consequence is bigger than convenience: evaluated code has full access to Neovim's API. `\ee` on `(vim.notify "hi")` fires a real notification; a form calling `vim.api.nvim_buf_set_lines` edits real buffers. Fennel files are a live scripting console for the editor itself.

The trade-off: evaluation happens in Neovim's Lua (LuaJIT), not in a standalone `fennel` process. For scripts meant to run outside the editor, conjure can be switched to its stdio client (`vim.g["conjure#filetype#fennel"]`, see the comment in `spec/lisp.lua`); nobody has needed it here yet.

## Evaluating

Fennel gets conjure's client-generic key set - no language-specific extras like Clojure's test and refresh families. Each key also exists as a buffer-local command in Fennel files.

| Key | Command | Action |
|-----|---------|--------|
| `\ee` | `:ConjureEvalCurrentForm` | Evaluate the expression under the cursor |
| `\er` | `:ConjureEvalRootForm` | Evaluate the top-level form under the cursor |
| `\eb` | `:ConjureEvalBuf` | Evaluate the whole file as currently shown in the editor, saved or not |
| `\ef` | `:ConjureEvalFile` | Evaluate the file as saved ON DISK - unlike `\eb`, unsaved edits are not seen |
| `\ew` | `:ConjureEvalWord` | Evaluate the word under the cursor - peek at what a symbol holds |
| `\e!` | `:ConjureEvalReplaceForm` | Evaluate the form and replace its text with the result, right in the file |
| `\em{mark}` | `:ConjureEvalMarkedForm` | Evaluate the form at a vim mark: `\emF` evaluates at mark `F` without moving the cursor |
| `\E` | `:ConjureEvalVisual` | Evaluate the visual selection |
| `\ece` / `\ecr` / `\ecw` | `:ConjureEvalComment...` | The `\ee` / `\er` / `\ew` evals, but the result is inserted into the file as a comment below the form |
| `\ls` / `\lv` | `:ConjureLogSplit` / `:ConjureLogVSplit` | Open conjure's log of results in a split / vsplit |
| `gd` | `:ConjureDefWord` | Go to the definition of the word under the cursor, LSP fallback |
| `K` | `:ConjureDocWord` | Documentation for the word under the cursor, shadowing LSP hover |

## Formatting

> [!NOTE]
> Fennel currently has NO format-on-save: the `fnlfmt` binary is installed on this machine but was never wired into `lsp/format.lua`, and fennel-ls does not format. Saves leave the file as typed (parinfer still keeps the parens structurally consistent while editing).
