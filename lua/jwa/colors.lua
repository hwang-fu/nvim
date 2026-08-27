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
-- --------------------------------------------------------------------------
-- Customization no. 2 (2026-08-23, user request): no italics in code.
--
-- dracula-soft ships 18 italic groups (surveyed live). The italics that
-- annoy are the CODE ones - @type.builtin, Special, SpecialComment,
-- Todo, italic URLs - while markup EMPHASIS is explicitly tolerable
-- ("if it is markdown or certain files it is tolerable"). So the strip
-- below removes the italic attribute from every highlight group EXCEPT
-- those whose name declares emphasis semantics: anything containing
-- "italic" or "emphasis" (@markup.italic, markdownItalic, htmlItalic,
-- @markup.emphasis, ...) plus markdownBlockquote. Colors are untouched;
-- only the slant goes.
--
-- Scope note: this runs at colorscheme time, so groups that a LAZILY
-- loaded plugin defines later (render-markdown's own groups, for
-- example) are not swept - acceptable, since those live in the
-- markdown/UI domain the user tolerates. Re-runs on ColorScheme like
-- the background pin, so scheme experiments stay italic-free too.
-- --------------------------------------------------------------------------
local function strip_code_italics()
    for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
        if def.italic then
            local lname = name:lower()
            local emphasis = lname:find("italic", 1, true)
                or lname:find("emphasis", 1, true)
                or name == "markdownBlockquote"
            if not emphasis then
                def.italic = nil
                if def.cterm then
                    def.cterm.italic = nil
                end
                vim.api.nvim_set_hl(0, name, def)
            end
        end
    end
end

-- --------------------------------------------------------------------------
-- Customization no. 3 (2026-08-27, user request, FIRST-LOOK TRIAL): inlay
-- hints without a background box, in bold.
--
-- dracula-soft ships LspInlayHint with its own bg (#2f3146) - invisible
-- against the scheme's native background but a visible darker chip
-- against our pinned kitty #32324e, which made dense hint lines read as
-- tiling. The redefinition below drops the box entirely and answers the
-- user's "without background but bold" spec: scheme's hint gray
-- (#969696), bold, transparent. nvim_set_hl REPLACES the whole group,
-- which is exactly right here (the bg must go away, not merge).
-- The dim-comment-gray alternative (#70747f, unstyled) was offered and
-- may return depending on how this trial reads.
-- Trial iterations (all 2026-08-27): bold -> underline -> underdotted
-- -> underdashed -> underdashed at 50% -> plain at 70% (rejected: too
-- similar to comments) -> CURRENT: underline at 50% opacity, whose
-- line keeps hints distinguishable from comment text at a glance.
--
-- Opacity note: the `blend` highlight attribute only applies in
-- floating windows - inline virtual text ignores it - so the opacity
-- is baked in arithmetically instead: #646472 is the 50/50 channel mix
-- of the hint gray #969696 over the pinned editor background #32324e.
-- If the background pin ever changes, recompute this mix.
-- --------------------------------------------------------------------------
local function style_inlay_hints()
    vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#646472", underline = true })
end

local function apply_overrides()
    vim.cmd.highlight("Normal guibg=#32324e")
    strip_code_italics()
    style_inlay_hints()
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
