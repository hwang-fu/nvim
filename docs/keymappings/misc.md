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
| `:ToggleWS` | Toggle whitespace visualization for the current window (defined in `lua/jwa/init.lua`) |
| `:checkhealth jwa` | The fresh-machine report: everything this config wants that the machine lacks - editor tools, build prerequisites, formatters, linters, language servers |
| `:Lazy` | Open the plugin manager |
| `:Lazy sync` | Install and update plugins |
| `:TSInstall <lang>` | Install a treesitter parser |
| `:TSUpdate` | Update the installed treesitter parsers |

## The phantom final-newline line

File buffers show one extra `~` line below their last line, with no line number and colored like a comment: that is the file's final newline made visible - the `\n` POSIX requires at the end of every text file, which Vim normally keeps implicit.

The line is real and reachable: `j` onto it, and `G` deliberately lands on it - it is the end of the file. On disk nothing changes: the write skips the phantom through end-of-line bookkeeping (no buffer edit involved, so undo history survives saves), files keep exactly one final newline, and deleting the line in the buffer just grows it back.

Keys behave specially on it (Helix semantics):

| Key on the `~` line | Action |
|---------------------|--------|
| `a` or `i` | Insert at the end of the last content line |
| `o` or `O` | Open a new content line at the end of the file |
| `dd`, `x` | Effectively nothing - the final newline is mandatory, so the line restores itself |
| `p` | Pasted text becomes real content at the end of the file; a fresh `~` line grows below |

Terminals, pickers, diff views, and the file sidebar do not have the line.

> [!NOTE]
> Git does not see it either: gitsigns reads the buffer through a small shim that drops the phantom, so a clean file shows no `+1`, and staging a hunk or the whole buffer never writes the phantom into the index. `:checkhealth jwa` reports the shim's state; if a gitsigns update ever breaks it, phantom lines disable themselves rather than risk the index.

## Colorscheme

One global theme for every file: dracula-soft, set at startup in `lua/jwa/colors.lua`, with two overrides on top: the editor background is pinned to the kitty terminal's background color (`#32324e`) so the pane blends into the terminal, and italics are stripped from code highlighting (builtin types, specials, todo markers) - markup emphasis in markdown and HTML keeps its slant. (The old per-filetype switching - 256_noir for web files, dracula on a dark-green background for the rest - was retired 2026-08-23; the alternate schemes in `colors/` and the colorscheme plugins remain installed for `:colorscheme` experiments.)
