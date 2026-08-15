# Everything else

## Surround

vim-surround runs with its stock keys; `{char}` is the pair character (`"`, `'`, `)`, `]`, `}`, `t` for an HTML tag, ...).

| Key | Action |
|-----|--------|
| `ys{motion}{char}` | Add a surrounding pair around the motion: `ysiw"` quotes the word under the cursor |
| `cs{old}{new}` | Change one pair into another: `cs'"` turns single quotes into double |
| `ds{char}` | Delete the pair: `ds(` removes the parentheses |
| `S{char}` | In visual mode, wrap the selection |

## Maintenance commands

| Command | Action |
|---------|--------|
| `:ToggleWS` | Toggle whitespace visualization for the current window (defined in `lua/hwangfu/init.lua`) |
| `:Lazy` | Open the plugin manager |
| `:Lazy sync` | Install and update plugins |
| `:TSInstall <lang>` | Install a treesitter parser |
| `:TSUpdate` | Update the installed treesitter parsers |

## Automatic colorschemes

Colorschemes switch by filetype with no keybinding (`lua/hwangfu/colors.lua`): web and markup files get 256_noir, everything else gets dracula on a dark-green background.
