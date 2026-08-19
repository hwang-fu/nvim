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
| `:ToggleWS` | Toggle whitespace visualization for the current window (defined in `lua/jwn/init.lua`) |
| `:checkhealth jwn` | The fresh-machine report: everything this config wants that the machine lacks - editor tools, build prerequisites, formatters, linters, language servers |
| `:Lazy` | Open the plugin manager |
| `:Lazy sync` | Install and update plugins |
| `:TSInstall <lang>` | Install a treesitter parser |
| `:TSUpdate` | Update the installed treesitter parsers |

## The phantom final-newline line

File buffers show one extra `~` line below their last line, with no line number and colored like a comment: that is the file's final newline made visible - the `\n` POSIX requires at the end of every text file, which Vim normally keeps implicit. It is display only: not part of the buffer, impossible to move the cursor into, and it adds nothing on save. Terminals, pickers, and the file sidebar do not show it.

## Automatic colorschemes

Colorschemes switch by filetype with no keybinding (`lua/jwn/colors.lua`): web and markup files get 256_noir, everything else gets dracula on a dark-green background.
