-- ============================================================================
-- Colorscheme: one global theme for every file.
--
-- dracula-soft (the muted-palette variant shipped by Mofiqul/dracula.nvim),
-- set once at startup, PURE - no highlight overrides on top (2026-08-23,
-- user request: "setting it right now as default ... pure dracula-soft").
-- Fresh customizations will be layered here as the user specifies them.
--
-- HISTORY - this module was a per-filetype colorscheme switcher until
-- 2026-08-23: web/markup files (html/htmlangular/css/scss) got 256_noir
-- with black sign column + red/grey diagnostic accents, and everything
-- else got dracula overlaid with the user's signature tweaks - Normal
-- guibg=#022800 (the dark-green background), LspInlayHint on the same
-- green, @keyword guifg=#0078cd (blue keywords), @type.builtin gui=none.
-- All retired together with the switch to pure dracula-soft; resurrect
-- any of it from git history if the new round of customization wants a
-- starting point. (An even earlier markdown-only group used the local
-- colors/green.vim, which still lives in colors/ alongside 256_noir and
-- friends - everything there and in plugins/spec/colorschemes.lua stays
-- available to :colorscheme for experiments.)
--
-- If overrides ever return, remember the ordering rule that shaped the
-- old code: `:colorscheme X` runs `:highlight clear` and redefines
-- everything, so overrides only stick when set AFTER the colorscheme
-- call (for a startup call like this one, an accompanying ColorScheme
-- autocmd is the robust place - see the PhantomEol relink in
-- lua/jwa/init.lua for the pattern).
-- ============================================================================

local M = {}

-- --------------------------------------------------------------------------
-- Customization no. 1 (2026-08-23, user request): the editor background
-- matches the kitty terminal background, so the nvim pane blends into
-- the terminal instead of drawing its own darker box.
--
-- The color is COPIED from kitty's config (~/.config/kitty/modules/
-- general.conf: `background #32324e`) - if kitty's background ever
-- changes, update the hex here to match. (The self-syncing alternative
-- is `Normal guibg=NONE`, true transparency; not chosen, a pinned copy
-- keeps nvim identical even if kitty gains background effects.)
--
-- vim.cmd.highlight MERGES attributes into the existing group -
-- dracula-soft's Normal foreground survives; only the background is
-- repainted. nvim_set_hl would REPLACE the whole group and wipe fg.
-- Applied once after the startup :colorscheme below, and re-applied by
-- autocmd so a manual :colorscheme experiment keeps the terminal-
-- matched background too.
-- --------------------------------------------------------------------------
local function apply_overrides()
    vim.cmd.highlight("Normal guibg=#32324e")
end

-- require("jwa.colors").setup()
function M.setup()
    vim.cmd.colorscheme("dracula-soft")
    apply_overrides()
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("JwaColorOverrides", { clear = true }),
        pattern = "*",
        callback = apply_overrides,
    })
end

return M
