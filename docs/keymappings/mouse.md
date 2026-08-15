# Mouse keys

*Defined in `lua/hwangfu/keymappings/mouse.lua`.*

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-LeftClick` | n | Smart jump on the clicked symbol (see below) |
| `Ctrl-RightClick` | n | Ripgrep the clicked word across the project: live grep opens pre-filled with it; erase the prefill to search for anything else. The buffers picker this used to open lives on `<leader>fb` |

The smart jump behaves like VSCode's Ctrl+click:

- Clicking a **usage** jumps to the symbol's definition.
- Clicking a symbol **at its own definition** opens its references in the quickfix list instead.
- In a buffer **without a language server**, it falls back to a classic ctags jump and says so briefly when nothing is found.

Jump back with `Ctrl-O`.

The two Ctrl-clicks form a pair: `Ctrl-LeftClick` asks where the symbol is *defined*, `Ctrl-RightClick` asks where the *text appears*.

## Plain right-click

A right-click without any modifier is Neovim's stock behavior, no plugin involved: the cursor first moves to the clicked position, then the built-in popup menu opens.

| Entry | Action |
|-------|--------|
| Inspect | Runs `:Inspect`: shows the treesitter and highlight groups under the cursor - the tool for answering "why is this colored like that?" |
| Go to definition | The LSP definition jump on the clicked symbol, same target as `gd` and `Ctrl-LeftClick`; prints "No locations found" on comments, plain text, or buffers without a server |
| Paste | Paste the clipboard at the click position |
| Select All | Select the whole buffer |
| How-to disable mouse | Opens the help page on turning mouse support off |

The menu itself is editable - Neovim treats it as an ordinary menu named `PopUp` - but this config leaves the stock entries as they are.
