# Peek - glance.nvim

*Defined in `lua/jwa/plugins/spec/glance.lua`.*

Glance opens an embedded panel at the cursor - a location list beside a live preview - so call sites can be inspected and visited without leaving the code you are reading. It is the third way to consume LSP locations, next to telescope pickers (find one, transient) and the quickfix list (process all, persistent).

In LSP buffers, `grr` opens the references peek. The commands:

| Command | Action |
|---------|--------|
| `:Glance references` | Peek every reference to the symbol under the cursor |
| `:Glance definitions` | Peek its definition |
| `:Glance implementations` | Peek implementations of the interface / trait under the cursor |
| `:Glance type_definitions` | Peek the definition of its type |

## Inside the panel

| Key | Action |
|-----|--------|
| `Down` / `Up` (or `j` / `k`) | Move through the list |
| `Enter` (or `o`) | Jump to the location |
| `Tab` / `S-Tab` | Next / previous location, cycling |
| `v` | Open the location in a vertical split |
| `s` | Open it in a horizontal split |
| `t` | Open it in a new tab |
| `Ctrl-U` / `Ctrl-D` | Scroll the preview |
| `q` (or `Esc`) | Close the panel |
| `Ctrl-Q` | Send all locations to the quickfix list and close |
| `Ctrl-W` `w` | Cycle: list, then the preview window, then back to the code (leaving the panel closes it) |
