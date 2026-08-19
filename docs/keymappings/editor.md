# Editor keys

*Defined in `lua/jwn/keymappings/editor.lua`.*

Familiar shortcuts from mainstream editors, layered on top of Vim without touching its core motions.

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-S` | n, i, v | Save the file. In visual mode the selection is dropped first |
| `Ctrl-Q` | n | Quit the window. In insert or visual mode it shows an error instead, telling you to press Esc first |
| `Ctrl-D` | v | Copy the selection to the system clipboard |
| `Ctrl-X` | v | Cut the selection to the system clipboard |
| `Ctrl-A` | n, i | Select the whole file |
| `Ctrl-U` | n | Undo |
| `Ctrl-Z` | n | Undo |
| `Ctrl-R` | n | Redo (built in) |
| `Ctrl-R` | v | Search-and-replace the selected text across the file: the command line is pre-filled and previews live |
| `Ctrl-/` | n, v | Toggle comments on the current line or selection |
| `Shift-arrows` | n | Start a selection and extend it in that direction |

## Notes

- In insert mode `Ctrl-R` keeps its built-in meaning: insert from a register.
- `Ctrl-_` triggers the same comment toggle: older terminals and default tmux send the physical Ctrl+/ keypress as `Ctrl-_`.
