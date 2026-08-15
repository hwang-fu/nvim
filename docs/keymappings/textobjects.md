# Structural editing

*Defined in `lua/hwangfu/plugins/spec/textobjects.lua` (nvim-treesitter-textobjects).*

## Text objects

A text object does nothing on its own - it names a *region* for another key to act on. The pattern is always **verb + object**: `v` selects the region, `d` deletes it, `y` copies it, `c` deletes it and drops you into insert mode. It is the same grammar as Vim's built-in `diw` (delete a word) - these objects just name code regions instead of words.

The `a` / `i` prefix chooses how much: `a` is *around* (the whole construct), `i` is *inner* (only its inside).

| Object | Region it names |
|--------|-----------------|
| `af` | A whole function, signature included |
| `if` | Only the function's body |
| `ac` | A whole class - or struct / impl / module in languages without classes |
| `ic` | Only the class body |
| `aa` | One argument, including its separating comma |
| `ia` | Just the argument itself |

## Common combinations

| Keys | Effect |
|------|--------|
| `vaf` | Select the whole function under the cursor |
| `yaf` | Copy the whole function, ready to paste elsewhere |
| `daf` | Delete the whole function |
| `cif` | Clear the function's body for a rewrite, keeping the signature |
| `vac` | Select the whole class to eyeball its extent |
| `dic` | Empty a class, keeping its header |
| `daa` | Remove an argument from a call without leaving a stray comma |
| `cia` | Retype an argument, commas untouched |

The cursor only needs to be *anywhere inside* the target: `daf` from deep in a function body still deletes that whole function. If the cursor sits before any function, lookahead targets the next one instead of failing.

## Motions

These are ordinary keypresses - no verb needed:

| Key | Action |
|-----|--------|
| `]f` | Jump to the start of the next function |
| `[f` | Jump to the start of the previous function |
| `]F` | Jump to the end of the next function |
| `[F` | Jump to the end of the previous function |
| `]]` | Jump to the next class |
| `[[` | Jump to the previous class |

They also extend a visual selection, and combine with verbs like any motion: `d]f` deletes from the cursor to the next function start.

## Notes

- Works in every treesitter language here except Erlang, which has no upstream queries - the keys quietly do nothing there.
- Hunk navigation lives on `]h` / `[h` (see [git](git.md)); `]c` / `[c` keep their built-in diff-mode meaning.
- Jumps land in the jump list, so `Ctrl-O` returns after an overshoot.
