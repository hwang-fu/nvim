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
| `grr` | Peek references in the [glance](glance.md) panel (upgraded from the built-in quickfix listing) |
| `grn` | Rename (built in) |
| `gra` | Code actions (built in) |
| `gri` | Go to implementation (built in) |
| `[d` | Previous diagnostic (built in) |
| `]d` | Next diagnostic (built in) |

Formatting runs automatically on save, per language; `lua/hwangfu/lsp/format.lua` defines which formatter each language uses.

Peeking locations in an embedded panel - references, definitions, implementations - has its own page: [glance](glance.md).

## Per-language pages

Languages with tooling beyond the common keys have their own page:

- [rust](rust.md) - `:RustLsp` extras, `:RustFormat`, hover with actions
- [ocaml](ocaml.md) - Merlin commands, typed holes, the utop REPL
- [haskell](haskell.md) - `:Haskell` subcommands, Hoogle-aware hover
- [elixir](elixir.md) - `:Mix`, pipe rewriting, Phoenix scaffolding
- [lisp](lisp.md) - buffer evaluation with conjure; SLIME for Common Lisp (the lisps use the common keys above for LSP itself)

Every other language (Go, Python, C, Erlang, Clojure, Racket, Fennel, and the rest) uses exactly the keys above.
