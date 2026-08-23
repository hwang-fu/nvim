-- ============================================================================
-- Global keymappings: entrypoint + master index.
--
-- Goal: make Neovim feel closer to mainstream editor conventions for the
-- handful of universal shortcuts (Ctrl-S disk-aware save, Ctrl-A select all,
-- Ctrl-arrow word navigation, Alt-arrow line moving) WITHOUT touching
-- Vim's core motions.
--
-- STRUCTURE (split from the single lua/jwa/keymap.lua on 2026-08-15,
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
--                       Window resize     Alt+h/j/k/l
--   * mouse.lua       - Ctrl+LeftClick smart jump: LSP definition;
--                       references when clicked at the definition
--                       itself; quiet ctags fallback in non-LSP
--                       buffers (back: <C-o>). Ctrl+RightClick opens
--                       an empty live-grep prompt scoped to the OPEN
--                       buffers (ripgrep; reads disk, not unsaved edits)
--   * navigation.lua  - Ctrl-T oil sidebar toggle (see
--                       lua/jwa/explorer.lua); ]b / [b buffer
--                       cycle, <leader>bd close buffer
--
-- NOT in this folder (buffer-local maps defined where their plugin is
-- configured, in lua/jwa/plugins/spec/<plugin>.lua):
--   * Git hunks         - ]h / [h, <leader>h*, ih
--                         (gitsigns.nvim spec; see its "Keymap quick
--                         reference" comment for the full table)
--   * Oil buffer keys   - <CR> open (also on the always-visible ../ first
--                         row, NERDTree-style), - / .. up, g. hidden,
--                         dd + :w ops (oil.nvim spec; see its "Keymap
--                         quick reference" comment for the full table)
--   * Git UI            - <leader>gg lazygit float (lua/jwa/git.lua);
--                         <leader>gd / gh / gH diffview (its spec's keys)
--   * Markdown/preview  - commands only, no keys (:LivePreview,
--                         :MarkdownRender; specs of live-preview.nvim
--                         and render-markdown.nvim)
--   * Textobjects       - af/if, ac/ic, aa/ia (visual + operator-
--                         pending); ]f/[f, ]F/[F, ]]/[[ motions
--                         (nvim-treesitter-textobjects spec; ]c/[c stay
--                         with gitsigns hunks)
--   * Flash jumps       - s labeled jump, S treesitter select
--                         (flash.nvim spec; shadows the cl / cc
--                         synonyms)
--   * Keymap discovery  - which-key popup on any pending prefix; leader
--                         groups labeled in its spec (which-key.nvim)
--   * OCaml editing     - <localleader>* in OCaml buffers, <localleader>
--                         being backslash: \c construct/fill hole, \n / \p
--                         next / prev hole, \s switch .ml/.mli, \i infer
--                         interface, \t type enclosing, \j jump
--                         (ocaml.nvim spec; see its command reference
--                         comment for the full table)
--   * OCaml REPL        - <localleader>r toggle the project-scoped utop
--                         float (lua/jwa/repl.lua)
--   * Lisp eval         - conjure: <localleader>e* eval maps + \l* log
--                         maps in clojure/fennel/racket/scheme buffers
--                         (its spec); slimv: ,* SLIME maps for Common
--                         Lisp - GLOBAL once loaded, so the comma
--                         namespace belongs to slimv (its spec).
--                         parinfer-rust and rainbow-delimiters add no
--                         keys at all.
--   * Phantom EOF line  - a / i / o / O gain conditional behavior ON the
--                         reachable trailing `~` line only (a / i append
--                         at the end of the last content line, o / O
--                         open a new content line at EOF); defined with
--                         the phantom machinery in lua/jwa/init.lua,
--                         documented in docs/keymappings/misc.md.
-- ============================================================================

local M = {}

-- require("jwa.keymappings").setup()
function M.setup()
    require("jwa.keymappings.editor").setup()
    require("jwa.keymappings.movement").setup()
    require("jwa.keymappings.mouse").setup()
    require("jwa.keymappings.navigation").setup()
end

return M
