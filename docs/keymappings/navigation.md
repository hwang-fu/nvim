# Navigation keys

*Defined in `lua/jwa/keymappings/navigation.lua`.*

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-T` | n | Toggle the file sidebar: a 35-column oil.nvim listing of the current buffer's directory |
| `]b` | n | Next buffer - the tab to the right in the bar |
| `[b` | n | Previous buffer - the tab to the left |
| `<leader>bd` | n | Close the current buffer (`:bdelete`) |
| `Ctrl-O` | n | Jump back in cursor-position history, often across buffers (built in, `:h CTRL-O`) |
| `Ctrl-I` | n | Jump forward again (built in, `:h CTRL-I`) |
| `Ctrl-^` | n | Flip between the current and previous buffer (built in) |

## The buffer bar

Every open file gets a tab along the top of the window, the way Notepad++ and Visual Studio show them: filetype icon, name, a dot while there are unsaved changes, and the parent directory added automatically when two open files share a name. Error and warning counts from the language server appear on each tab, so a file breaking while you are looking at another one is visible instead of silent. The bar stays put with a single file open, and clicking a tab switches to it. It comes from bufferline.nvim (`lua/jwa/plugins/spec/bufferline.lua`).

There is no second list to keep in step: the bar draws Neovim's own listed buffers, so opening a file adds a tab and `<leader>bd` removes one. Left-to-right on screen is the same order `]b` walks forward through.

That last point is only true because the ordering is left at its default. Sorting by directory or extension, or dragging a tab to a new position, would impose an order that `:bnext` cannot follow - it is hardcoded to buffer numbers. `]b` and `[b` are therefore bound to bufferline's own cycle commands rather than `:bnext`, so they keep following the bar if that ever changes.

## Notes

- The keys available *inside* the sidebar are documented in [explorer](explorer.md).
- `Ctrl-O` / `Ctrl-I` record every jump - `gd`, a search, `gg`/`G`, a telescope pick - so they return to the places you have actually been, including several stops inside one file.
- `]b` / `[b` treat the buffer list as a ring. With a single buffer open they warn instead of switching.
