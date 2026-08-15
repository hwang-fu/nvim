# Navigation keys

*Defined in `lua/hwangfu/keymappings/navigation.lua`.*

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-T` | n | Toggle the file sidebar: a 35-column oil.nvim listing of the current buffer's directory |
| `]b` / `[b` | n | Go to the next / previous buffer, wrapping at the ends |
| `<leader>bd` | n | Close the current buffer |
| `Ctrl-O` / `Ctrl-I` | n | Retrace cursor-position history backward / forward, often across buffers (built in) |
| `Ctrl-^` | n | Flip between the current and previous buffer (built in) |

## Notes

- The keys available *inside* the sidebar are documented in [explorer](explorer.md).
- `Ctrl-O` / `Ctrl-I` record every jump - `gd`, a search, `gg`/`G`, a telescope pick - so they return to the places you have actually been, including several stops inside one file.
- `]b` / `[b` treat the buffer list as a ring: past the last buffer they wrap around to the first. The order is the order files were first opened, not recency. Only listed buffers take part - help pages and the floating terminals are skipped - and closing a buffer with `<leader>bd` simply shrinks the ring.
