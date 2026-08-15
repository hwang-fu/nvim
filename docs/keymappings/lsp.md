# LSP (lua/hwangfu/lsp/init.lua + helpers.lua; buffer-local on attach)

| Key | Action |
|-----|--------|
| K | Hover docs (press K again to enter the popup, q closes) |
| Ctrl-K | Signature help (works in insert mode) |
| gd / gD | Go to definition / declaration |
| gt / gi | Go to type definition / implementation |
| \<leader\>rn | Rename symbol everywhere |
| \<leader\>ca | Code action |
| gl | Line diagnostics float |
| grr / grn / gra / gri | Neovim 0.11 built-ins: references / rename / action / impl |
| [d / ]d | Previous / next diagnostic (built-in) |

Format-on-save runs automatically per-language
(lua/hwangfu/lsp/format.lua). Language extras:

- Rust (rustaceanvim): `:RustLsp <verb>` - expandMacro, explainError,
  openDocs, runnables, debuggables, parentModule, ... plus custom
  `:RustFormat`. K is overridden to `:RustLsp hover actions`.
- Haskell (haskell-tools): `:Haskell <subcommand>` - hover, hls evalAll,
  repl toggle, projectFile, ... K overridden to Hoogle-aware hover.
  Telescope extension: `:Telescope ht ...`.
- Elixir (elixir-tools): `:Mix <task>`, `:ElixirFromPipe`, `:ElixirToPipe`,
  `:ElixirExpandMacro`, `:ElixirRestart`, `:ElixirOutputPanel`,
  projectionist `:E*` commands.
- OCaml (ocaml.nvim): `:OCaml*` commands for the Merlin features standard
  LSP cannot reach - see [ocaml](ocaml.md) for the keymap table. Unlike
  the three above, the plugin does NOT own the LSP client; ocamllsp
  stays native, with inlay hints (let bindings, pattern variables,
  function params) and type-signature codelenses enabled.
