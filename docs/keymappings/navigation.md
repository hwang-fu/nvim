# Navigation keys

*Defined in `lua/hwangfu/keymappings/navigation.lua`.*

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-T` | n | Toggle the file sidebar: a 35-column oil.nvim listing of the current buffer's directory |
| `]b` / `[b` | n | Go to the next / previous buffer |
| `<leader>bd` | n | Close the current buffer |

## Notes

- The keys available *inside* the sidebar are documented in [explorer](explorer.md).
- Worth remembering, though built in rather than mapped here: `Ctrl-O` and `Ctrl-I` walk the jump list back and forward after any go-to-definition style jump, and `Ctrl-^` flips to the previous buffer.
