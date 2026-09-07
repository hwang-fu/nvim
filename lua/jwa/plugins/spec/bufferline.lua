-- A tab bar across the top listing every open buffer (bufferline.nvim).
--
-- The goal is the one every mainstream editor already meets: see at a glance
-- which files are open, and know where [b / ]b are about to take you
-- (2026-09-07, user request).
--
-- It does NOT keep a buffer list of its own. What it draws is Neovim's list
-- of listed buffers, so opening a file adds a tab and :bdelete removes one,
-- with nothing to keep in sync. The ORDER is the same story: upstream's
-- default `sort_by = "id"` is the buffer number, which is exactly the order
-- :bnext and :bprevious walk. Left-to-right on screen and forward with ]b are
-- the same direction, by default, without configuring anything.
--
-- That default is deliberately left alone. Setting sort_by to "directory",
-- "extension" or "insert_after_current" - or dragging a tab with
-- :BufferLineMoveNext - imposes an order Neovim's own :bnext cannot follow,
-- because :bnext is hardcoded to buffer numbers. The keymaps in
-- keymappings/navigation.lua call bufferline's cycle commands rather than
-- :bnext for exactly that reason: today the two behave identically, and if a
-- custom order is ever wanted, the keys keep following what the eye sees
-- instead of quietly disagreeing with it.
--
-- Loads eagerly (no event/ft/cmd trigger), like lualine: it is always-visible
-- chrome, and its commands have to exist before the first ]b.
return {
	"akinsho/bufferline.nvim",
	dependencies = {
		-- Per-filetype glyphs on each tab. Already in the tree for lualine,
		-- oil and render-markdown; named here so lazy knows the load order.
		-- The glyphs are Nerd Font private-use codepoints, so the TERMINAL
		-- font has to be a Nerd Font - the same requirement lualine's
		-- filetype component already carries.
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		-- Repaint the whole bar on the editor background (2026-09-07, user
		-- request). The scheme gives bufferline four or five slightly
		-- different darks - fill #1c1c1c, inactive tabs #0f1014, the selected
		-- one #292a35 - none of which is Normal's #000000, so the bar reads
		-- as a lighter band pasted above the buffer.
		--
		-- Done as a sweep rather than a list because there are 62
		-- BufferLine* groups and 60 of them carry a background: naming them
		-- would be a table nobody could keep correct across plugin updates.
		-- Every other attribute is preserved, so the tabs keep whatever
		-- foreground, bold and underline the scheme gave them - only the
		-- background is forced.
		--
		-- Read from the live Normal rather than a literal, so it follows the
		-- editor background instead of needing to be recomputed with it.
		-- Deferred through vim.schedule inside the ColorScheme handler
		-- because lua/jwa/colors.lua repaints Normal from its own
		-- ColorScheme autocmd; reading during the event would race it and
		-- could catch the scheme's background instead of ours.
		local function match_normal_background()
			local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
			if not normal.bg then
				return
			end
			for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
				if name:match("^BufferLine") and def.bg then
					def.bg = normal.bg
					-- Drop `default` before writing it back. bufferline
					-- registers the per-filetype icon highlights with
					-- default = true, and nvim_set_hl honours that flag on
					-- the way IN: a default definition does not overwrite an
					-- existing group, so echoing the table back unchanged is
					-- a silent no-op on exactly the groups that needed it.
					def.default = nil
					vim.api.nvim_set_hl(0, name, def)
				end
			end
		end

		require("bufferline").setup({
			options = {
				-- Error and warning counts per tab, from the language
				-- servers. Worth the space here: with several files open,
				-- this is what tells you a file you are not looking at has
				-- broken, which is otherwise invisible until you switch to
				-- it.
				diagnostics = "nvim_lsp",

				-- Keep the bar visible with a single file open. The editors
				-- this is modelled on do the same, and a bar that appears
				-- and disappears shifts every line on screen by one row.
				always_show_bufferline = true,

				-- Leave room for the oil sidebar (<C-t>, 35 columns, left)
				-- rather than drawing tabs above it. Without this the bar
				-- spans the full width and its left end sits over a pane
				-- that has nothing to do with buffers.
				offsets = {
					{
						filetype = "oil",
						text = "Files",
						highlight = "Directory",
						separator = true,
					},
				},
			},
		})

		match_normal_background()

		-- Re-swept on buffer events as well as on :colorscheme, because the
		-- group list is not fixed. bufferline creates the per-filetype icon
		-- highlights lazily - BufferLineDevIconClojure and its Selected twin
		-- appear the first time a Clojure buffer is drawn in the bar - so a
		-- sweep at setup catches only the filetypes already open, and every
		-- new one afterwards would arrive wearing the scheme's background.
		--
		-- Cheap enough for these events: a few hundred table reads, once per
		-- buffer shown, not per keystroke. Scheduled so it runs after
		-- bufferline has rendered and the new groups actually exist.
		vim.api.nvim_create_autocmd({ "ColorScheme", "BufAdd", "BufWinEnter" }, {
			group = vim.api.nvim_create_augroup("JwaBufferlineHl", { clear = true }),
			callback = function()
				vim.schedule(match_normal_background)
			end,
		})
	end,
}
