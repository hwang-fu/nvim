# Navigation keys

*Defined in `lua/hwangfu/keymappings/navigation.lua`.*

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-T` | n | Toggle the file sidebar: a 35-column oil.nvim listing of the current buffer's directory |
| `]b` / `[b` | n | Go to the next / previous buffer |
| `<leader>bd` | n | Close the current buffer |

## Notes

- The keys available *inside* the sidebar are documented in [explorer](explorer.md).
- Three built-ins pair well with these. `Ctrl-O` and `Ctrl-I` retrace your cursor-position history: every jump is recorded - `gd`, a search, `gg`/`G`, a telescope pick - and since jumps often cross files, retracing them switches buffers too. The difference from `]b`/`[b`: those cycle the buffer list in order, while `Ctrl-O` returns to the places you have actually been, including several stops inside one file. `Ctrl-^` flips between the current and previous buffer.
