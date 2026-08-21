# Haskell

*LSP owned by haskell-tools (`lua/jwa/plugins/spec/haskell_tools.lua`); settings in `lua/jwa/lsp/servers/hls.lua`.*

All common [LSP keys](lsp.md) apply, plus:

| Command / key | Action |
|---------------|--------|
| `:Haskell hover` | Hover with Hoogle lookup, open-docs, and find-references as pickable actions |
| `:Haskell hls evalAll` | Evaluate `-- >>>` doctest comments in place |
| `:Haskell repl toggle` | Toggle a GHCi terminal scoped to the project |
| `:Haskell repl cword_type` | GHCi `:type` of the symbol under the cursor |
| `:Haskell projectFile` | Open cabal.project / stack.yaml |
| `K` | Upgraded to the Hoogle-aware hover above |

Telescope integration: `:Telescope ht` offers package-scoped file and grep pickers plus Hoogle signature search.
