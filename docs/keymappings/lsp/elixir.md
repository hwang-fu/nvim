# Elixir

*LSP owned by elixir-tools (`lua/hwangfu/plugins/spec/elixir_tools.lua`); settings in `lua/hwangfu/lsp/servers/elixirls.lua`.*

All common [LSP keys](lsp.md) apply, plus:

| Command | Action |
|---------|--------|
| `:Mix <task>` | Run mix tasks with completion: `deps.get`, `test`, `ecto.migrate`, ... |
| `:ElixirFromPipe` | Rewrite `x \|> f(y)` into `f(x, y)` at the cursor |
| `:ElixirToPipe` | Rewrite `f(x, y)` into `x \|> f(y)` |
| `:ElixirExpandMacro` | Show a macro's expansion in a float |
| `:ElixirRestart` | Restart the language server |
| `:ElixirOutputPanel` | Open the server's log panel |
| `:Esource` / `:Etest` / `:Econtroller` / ... | Projectionist scaffolding for Phoenix files, inside Mix projects |

Test files get "Run test" codelenses above ExUnit functions.
