# Editor keys

*Defined in `lua/hwangfu/keymappings/editor.lua`.*

Familiar shortcuts from mainstream editors, layered on top of Vim without touching its core motions.

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-S` | n, i, v | Save the file. In visual mode the selection is dropped first |
| `Ctrl-Q` | n | Quit the window. In insert or visual mode it shows an error instead, telling you to press Esc first |
| `Ctrl-C` / `Ctrl-D` | v | Copy the selection to the system clipboard |
| `Ctrl-X` | v | Cut the selection to the system clipboard |
| `Ctrl-A` | n, i | Select the whole file |
| `Ctrl-U` | n | Undo |
| `Ctrl-Z` | n, i | Undo. From insert mode it leaves insert first, so it reverts everything typed since insert began |
| `Ctrl-R` | n | Search-and-replace the character under the cursor: the command line is pre-filled and previews live as you type the replacement |
| `Ctrl-R` | v | The same, for the selected text |
| `Ctrl-/` | n, v | Toggle comments on the current line or selection |
| `Shift-arrows` | n | Start a selection and extend it in that direction |
| `Ctrl-Up` / `Ctrl-Down` | n, i | Scroll without moving the cursor. In visual mode they extend the selection by a line instead |
| `Ctrl-Left` / `Ctrl-Right` | n, i, v | Move by one word. In visual mode the selection extends |
| `Alt-Up` / `Alt-Down` | n, v, i | Move the current line or selected block up or down, re-indenting as it goes |

## Notes

- `Ctrl-R` shadows Vim's built-in redo; use `:redo` when you need it. Inside insert mode, `Ctrl-R` keeps its built-in meaning (insert from a register).
- `Ctrl-_` triggers the same comment toggle as `Ctrl-/`. It is not a second binding to reclaim: older terminals and default tmux deliver the physical Ctrl+/ keypress as `Ctrl-_`, so anything else bound there would fire when you press Ctrl+/.
