# Mouse keys

*Defined in `lua/jwa/keymappings/mouse.lua`.*

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-LeftClick` | n | Smart jump on the clicked symbol (see below) |
| `Ctrl-RightClick` | n | Live grep across the open buffers: an empty ripgrep prompt whose search scope is just the files currently open. Buffers by name stay on `<leader>fb`, whole-project grep on `<leader>fg` |

The smart jump behaves like VSCode's Ctrl+click:

- Clicking a **usage** jumps to the symbol's definition.
- Clicking a symbol **at its own definition** opens its references in the quickfix list instead.
- In a buffer **without a language server**, it falls back to a classic ctags jump and says so briefly when nothing is found.

Jump back with `Ctrl-O`.

> [!NOTE]
> The `Ctrl-RightClick` grep reads files from disk, as ripgrep does - unsaved buffer modifications are invisible to it, and unnamed scratch buffers are not searched.

## Plain right-click

A right-click without any modifier is Neovim's stock behavior, no plugin involved: the cursor first moves to the clicked position, then the built-in popup menu opens.

| Entry | Action |
|-------|--------|
| Inspect | Runs `:Inspect`: shows the treesitter and highlight groups under the cursor - the tool for answering "why is this colored like that?" |
| Go to definition | The LSP definition jump on the clicked symbol, same target as `gd` and `Ctrl-LeftClick`; prints "No locations found" on comments, plain text, or buffers without a server |
| Paste | Paste the clipboard at the click position |
| Select All | Select the whole buffer |
| How-to disable mouse | Opens the help page on turning mouse support off |
| Find file | Open the file finder, same as `<leader>t` (added by this config; the rows above are Neovim's stock entries) |
| Search inside project | Live grep across the project, same as `<leader>fg` (added by this config) |

The menu is an ordinary Neovim menu named `PopUp`; this config appends its own entries below the stock ones, in `lua/jwa/keymappings/mouse.lua`.
