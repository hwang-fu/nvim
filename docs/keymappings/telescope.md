# Telescope

*Defined in `lua/jwa/telescope.lua`.*

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

## Where the file and grep pickers search

The seven pickers that walk a directory - `<leader>t`, `<leader>T`, `<leader>ff`, `<leader>fF`, `<leader>fg`, `<leader>fG` and `<leader>fs` - search the **project root**, not the working directory. The root is the nearest `.git` above the file you are in; outside a repository it falls back to the nearest `.git` above the directory Neovim was started in, and then to that directory itself.

This is deliberate rather than incidental. The working directory follows whatever buffer you are looking at (see [misc](misc.md#the-working-directory-follows-the-file)), so a picker left on its default scope would search the one folder that file happens to live in and quietly return fewer results. Pinning the root keeps "search the project" true wherever you are in it.

To search somewhere else on purpose, pass a directory: `:Telescope live_grep cwd=%:p:h` greps just the current file's folder, and `:Telescope find_files cwd=~/work` looks outside the project entirely.

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
