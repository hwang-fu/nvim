# Mouse keys

*Defined in `lua/hwangfu/keymappings/mouse.lua`.*

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-LeftClick` | n | Smart jump on the clicked symbol (see below) |

The smart jump behaves like VSCode's Ctrl+click:

- Clicking a **usage** jumps to the symbol's definition.
- Clicking a symbol **at its own definition** opens its references in the quickfix list instead.
- In a buffer **without a language server**, it falls back to a classic ctags jump, and failures print one quiet notice.

Jump back with `Ctrl-O`. The built-in right-click menu also offers "Go to definition".
