-- ============================================================================
-- flash.nvim: labeled jumps - search with your eyes, not with repeats.
--
-- Press s (normal / visual / operator-pending), type a couple of
-- characters, and every match on screen grows a one-letter label;
-- pressing the label jumps there. Enter always takes the first match,
-- so labels only matter when the wanted match is not the first one.
--
-- The treesitter select mode (S) was deliberately REMOVED (2026-08-15,
-- user request) - do not re-add it. S is the built-in synonym for cc
-- (change line) again; structural selection stays with the textobjects
-- (vaf / vac / vaa, spec/textobjects.lua).
--
-- Keymap trade-off, upstream's own default and accepted here
-- (2026-08-15): `s` shadows the built-in synonym for `cl` (substitute
-- character). That spelling still works; nothing is lost but a
-- duplicate.
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
	},
	opts = {},
}
