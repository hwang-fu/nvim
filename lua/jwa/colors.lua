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
-- Palette variables (2026-08-27, user request): the three colors this
-- module owns, extracted so each is tuned in exactly one place. The
-- customization blocks below tell the story of how each value was
-- chosen; THESE are the knobs to turn.
-- --------------------------------------------------------------------------
local palette = {
	-- Editor background. Plain black, chosen for concentration
	-- (2026-08-29) - NOT derived from anything else, so nothing has to
	-- be kept in sync with it. See customization no. 1 below for what
	-- it replaced.
	background = "#000000",
	-- The kitty terminal's own background, copied by hand from
	-- ~/.config/kitty/modules/general.conf. UNUSED on purpose - it is
	-- kept because it was the editor background from 2026-08-23 to
	-- 2026-08-29, and it is the value to put back into `background`
	-- above if the nvim pane should blend into the terminal again
	-- instead of drawing its own black rectangle. Not dead weight to
	-- delete: retyping a hand-copied colour is how the two drift apart.
	kitty_background = "#32324e",
	-- Comment text: the scheme's hint gray nudged toward white, so
	-- comments outrank inlay hints in brightness.
	comment_fg = "#a8a8a8",
	-- Inlay hint text: the scheme's original comment gray; the
	-- underline (set below) is what keeps hints looking like hints.
	inlay_hint_fg = "#70747f",
}

-- --------------------------------------------------------------------------
-- Customization no. 1: the editor background is repainted, overriding
-- whatever the colorscheme ships.
--
-- It was kitty's own background (#32324e, copied by hand from
-- ~/.config/kitty/modules/general.conf) from 2026-08-23, so the nvim pane
-- blended into the terminal instead of drawing its own box. Replaced by
-- plain black on 2026-08-29 at the user's request, for concentration.
--
-- That trade is worth stating plainly: the pane no longer matches the
-- terminal around it, so nvim now draws a black rectangle inside a
-- #32324e kitty window. Matching them again means changing kitty, not
-- this file.
--
-- Nothing derives from this value, and nothing needs to follow it when it
-- changes. The indent-guide colour in lua/jwa/init.lua is a settled
-- literal of its own, deliberately independent of whatever is behind it.
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
-- against the kitty-matched #32324e in force at the time, which made
-- dense hint lines read as tiling. The redefinition below drops the box entirely and answers the
-- user's "without background but bold" spec: scheme's hint gray
-- (#969696), bold, transparent. nvim_set_hl REPLACES the whole group,
-- which is exactly right here (the bg must go away, not merge).
-- The dim-comment-gray alternative (#70747f, unstyled) was offered and
-- may return depending on how this trial reads.
-- SETTLED (2026-08-27) after a trial tour - bold, underline,
-- underdotted, underdashed, 50% and 70% opacity mixes: no background,
-- a straight underline (what keeps hints recognizably hints), and -
-- final twist, customization no. 4 - the FG COLORS OF HINTS AND
-- COMMENTS SWAPPED, because the user wants comments to outrank hints
-- in brightness: hints wear the scheme's old comment gray (#70747f),
-- comments take the brighter register and are then nudged further
-- toward white (#a8a8a8, from the scheme's #969696 hint gray via
-- "slightly brighter towards white"). Treesitter/semantic comment
-- groups follow automatically - they link to Comment.
-- (Opacity lesson kept for posterity: the `blend` attribute only
-- works in floating windows - inline virtual text needs opacity baked
-- in as a channel mix against the background.)
-- --------------------------------------------------------------------------
local function style_inlay_hints()
	vim.api.nvim_set_hl(0, "LspInlayHint", { fg = palette.inlay_hint_fg, underline = true })
	vim.api.nvim_set_hl(0, "Comment", { fg = palette.comment_fg })
end

local function apply_overrides()
	vim.cmd.highlight("Normal guibg=" .. palette.background)
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
