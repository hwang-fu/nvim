# Telescope

*Defined in `lua/hwangfu/telescope.lua`.*

| Key | Picker |
|-----|--------|
| `<leader>ff` | Files by name |
| `<leader>fg` | Live grep across the project |
| `<leader>fs` | Grep the word under the cursor |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recently opened files |
| `<leader>fd` | Project diagnostics |
| `<leader>fh` | Neovim help |
| `<leader>fk` | All keymaps - handy for discovering bindings |

Every picker is also a command: `:Telescope <picker>`, and bare `:Telescope` lists them all.

Inside a picker: `Ctrl-N` / `Ctrl-P` move, `Enter` opens, `Ctrl-X` / `Ctrl-V` / `Ctrl-T` open in a split / vsplit / tab, `Ctrl-U` / `Ctrl-D` scroll the preview, `Ctrl-C` closes, and `Ctrl-/` shows telescope's own mappings.
