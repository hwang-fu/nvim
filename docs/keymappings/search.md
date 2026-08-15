# Searching

One page for "where is it?" - in the current file, across the project, and by symbol. The heavy lifting is shared between telescope, flash, and the LSP; this page is the map.

## In the current file

| Key | Action |
|-----|--------|
| `*` / `#` | Search the word under the cursor, forward / backward (built in) |
| `n` / `N` | Repeat the last search, forward / backward (built in) |
| `<leader>f/` | Fuzzy search the buffer's lines in a picker - scattered letters match, no regex |
| `s` | Flash jump: type two characters, every match on screen gets a one-letter label, press the label to land there. Works in normal, visual, and operator-pending mode - `ds` + label deletes up to it |
| `S` | Flash treesitter select: labels appear on the syntax constructs around the cursor (expression, call, function); pick one to select it |
| `/` and `?` | The built-in searches; starting with `/` switches to modern regex syntax where `+`, `(`, and `|` work without backslashes |

Flash's `s` / `S` shadow the built-in synonyms for `cl` and `cc`; those spellings still work.

## Across the project

| Key | Action |
|-----|--------|
| `<leader>fg` | Live grep, respecting ignore files ([telescope](telescope.md)) |
| `<leader>fG` | Live grep, including ignored and hidden files |
| `<leader>fs` | Grep the word under the cursor |

## By symbol

| Key | Action |
|-----|--------|
| `grr` | Peek every reference in the [glance](lsp/glance.md) panel |
| `gd` | Jump to the definition ([lsp](lsp/lsp.md)) |
| `:Telescope lsp_workspace_symbols` | Fuzzy search every symbol in the project by name |

## Replacing

| Key / command | Action |
|---------------|--------|
| `<leader>rn` | Rename the symbol under the cursor across the project, semantically ([lsp](lsp/lsp.md)) |
| `Ctrl-R` (visual) | Search-and-replace the selected text across the current file ([editor](editor.md)) |
| `Alt-Q` in a grep picker, then `:cfdo %s/old/new/ge | update` | Project-wide text replace: send the matches to the quickfix list, then run the substitution over every listed file |
