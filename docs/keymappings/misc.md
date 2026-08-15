# Everything else

- **vim-surround** works with its stock keys: `ys{motion}{char}` adds a surrounding pair, `cs{old}{new}` changes it, `ds{char}` deletes it, and `S{char}` wraps a visual selection.
- `:ToggleWS` toggles whitespace visualization for the current window (defined in `lua/hwangfu/init.lua`).
- `:Lazy` opens the plugin manager; `:Lazy sync` installs and updates.
- `:TSInstall <lang>` and `:TSUpdate` manage treesitter parsers.
- Colorschemes switch automatically by filetype (`lua/hwangfu/colors.lua`), with no keybinding: web and markup files get 256_noir, everything else gets dracula on a dark-green background.
