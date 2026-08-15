-- ============================================================================
-- Global keymappings: entrypoint + master index.
--
-- Goal: make Neovim feel closer to mainstream editor conventions for the
-- handful of universal shortcuts (Ctrl-S to save, Ctrl-A to select all,
-- Ctrl-arrow word navigation, Alt-arrow line moving) WITHOUT touching
-- Vim's core motions.
--
-- STRUCTURE (split from the single lua/hwangfu/keymap.lua on 2026-08-15,
-- one file per domain; each file documents its own maps in full):
--   * editor.lua      - the editing shortcuts:
--                         Clipboard         Ctrl-D yank, Ctrl-X cut (v)
--                         Save / quit       Ctrl-S (n/i/v), Ctrl-Q (n)
--                         Substitute        Ctrl-R (v: selection; n is
--                                           built-in redo)
--                         Undo              Ctrl-U / Ctrl-Z (n)
--                         Select all        Ctrl-A (n/i)
--                         Visual selection  Shift+arrows (n)
--                         Comment toggle    Ctrl-/ (n + v; Ctrl-_ is the
--                                           same keypress in legacy
--                                           terminal encodings, not a
--                                           free key)
--   * movement.lua    - Scrolling         Ctrl+Up/Down
--                       Word motion       Ctrl+Left/Right
--                       Move line         Alt+Up/Down
--   * mouse.lua       - Ctrl+LeftClick smart jump: LSP definition;
--                       references when clicked at the definition
--                       itself; quiet ctags fallback in non-LSP
--                       buffers (back: <C-o>)
--   * navigation.lua  - Ctrl-T oil sidebar toggle (see
--                       lua/hwangfu/explorer.lua); ]b / [b buffer
--                       cycle, <leader>bd close buffer
--
-- NOT in this folder (buffer-local maps defined where their plugin is
-- configured, in lua/hwangfu/plugins/spec/<plugin>.lua):
--   * Git hunks         - ]c / [c, <leader>h*, <leader>tb, <leader>tw, ih
--                         (gitsigns.nvim spec; see its "Keymap quick
--                         reference" comment for the full table)
--   * Oil buffer keys   - <CR> open (also on the always-visible ../ first
--                         row, NERDTree-style), - / .. up, g. hidden,
--                         dd + :w ops (oil.nvim spec; see its "Keymap
--                         quick reference" comment for the full table)
--   * Git UI            - <leader>gg lazygit float (lua/hwangfu/git.lua);
--                         <leader>gd / gh / gH diffview (its spec's keys)
--   * Browser preview   - <leader>mp start / ms close / mt pick
--                         (live-preview.nvim spec)
--   * Markdown render   - <leader>mr (or :MarkdownRender toggle) toggles
--                         in-buffer rendering on/off (render-markdown.nvim
--                         spec; lazy `ft`/`keys`/`cmd` triggers, default on)
--   * Textobjects       - af/if, ac/ic, aa/ia (visual + operator-
--                         pending); ]f/[f, ]F/[F, ]]/[[ motions
--                         (nvim-treesitter-textobjects spec; ]c/[c stay
--                         with gitsigns hunks)
--   * Keymap discovery  - which-key popup on any pending prefix; leader
--                         groups labeled in its spec (which-key.nvim)
--   * OCaml editing     - <localleader>* in OCaml buffers, <localleader>
--                         being backslash: \c construct/fill hole, \n / \p
--                         next / prev hole, \s switch .ml/.mli, \i infer
--                         interface, \t type enclosing, \j jump
--                         (ocaml.nvim spec; see its command reference
--                         comment for the full table)
--   * OCaml REPL        - <localleader>r toggle the project-scoped utop
--                         float (lua/hwangfu/repl.lua)
--   * Lisp eval         - conjure: <localleader>e* eval maps + \l* log
--                         maps in clojure/fennel/racket/scheme buffers
--                         (its spec); slimv: ,* SLIME maps for Common
--                         Lisp - GLOBAL once loaded, so the comma
--                         namespace belongs to slimv (its spec).
--                         parinfer-rust and rainbow-delimiters add no
--                         keys at all.
--   * Debugging         - F5 start/continue, S-F5 stop, F6 pause, F7 UI,
--                         F8 Rust debuggables, F9 breakpoint, F10/F11/
--                         S-F11 step over/into/out - global, defined in
--                         lua/hwangfu/dap.lua (bare `keys` triggers in the
--                         nvim-dap spec lazy-load the stack on first press)
-- ============================================================================

local M = {}

-- require("hwangfu.keymappings").setup()
function M.setup()
    require("hwangfu.keymappings.editor").setup()
    require("hwangfu.keymappings.movement").setup()
    require("hwangfu.keymappings.mouse").setup()
    require("hwangfu.keymappings.navigation").setup()
end

return M
