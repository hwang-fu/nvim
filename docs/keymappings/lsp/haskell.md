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

## Formatting

Haskell does not format on save - a save leaves the file exactly as you typed it. `:HaskellFmt` formats the current buffer when you ask, through HLS and whichever formatter `formattingProvider` names (ormolu, set in `lua/jwa/lsp/servers/hls.lua`). The command lives in `after/ftplugin/haskell.lua` and exists in literate `.lhs` buffers too.

A buffer that does not parse yet - mid-edit, a mismatched bracket - is refused by ormolu and left alone, with a one-line yellow warning saying so; the parse error itself is already marked on the offending line as a diagnostic. With no HLS attached the command says so rather than quietly doing nothing.

`:FormatNotOnSave` does not affect `:HaskellFmt` - that switch silences saves, and this is an explicit request.

> [!NOTE]
> Highlighting and hints run rich: the HLS semanticTokens plugin colors type-level names, class methods, record fields, and pattern synonyms distinctly on top of treesitter, and the inlay-hint plugins (record-field expansions for wildcards, explicit import lists) are active - both ship on by default in HLS 2.14, with semanticTokens enabled in `lua/jwa/lsp/servers/hls.lua`.
