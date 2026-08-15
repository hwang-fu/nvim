# Movement keys

*Defined in `lua/hwangfu/keymappings/movement.lua`.*

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-Up` | n, i, v | Scroll up without moving the cursor; in visual mode extend the selection up a line |
| `Ctrl-Down` | n, i, v | Scroll down without moving the cursor; in visual mode extend the selection down a line |
| `Ctrl-Left` | n, i, v | Move one word left; in visual mode extend the selection |
| `Ctrl-Right` | n, i, v | Move one word right; in visual mode extend the selection |
| `Alt-Up` | n, i, v | Move the current line or selected block up, re-indenting |
| `Alt-Down` | n, i, v | Move the current line or selected block down, re-indenting |
| `Alt-H` | n | Make the current window narrower |
| `Alt-L` | n | Make the current window wider |
| `Alt-J` | n | Make the current window shorter |
| `Alt-K` | n | Make the current window taller |

## Notes

- The resize keys step by 2 and repeat while held. Built-ins cover the one-shot cases: `Ctrl-W =` equalizes, `Ctrl-W _` / `Ctrl-W |` maximize, and `:resize N` sets an exact size. Dragging a window separator with the mouse also works.
