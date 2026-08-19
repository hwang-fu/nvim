# File explorer

*Defined in `lua/jwn/plugins/spec/oil.lua`, with the sidebar logic in `lua/jwn/explorer.lua`.*

`Ctrl-T` (see [navigation](navigation.md)) toggles a 35-column sidebar listing the current buffer's directory. Pressing `Enter` on a folder replaces the listing in place - oil shows one directory per buffer and cannot expand a tree inline. Pressing `Enter` on a file opens it in the main window and closes the sidebar.

A listing is an ordinary buffer you edit like text, and `:w` applies your edits to the filesystem: type a name to create a file, end it with `/` for a folder, rename in place, `dd` a line to delete (permanently), or `yy` and `p` to copy. Every save shows a confirmation first.

| Key | Action |
|-----|--------|
| `Enter` | Open the entry. On the `../` first row, go up one directory |
| `-` or `..` | Go up one directory |
| `_` | Show Neovim's working directory instead |
| `` ` `` | Change Neovim's working directory to the one being viewed |
| `Ctrl-T` | Close the sidebar or listing |
| `Ctrl-H` | Open the entry in a horizontal split |
| `Ctrl-V` | Open the entry in a vertical split |
| `Ctrl-P` | Preview the entry in a float |
| `Ctrl-S` | Refresh the listing from disk |
| `g.` | Toggle hidden dotfiles (shown by default) |
| `gs` | Change the sort order |
| `gx` | Open the entry with your desktop's default application for that file type - image viewer for pictures, PDF reader, browser for HTML (via xdg-open) |
| `g?` | Oil's own key help |

`Ctrl-S` deliberately does not save here: a mistyped save gesture re-reads the listing instead of applying pending filesystem operations. `:w` is the one apply key.
