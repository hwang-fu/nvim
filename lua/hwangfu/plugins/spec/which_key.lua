-- ============================================================================
-- Keymap discovery popup (which-key.nvim): pause mid-keypress and a
-- popup lists every continuation with its desc= text. The living
-- counterpart of docs/keymappings/ and telescope's <leader>fk:
-- nearly every map in this config already carries a desc, so the
-- popup arrives fully labeled with zero per-map work here.
-- Buffer-local maps (gitsigns hunks, oil keys, ocaml.nvim's
-- backslash maps, the \r utop toggle) appear only in buffers where
-- they exist - which-key reads live mappings, not a static registry.
--
-- setup({}) keeps every default (preset "classic", ~200ms delay).
-- The wk.add() below registers NO mappings: entries carrying only
-- `group` are labels, so the popup shows "+git hunks" for <leader>h
-- instead of a bare "+prefix".
--
-- ASCII note: the popup draws with which-key's own runtime glyphs
-- (borders, separators, nerd-font icons) - the same standing
-- exception as lualine / render-markdown: plugin runtime output may
-- be fancy, the config files stay ASCII.
-- ============================================================================

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		local wk = require("which-key")
		wk.setup({})
		wk.add({
			{ "<leader>b", group = "buffers" },
			-- (<leader>c group label removed 2026-08-15: the crates
			-- keymaps became :Crates commands; the namespace is free.)
			{ "<leader>f", group = "find / telescope" },
			{ "<leader>g", group = "git ui" },
			{ "<leader>h", group = "git hunks" },
			{ "<leader>m", group = "markdown / preview" },
			{ "<localleader>", group = "filetype tools" },
		})
	end,
}
