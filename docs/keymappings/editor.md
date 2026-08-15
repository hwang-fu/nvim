# Editor keys (lua/hwangfu/keymappings/editor.lua)

Mainstream-editor conventions on top of Vim, without touching core
motions.

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-S` | n, i, v | Save (visual variant exits selection first) |
| `Ctrl-Q` | n | Quit window (i/v: error tells you to Esc first) |
| `Ctrl-C` / `Ctrl-D` | v | Yank selection to system clipboard |
| `Ctrl-X` | v | Cut selection to system clipboard |
| `Ctrl-A` | n, i | Select all |
| `Ctrl-U` | n | Undo |
| `Ctrl-Z` | n, i | Undo (from insert: exits insert and reverts the whole typed chunk) |
| `Ctrl-R` | n | Substitute char under cursor across file (pre-fills :%s) |
| `Ctrl-R` | v | Substitute the visual selection across file |
| `Ctrl-/` (or `Ctrl-_`) | n, v | Toggle comment (delegates to built-in gc) |
| `Ctrl-L` | v | Toggle comment (older alias, same gc) |
| `Shift-arrows` | n | Enter visual mode and extend selection |
| `Ctrl-Up` / `Ctrl-Down` | n, i | Scroll viewport (v: extend selection by line) |
| `Ctrl-Left` / `Ctrl-Right` | n, i, v | Word motion (v extends) |
| `Alt-Up` / `Alt-Down` | n | Move line up / down with re-indent |

Note: Ctrl-R shadows built-in redo (use `:redo`); insert-mode Ctrl-R
keeps the built-in insert-register behavior.
