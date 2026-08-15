# Elixir

*LSP owned by elixir-tools (`lua/hwangfu/plugins/spec/elixir_tools.lua`); settings in `lua/hwangfu/lsp/servers/elixirls.lua`.*

All common [LSP keys](lsp.md) apply. Everything plugin-specific is a command; there are no extra keys.

## The ElixirLS commands

These exist buffer-locally in Elixir buffers, once the server has attached.

| Command | Action |
|---------|--------|
| `:ElixirFromPipe` | Rewrite `x \|> f(y)` into `f(x, y)` at the cursor |
| `:ElixirToPipe` | Rewrite `f(x, y)` into `x \|> f(y)` |
| `:ElixirExpandMacro` | Show the expansion of the visually selected macro call in a float |
| `:ElixirRestart` | Restart the language server |
| `:ElixirOutputPanel` | Open the server's log panel |

Test files get "Run test" codelenses above ExUnit functions.

## Mix

| Command | Action |
|---------|--------|
| `:Mix <task>` | Run any mix task, with tab completion over the project's tasks: `deps.get`, `test`, `ecto.migrate`, ... |
| `:M <task>` | Shorter alias for `:Mix` |

> [!NOTE]
> The plugin also defines an `:Elixir nextls ...` command family, but those subcommands only talk to Next LS, the alternative language server this config does not run.
