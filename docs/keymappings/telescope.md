# Telescope

*Defined in `lua/hwangfu/telescope.lua`.*

| Key | Picker |
|-----|--------|
| `<leader>t` | Files by name (short form of `<leader>ff`) |
| `<leader>T` | Files by name, including ignored and hidden (short form of `<leader>fF`) |
| `<leader>ff` | Files by name |
| `<leader>fF` | Files by name, including ignored and hidden ones |
| `<leader>fg` | Live grep across the project |
| `<leader>fG` | Live grep, including ignored and hidden files |
| `<leader>fs` | Grep the word under the cursor |
| `<leader>f/` | Fuzzy search the current buffer's lines - no regex needed |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recently opened files |
| `<leader>fd` | Project diagnostics |
| `<leader>fh` | Neovim help |
| `<leader>fk` | All keymaps - handy for discovering bindings |

Every picker is also a command: `:Telescope <picker>`, and bare `:Telescope` lists them all.

## Inside a picker

| Key | Action |
|-----|--------|
| `Down` | Next result (also `Ctrl-N`) |
| `Up` | Previous result (also `Ctrl-P`) |
| `Enter` | Open the selected result |
| `Ctrl-X` | Open it in a horizontal split |
| `Ctrl-V` | Open it in a vertical split |
| `Ctrl-T` | Open it in a new tab |
| `Ctrl-U` | Scroll the preview up |
| `Ctrl-D` | Scroll the preview down |
| `Ctrl-Q` | Close the picker (also `Esc`) |
| `Ctrl-/` | Show telescope's own mappings |
