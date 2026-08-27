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

-- require("jwa.colors").setup()
function M.setup()
    vim.cmd.colorscheme("dracula-soft")
end

return M
