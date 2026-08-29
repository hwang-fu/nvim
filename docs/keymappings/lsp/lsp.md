# Language server keys

*Defined in `lua/jwa/lsp/helpers.lua`; active in any buffer with a language server attached.*

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

Formatting runs automatically on save, per language; `lua/jwa/lsp/format.lua` defines which formatter each language uses.

Messages a server pushes on its own - a formatter refusing a file it cannot parse, a project failing to load - arrive as a single yellow line and never interrupt what you are doing. Server **errors** are shown at warning level deliberately: an error-level message echoed while a save was in flight used to abort the write itself, so the file stayed unsaved behind the error text. Long messages are cut to fit one line. Diagnostics are untouched by this - a real fault still marks the offending line in the buffer, which is where the detail belongs. The handler is in `lua/jwa/lsp/init.lua`.

Peeking locations in an embedded panel - references, definitions, implementations - has its own page: [glance](glance.md).

## Schema checking for config files

JSON, YAML, and TOML files that are known by name get validated against their official schema: wrong types and misspelled keys become diagnostics, completion offers the legal keys and values, and `K` on a key shows its documentation.

| Filetype | Covered files | How |
|----------|---------------|-----|
| JSON | `package.json`, `tsconfig.json`, `.eslintrc`, and everything else the [schemastore.org](https://www.schemastore.org) catalog knows by name | jsonls + the SchemaStore.nvim plugin |
| YAML | GitHub workflows, docker-compose, and the rest of the same catalog | yamlls fetches the catalog itself |
| TOML | `Cargo.toml`, `pyproject.toml`, `.taplo.toml` only | taplo, with the schemas pinned one by one - taplo 0.10 can no longer parse the catalog (details in `lua/jwa/lsp/servers/taplo.lua`) |

A YAML file the catalog does not recognize can name its own schema in a first-line comment: `# yaml-language-server: $schema=<url>`. JSON files do the same with a top-level `"$schema"` key.

## Per-language pages

Languages with tooling beyond the common keys have their own page:

- [rust](rust.md) - `:RustLsp` extras, `:RustFmt`, hover with actions
- [ocaml](ocaml.md) - Merlin commands, typed holes, the utop REPL
- [haskell](haskell.md) - `:Haskell` subcommands, Hoogle-aware hover
- [elixir](elixir.md) - `:Mix`, pipe rewriting, Phoenix scaffolding
- [lisp](lisp.md) - buffer evaluation with conjure; SLIME for Common Lisp (the lisps use the common keys above for LSP itself)

Every other language (Go, Python, C, Java, CMake, Erlang, Clojure, Racket, Fennel, and the rest) uses exactly the keys above.
