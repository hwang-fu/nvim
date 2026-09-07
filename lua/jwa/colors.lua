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
	-- Floating-window border. The scheme paints it near-white, the same
	-- colour as the text, which is what makes a thin line read as a heavy
	-- frame. Dimmed until it is an edge rather than a feature.
	float_border_fg = "#5b5e70",
	-- Background of fenced code blocks inside rendered markdown, which
	-- in practice means the code samples in every LSP hover popup.
	-- Wanted: clearly a block against the float's own #292a35, while
	-- staying dark enough for the near-white float text.
	code_block_bg = "#3a3c4c",
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

-- --------------------------------------------------------------------------
-- Customization no. 5 (2026-08-29, user request): the 'colorcolumn' stripe
-- is painted like ordinary text, which makes it invisible.
--
-- Done as a LINK rather than by copying the background value. A copy would
-- have to be revisited every time the background changes, and the failure
-- mode of forgetting is silent - a stripe in the old colour, still there,
-- looking deliberate. A link cannot go stale: whatever Normal becomes,
-- from this palette or from a different colorscheme, ColorColumn is that.
--
-- The option itself is untouched. Nothing in this config sets
-- 'colorcolumn'; in a stock Neovim only the `man` ftplugin does, so the
-- stripe is rare to begin with - this decides how it looks when something
-- does ask for it, rather than suppressing the request.
-- --------------------------------------------------------------------------
local function hide_color_column()
	vim.api.nvim_set_hl(0, "ColorColumn", { link = "Normal" })
end

-- --------------------------------------------------------------------------
-- Customization no. 6 (2026-09-06): give rendered code blocks a background
-- of their own, instead of borrowing ColorColumn's.
--
-- render-markdown.nvim defines RenderMarkdownCode as a link to ColorColumn
-- (its core/colors.lua). That is a reasonable default - until customization
-- no. 5 above made ColorColumn invisible on purpose, at which point every
-- code sample inside every LSP hover popup was painted the same black as
-- the editor, and hover text started bleeding into the buffer behind it
-- with no visible edge. The two groups were only ever the same by accident;
-- this separates them.
--
-- Safe against ordering: render-markdown installs its links with
-- `default = true`, which never overwrites an explicit definition. Whether
-- its ColorScheme handler runs before or after apply_overrides, the
-- explicit value below is the one that survives.
--
-- The general lesson, written down because it cost a regression: a
-- highlight group is a shared namespace. Before repurposing a standard one,
-- grep the installed plugins for it - the option it is named after is not
-- the only thing that reads it.
-- --------------------------------------------------------------------------
local function style_code_blocks()
	vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = palette.code_block_bg })
end

-- --------------------------------------------------------------------------
-- Customization no. 7 (2026-09-06, user request): a thinner-looking float
-- border.
--
-- There is no thinner border STYLE to switch to. Neovim offers single and
-- rounded (both the light box-drawing set), bold, double, solid and shadow
-- ('winborder' in options.txt) - rounded is already the lightest stroke
-- available, so weight has to come off the colour instead.
--
-- The scheme gives FloatBorder the same near-white as the float's text,
-- which is why one light line reads as a frame around everything. Dimming
-- it keeps the edge legible - the point of having it at all is telling
-- popup from buffer - without competing with the content inside.
--
-- The border keeps NO background of its own, so the corners sit on the
-- editor background rather than the float's. Giving it bg = NormalFloat's
-- would fuse the frame into the popup body; not done, because the ring of
-- editor background is part of what separates the two.
-- --------------------------------------------------------------------------
local function style_float_border()
	vim.api.nvim_set_hl(0, "FloatBorder", { fg = palette.float_border_fg })
end

-- --------------------------------------------------------------------------
-- Customization no. 8 (2026-09-07, user request): the sign column shares the
-- editor background.
--
-- The scheme gives SignColumn its own #292a35, which against a black Normal
-- draws a permanent lighter stripe down the left edge - visible on every
-- window, whether or not any sign is in it. Linked rather than copied, for
-- the reason given on ColorColumn above: a copy would have to be revisited
-- every time the background moves, and forgetting is silent.
--
-- Checked before repurposing this group, which is the habit customization
-- no. 6 was paid for. Three installed plugins reference SignColumn:
-- render-markdown links its own Sign highlight to it and therefore inherits
-- this, which is what we want; glance and diffview both remap SignColumn to
-- private groups through winhighlight inside their own windows, so neither
-- sees the change at all. diffview's own table already sets SignColumn to
-- Normal, which is some comfort that this is the conventional answer.
-- --------------------------------------------------------------------------
local function blend_sign_column()
	vim.api.nvim_set_hl(0, "SignColumn", { link = "Normal" })
end

local function apply_overrides()
	vim.cmd.highlight("Normal guibg=" .. palette.background)
	strip_code_italics()
	style_inlay_hints()
	hide_color_column()
	style_code_blocks()
	style_float_border()
	blend_sign_column()
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
