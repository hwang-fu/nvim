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

## Per-language pages

Languages with tooling beyond the common keys have their own page:

- [rust](rust.md) - `:RustLsp` extras, `:RustFormat`, hover with actions
- [ocaml](ocaml.md) - Merlin commands, typed holes, the utop REPL
- [haskell](haskell.md) - `:Haskell` subcommands, Hoogle-aware hover
- [elixir](elixir.md) - `:Mix`, pipe rewriting, Phoenix scaffolding

Every other language (Go, Python, C, Erlang, Clojure, Racket, Fennel, and the rest) uses exactly the keys above.
