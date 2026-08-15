# Keybindings Reference

This folder documents every custom keybinding and user command in the Neovim config, one page per topic. Each page names the file that defines its bindings; the deeper rationale lives in that file's comments, and the change history lives in `git log`.

## Conventions

| Notation | Meaning |
|----------|---------|
| `<leader>` | The Space key |
| `<localleader>` | The backslash key, used for filetype-specific plugin maps |
| `,` | Comma starts slimv's Common Lisp commands |
| n / i / v | Normal, insert, and visual mode |

## Global keys

These are defined in `lua/hwangfu/keymappings/`, one file per page:

- [editor](editor.md) - saving, undo, clipboard, selection, and comment toggling
- [movement](movement.md) - scrolling, word motion, and line moving
- [mouse](mouse.md) - jump to definition with Ctrl+click
- [navigation](navigation.md) - the file sidebar and buffer switching

## Editing and discovery

- [textobjects](textobjects.md) - select or jump between functions, classes, and parameters
- [which-key](which-key.md) - the popup that shows available keys as you type
- [completion](completion.md) - the completion menu
- [lsp](lsp.md) - language server keys, plus per-language extras
- [telescope](telescope.md) - fuzzy finding

## Tools

- [git](git.md) - hunk editing, the lazygit window, and diff views
- [explorer](explorer.md) - the oil.nvim file listings
- [markdown](markdown.md) - browser preview and in-buffer rendering
- [debugging](debugging.md) - the debugger's F-keys

## Languages

- [ocaml](ocaml.md) - OCaml editing commands and the utop REPL
- [lisp](lisp.md) - evaluating Lisp code from the buffer
- [crates](crates.md) - Cargo.toml dependency commands
- [fhir](fhir.md) - FHIR resource tooling

And [misc](misc.md) collects the small leftovers: vim-surround, maintenance commands, and the automatic colorschemes.
