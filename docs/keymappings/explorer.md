# File explorer - oil.nvim (spec in lua/hwangfu/plugins/spec/oil.lua; sidebar in lua/hwangfu/explorer.lua)

Ctrl-T (global, see [navigation](navigation.md)) toggles a 35-column
left SIDEBAR (2026-08-14; previously full-window) listing the current
buffer's directory. Sidebar behavior: Enter on a folder replaces the
listing in place (oil is one directory per buffer by design and cannot
expand a tree inline - accepted trade-off vs switching to nvim-tree);
Enter on a file opens it in the MAIN window and closes the sidebar.
Listings are still buffers you edit like text; `:w` applies the
operations (create by typing names, `newdir/` for folders, rename in
place, dd deletes - PERMANENTLY, yy+p copies). Buffer-local:

| Key | Action |
|-----|--------|
| Enter | Open entry (see sidebar behavior above); on the `../` first row: go up one directory (NERDTree-style, added 2026-08-14) |
| - or .. | Go up one directory |
| _ | Listing of nvim's cwd |
| ` | :cd into the viewed directory |
| Ctrl-T / Ctrl-C | Close the sidebar (or a full-window listing) |
| Ctrl-H | Open entry in horizontal split |
| Ctrl-P | Preview entry in a float |
| Ctrl-L | Refresh from disk |
| g. | Toggle hidden dotfiles |
| gs / gx | Change sort / open with system handler |
| g? | Oil's full key help |

(Oil's default Ctrl-S vsplit is disabled so Ctrl-S stays "save".)
