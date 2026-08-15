# Structural editing

*Defined in `lua/hwangfu/plugins/spec/textobjects.lua` (nvim-treesitter-textobjects).*

## Text objects

A text object does nothing on its own - it names a *region* for another key to act on. The pattern is always **verb + object**: `v` selects the region, `d` deletes it, `y` copies it, `c` deletes it and drops you into insert mode. It is the same grammar as Vim's built-in `diw` (delete a word) - these objects just name code regions instead of words.

The `a` / `i` prefix chooses how much: `a` is *around* (the whole construct), `i` is *inner* (only its inside).

| Object | Region it names | Example use |
|--------|-----------------|-------------|
| `af` | A whole function, signature included | `daf` deletes the function around the cursor; `yaf` copies it to paste elsewhere |
| `if` | Only the function's body | `cif` clears the body for a rewrite but keeps the signature |
| `ac` | A whole class - or struct / impl / module in languages without classes | `vac` selects it to eyeball its extent |
| `ic` | Only the class body | `dic` empties the class, keeping its header |
| `aa` | One argument, including its separating comma | `daa` removes an argument from a call without leaving a stray comma |
| `ia` | Just the argument itself | `cia` retypes an argument, commas untouched |

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
