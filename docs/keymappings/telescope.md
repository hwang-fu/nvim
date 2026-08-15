# Telescope

*Defined in `lua/hwangfu/telescope.lua`.*

| Key | Picker |
|-----|--------|
| `<leader>ff` | Files by name |
| `<leader>fF` | Files by name, including ignored and hidden ones |
| `<leader>fg` | Live grep across the project |
| `<leader>fG` | Live grep, including ignored and hidden files |
| `<leader>fs` | Grep the word under the cursor |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recently opened files |
| `<leader>fd` | Project diagnostics |
| `<leader>fh` | Neovim help |
| `<leader>fk` | All keymaps - handy for discovering bindings |

Every picker is also a command: `:Telescope <picker>`, and bare `:Telescope` lists them all.

Both search pickers respect ignore files by default. To look past them: `:Telescope find_files no_ignore=true hidden=true` (`no_ignore` skips `.gitignore` rules, `hidden` adds dotfiles; each works alone), and `:Telescope live_grep additional_args=--no-ignore` for grep, where the flag goes straight to ripgrep (add `--hidden` for dotfiles).

Inside a picker: `Down` / `Up` (or `Ctrl-N` / `Ctrl-P`) move, `Enter` opens, `Ctrl-X` / `Ctrl-V` / `Ctrl-T` open in a split / vsplit / tab, `Ctrl-U` / `Ctrl-D` scroll the preview, `Ctrl-C` closes, and `Ctrl-/` shows telescope's own mappings.
