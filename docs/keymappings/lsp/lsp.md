# Language server keys

*Defined in `lua/hwangfu/lsp/helpers.lua`; active in any buffer with a language server attached.*

| Key | Action |
|-----|--------|
| `K` | Hover documentation. Press `K` again to enter the popup; `q` closes it |
| `Ctrl-K` | Signature help, also while typing in insert mode |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gt` | Go to type definition |
| `gi` | Go to implementation |
| `<leader>rn` | Rename the symbol across the project |
| `<leader>ca` | Code actions |
| `gl` | Show this line's diagnostics in a float |
| `grr` | List references (built in) |
| `grn` | Rename (built in) |
| `gra` | Code actions (built in) |
| `gri` | Go to implementation (built in) |
| `[d` | Previous diagnostic (built in) |
| `]d` | Next diagnostic (built in) |

Formatting runs automatically on save, per language; `lua/hwangfu/lsp/format.lua` defines which formatter each language uses.

## Peek - glance.nvim

`:Glance references` (or `definitions`, `implementations`, `type_definitions`) opens an embedded panel at the cursor: a location list beside a live preview, for inspecting call sites without leaving the code you are reading. Command-driven, no keymaps of its own. This is the third way to consume LSP locations, next to telescope pickers (find one) and the quickfix list (process all).

Inside the panel:

| Key | Action |
|-----|--------|
| `Down` / `Up` (or `j` / `k`) | Move through the list |
| `Enter` (or `o`) | Jump to the location |
| `Tab` / `S-Tab` | Next / previous location, cycling |
| `v` / `s` / `t` | Open the location in a vsplit / split / tab |
| `Ctrl-U` / `Ctrl-D` | Scroll the preview |
| `q` (or `Esc`) | Close the panel |
| `Ctrl-Q` | Send all locations to the quickfix list and close |

## Per-language pages

Languages with tooling beyond the common keys have their own page:

- [rust](rust.md) - `:RustLsp` extras, `:RustFormat`, hover with actions
- [ocaml](ocaml.md) - Merlin commands, typed holes, the utop REPL
- [haskell](haskell.md) - `:Haskell` subcommands, Hoogle-aware hover
- [elixir](elixir.md) - `:Mix`, pipe rewriting, Phoenix scaffolding

Every other language (Go, Python, C, Erlang, Clojure, Racket, Fennel, and the rest) uses exactly the keys above.
