# Keybindings and Commands Reference

Summary of every custom keybinding and plugin command in this config,
one page per domain. Compiled 2026-08-01; updated 2026-08-14 (OCaml
session, oil sidebar, textobjects, which-key, lisp cluster) and
2026-08-15 (smart mouse jump; split from the single KEYBINDINGS.md
into this folder; Ctrl-L comment alias removed; crates keymaps
replaced by :Crates commands). Each page names the file where the bindings are
defined - the comments there carry the full rationale.

Conventions:

- `<leader>` is **Space**
- `<localleader>` is **backslash** (filetype-scoped plugin maps)
- **comma** is slimv's namespace (Common Lisp)
- ASCII-only, like the rest of the config

## Pages

Global keys (defined in `lua/hwangfu/keymappings/`):

- [editor](editor.md) - clipboard, save/quit, substitute, undo, selection, scrolling, word motion, move line, comment toggle
- [mouse](mouse.md) - Ctrl+LeftClick smart definition / references jump
- [navigation](navigation.md) - oil sidebar toggle, buffer cycling

Editing and discovery:

- [textobjects](textobjects.md) - syntax-aware text objects and motions
- [which-key](which-key.md) - keymap discovery popup
- [completion](completion.md) - blink.cmp
- [lsp](lsp.md) - LSP keys + per-language extras
- [telescope](telescope.md) - fuzzy finding

Tools:

- [git](git.md) - gitsigns hunks, lazygit float, diffview
- [explorer](explorer.md) - oil.nvim listings and sidebar
- [markdown](markdown.md) - browser preview + in-buffer render
- [debugging](debugging.md) - nvim-dap F-keys (Rust, OCaml)

Languages:

- [ocaml](ocaml.md) - ocaml.nvim + utop REPL
- [lisp](lisp.md) - conjure, slimv (parinfer / rainbow have no keys)
- [crates](crates.md) - Cargo.toml dependency commands (`:Crates ...`; no keymaps)
- [fhir](fhir.md) - fhir.nvim

Leftovers: [misc](misc.md) - vim-surround, :ToggleWS, :Lazy / :Mason /
:TSInstall, automatic colorschemes.
