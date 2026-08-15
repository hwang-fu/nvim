# Mouse keys (lua/hwangfu/keymappings/mouse.lua)

| Key | Mode | Action |
|-----|------|--------|
| Ctrl-LeftClick | n | Smart jump (see below). Back: Ctrl-O |

Smart jump behavior (VSCode-style, 2026-08-15):

- click a **usage** -> jump to its definition (LSP)
- click a symbol **at its own definition** -> list its references
  in the quickfix list instead (what VSCode does)
- **non-LSP buffer** -> classic ctags jump, with one quiet notice on
  failure instead of the old E433/E426 + press-ENTER pair

The right-click popup menu (Neovim built-in) also offers
"Go to definition".
