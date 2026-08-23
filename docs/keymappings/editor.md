# Editor keys

*Defined in `lua/jwa/keymappings/editor.lua`.*

Familiar shortcuts from mainstream editors, layered on top of Vim without touching its core motions.

## What `Ctrl-S` does

`Ctrl-S` checks the file on disk before writing, so it never silently overwrites changes someone else made while you were editing:

| Situation | What happens |
|-----------|--------------|
| Only you changed the buffer | Ordinary save |
| Only the disk changed (you have no unsaved edits) | The buffer refreshes to the newest on-disk version; nothing is written, and a notice says so |
| Both changed | A prompt asks which version wins: `Mine` overwrites the disk, `Theirs` discards your edits and loads the disk version, `Cancel` (the default) leaves your edits in the buffer and their version on disk |

The same watchfulness applies in the background: when Neovim notices an outside change (for example on window focus), clean buffers quietly follow the disk, and a buffer with unsaved edits is kept and flagged once - the decision then waits for your next `Ctrl-S`.

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-S` | n, i, v | Disk-aware save (see below). In visual mode the selection is dropped first |
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
