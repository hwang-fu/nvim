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
	end,
}
