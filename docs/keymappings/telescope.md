# Telescope (lua/hwangfu/telescope.lua)

| Key | Picker |
|-----|--------|
| `<leader>ff` | Find files by name |
| `<leader>fg` | Live grep project contents |
| `<leader>fs` | Grep word under cursor |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recent files |
| `<leader>fd` | Project diagnostics |
| `<leader>fh` | Neovim help |
| `<leader>fk` | Search every keymap (discovery tool) |

All pickers also via `:Telescope <picker> [key=value ...]`; bare
`:Telescope` lists every picker. Inside the popup: Ctrl-N/P move, Enter
opens, Ctrl-X/Ctrl-V/Ctrl-T open in split/vsplit/tab, Ctrl-U/D scroll
preview, Ctrl-C closes, Ctrl-/ shows telescope's own mappings.
