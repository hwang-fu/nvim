# Structural editing

*Defined in `lua/hwangfu/plugins/spec/textobjects.lua` (nvim-treesitter-textobjects).*

Text objects let operators work on syntax units: `vaf` selects a whole function, `dif` deletes just its body, `cia` changes a parameter. The motions jump between those units.

| Key | Action |
|-----|--------|
| `af` / `if` | A function / its body only |
| `ac` / `ic` | A class / its body only. "Class" adapts per language: struct, impl block, or module where there are no classes |
| `aa` / `ia` | A parameter with its comma / the parameter alone |
| `]f` / `[f` | Jump to the next / previous function start |
| `]F` / `[F` | Jump to the next / previous function end |
| `]]` / `[[` | Jump to the next / previous class start |

## Notes

- The selections work in visual and operator-pending mode; the jumps also work in normal mode.
- Every treesitter language here is covered except Erlang, which has no upstream queries - the keys quietly do nothing there.
- `]c` and `[c` are *not* class motions; they belong to [git](git.md) hunk navigation.
- Jumps land in the jump list, so `Ctrl-O` returns after an overshoot.
