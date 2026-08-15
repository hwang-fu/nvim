-- ============================================================================
-- flash.nvim: labeled jumps - search with your eyes, not with repeats.
--
-- Press s (normal / visual / operator-pending), type a couple of
-- characters, and every match on screen grows a one-letter label;
-- pressing the label jumps there. S does the same over treesitter
-- nodes: labels appear on the syntax constructs around the cursor
-- (expression, call, function, block) and pick one to select it.
--
-- Keymap trade-off, upstream's own default and accepted here
-- (2026-08-15): `s` shadows the built-in synonym for `cl` (substitute
-- character) and `S` the synonym for `cc` (change line). Both have
-- those spellings; nothing is lost but a duplicate.
--
-- Keys are documented in docs/keymappings/search.md alongside the rest
-- of the search story.
-- ============================================================================

return {
	"folke/flash.nvim",
	keys = {
		{
			"s",
			mode = { "n", "x", "o" },
			function()
				require("flash").jump()
			end,
			desc = "Flash: labeled jump",
		},
		{
			"S",
			mode = { "n", "x", "o" },
			function()
				require("flash").treesitter()
			end,
			desc = "Flash: treesitter select",
		},
	},
	opts = {},
}
