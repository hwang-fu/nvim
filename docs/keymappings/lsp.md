# Language server keys

*Defined in `lua/hwangfu/lsp/helpers.lua`; active in any buffer with a language server attached.*

| Key | Action |
|-----|--------|
| `K` | Hover documentation. Press `K` again to enter the popup; `q` closes it |
| `Ctrl-K` | Signature help, also while typing in insert mode |
| `gd` / `gD` | Go to definition / declaration |
| `gt` / `gi` | Go to type definition / implementation |
| `<leader>rn` | Rename the symbol across the project |
| `<leader>ca` | Code actions |
| `gl` | Show this line's diagnostics in a float |
| `grr` / `grn` / `gra` / `gri` | Neovim's built-ins for references / rename / actions / implementation |
| `[d` / `]d` | Previous / next diagnostic (built in) |

Formatting runs automatically on save, per language; `lua/hwangfu/lsp/format.lua` defines which formatter each language uses.

## Per-language extras

- **Rust** (rustaceanvim): `:RustLsp <verb>` reaches rust-analyzer's extras - expandMacro, explainError, openDocs, runnables, debuggables, parentModule, and more - plus the custom `:RustFormat`. `K` is upgraded to hover-with-actions.
- **Haskell** (haskell-tools): `:Haskell <subcommand>` covers hover, doctest evaluation, a GHCi REPL toggle, and project navigation. `K` is upgraded to Hoogle-aware hover. Telescope integration lives under `:Telescope ht`.
- **Elixir** (elixir-tools): `:Mix <task>` runs mix tasks with completion, `:ElixirFromPipe` and `:ElixirToPipe` rewrite between pipe and call syntax, `:ElixirExpandMacro` expands macros, and the projectionist `:E*` commands scaffold Phoenix files.
- **OCaml** (ocaml.nvim): `:OCaml*` commands expose the Merlin features standard LSP cannot reach; see [ocaml](ocaml.md). Unlike the plugins above, ocaml.nvim does not own the LSP client - ocamllsp runs natively, with inlay hints and type-signature codelenses enabled.
