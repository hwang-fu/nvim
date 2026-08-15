# Editor keys

*Defined in `lua/hwangfu/keymappings/editor.lua`.*

Familiar shortcuts from mainstream editors, layered on top of Vim without touching its core motions.

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-S` | n, i, v | Save the file. In visual mode the selection is dropped first |
| `Ctrl-Q` | n | Quit the window. In insert or visual mode it shows an error instead, telling you to press Esc first |
| `Ctrl-D` | v | Copy the selection to the system clipboard |
| `Ctrl-X` | v | Cut the selection to the system clipboard |
| `Ctrl-A` | n, i | Select the whole file |
| `Ctrl-U` | n | Undo |
| `Ctrl-Z` | n, i | Undo. From insert mode it leaves insert first, so it reverts everything typed since insert began |
| `Ctrl-R` | n | Search-and-replace the character under the cursor: the command line is pre-filled and previews live as you type the replacement |
| `Ctrl-R` | v | The same, for the selected text |
| `Ctrl-/` | n, v | Toggle comments on the current line or selection |
| `Shift-arrows` | n | Start a selection and extend it in that direction |
| `Ctrl-Up` | n, i, v | Scroll up without moving the cursor; in visual mode extend the selection up a line |
| `Ctrl-Down` | n, i, v | Scroll down without moving the cursor; in visual mode extend the selection down a line |
| `Ctrl-Left` | n, i, v | Move one word left; in visual mode extend the selection |
| `Ctrl-Right` | n, i, v | Move one word right; in visual mode extend the selection |
| `Alt-Up` | n, i, v | Move the current line or selected block up, re-indenting |
| `Alt-Down` | n, i, v | Move the current line or selected block down, re-indenting |

## Notes

- `Ctrl-R` shadows Vim's built-in redo; use `:redo` when you need it. Inside insert mode, `Ctrl-R` keeps its built-in meaning (insert from a register).
- `Ctrl-_` triggers the same comment toggle: older terminals and default tmux send the physical Ctrl+/ keypress as `Ctrl-_`.
