-- ============================================================================
-- Neovim entrypoint.
--
-- Loaded by Neovim on startup. Two responsibilities, in order:
--   1. Set <leader> early - before any plugin or keymap code runs.
--   2. Wire up the config modules under lua/jwa/*:
--        plugins   - installs lazy.nvim and the plugin set
--        completion - completion engine (blink.cmp)
--        lsp       - language servers, format-on-save, linters
--        telescope - fuzzy finder (files, grep, buffers, ...)
--        keymappings - global keybindings (per-domain folder: editor /
--                    mouse / navigation, indexed in its init.lua)
--        git       - lazygit floating-terminal keymap
--        repl      - utop floating REPL for OCaml buffers
--        explorer  - oil sidebar toggle (required on demand by keymap /
--                    the oil spec; no setup() call here)
--        colors    - per-filetype colorscheme switching
--        (init)    - editor options and general autocmds
--
-- Add a new plugin -> add a spec file under lua/jwa/plugins/spec/, then restart
-- Neovim (lazy.nvim installs it automatically) or run `:Lazy sync`. Add new
-- behavior -> put it in one of the other lua/jwa/ modules.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Leader key
--
-- Must be set before everything else. `<leader>` inside a mapping is resolved
-- to the value of mapleader *at the moment the mapping is created* - and some
-- plugin code creates mappings during startup (lazy.nvim registers each
-- plugin's `init` hooks and `keys` triggers while the plugins module below
-- loads; live-preview's <leader>m* keys are defined that way). Setting
-- mapleader here guarantees those mappings see the intended leader.
--
-- It is also set in lua/jwa/init.lua's options block, alongside the rest
-- of the editor options. Assigning the same value twice is harmless, and
-- keeping it there preserves that file as the place to look for UX options.
-- ----------------------------------------------------------------------------
vim.g.mapleader = " "

-- <localleader> for filetype-scoped plugin maps (ocaml.nvim's construct /
-- hole navigation / switch-interface keys are the first user). Backslash IS
-- Neovim's fallback when maplocalleader is unset; assigning it explicitly
-- documents that the default is a choice, not an accident. Set here for the
-- same created-at-definition-time reason as mapleader above.
vim.g.maplocalleader = "\\"

-- ----------------------------------------------------------------------------
-- 2. Module wire-up
--
-- Order matters somewhat:
--   * plugins first - lazy.nvim must install and load the plugins before the
--     modules that configure them run (completion needs blink.cmp on the
--     runtimepath, lsp's make_capabilities() pcalls require("blink.cmp")).
--   * completion before lsp because make_capabilities() in lsp/helpers.lua
--     pcalls require("blink.cmp"). If that fails (blink not yet loaded),
--     servers come up without blink-augmented completion bits.
--   * lsp before colors so server-attached buffers exist when colors.lua's
--     filetype autocmds run on first FileType event.
--   * keymap and the catch-all jwa setup last (no LSP dependency).
-- ----------------------------------------------------------------------------
require("jwa.plugins").setup()

require("jwa.completion").setup()
require("jwa.lsp").setup()
require("jwa.telescope").setup()

require("jwa.keymappings").setup()
require("jwa.git").setup()
require("jwa.repl").setup()
require("jwa.colors").setup()
require("jwa").setup()
