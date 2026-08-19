-- ============================================================================
-- glance.nvim: VSCode-style "peek" for LSP locations.
--
-- :Glance references / definitions / implementations / type_definitions
-- opens an embedded panel AT THE CURSOR - a list of locations beside a
-- live preview - so call sites can be inspected and visited without
-- leaving the code being read. This is the third consumption mode for
-- LSP locations alongside telescope pickers (find one, transient) and
-- the quickfix list (process all, persistent).
--
-- Command-driven; the one keymap pointing here is grr (peek references),
-- bound buffer-locally in lsp/helpers.lua. Inside an open panel glance
-- has its own keys: <CR> jump, o jump, <Tab>/<S-Tab> next/previous
-- location, q or <Esc> close, <C-q> send the locations to quickfix.
--
-- Readability tuning (2026-08-19, user report: the panel fused with the
-- buffer behind it into one unreadable block):
--   * border: horizontal rules above and below the panel (the plugin
--     supports horizontal borders only). Since parent and preview share
--     a colorscheme, these lines are what marks where the panel begins
--     and ends.
--   * theme.mode = "darken": the default "auto" derives the panel
--     shades from the Normal background, and against this config's
--     dark-green it produced near-identical colors - no visual
--     separation at all. "darken" pushes the panel backgrounds
--     decisively darker than the surrounding buffer.
--   * preview: line numbers on, wrap OFF - long signature lines wrapping
--     inside the small preview were half the visual noise in the report.
--     Horizontal scroll (zl / zh) covers the rare need to see the tail.
-- ============================================================================

return {
	"dnlhc/glance.nvim",
	cmd = { "Glance" },
	config = function()
		require("glance").setup({
			border = {
				enable = true,
				top_char = "-",
				bottom_char = "-",
			},
			theme = {
				enable = true,
				mode = "darken",
			},
			preview_win_opts = {
				cursorline = true,
				number = true,
				wrap = false,
			},
		})
	end,
}
