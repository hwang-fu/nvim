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
-- Command-driven, no keymaps, by the same choice as crates.nvim and the
-- markdown tools. Inside an open panel glance has its own keys:
-- <CR> jump, o jump, <Tab>/<S-Tab> next/previous location, q or <Esc>
-- close, <C-q> send the locations to quickfix.
-- ============================================================================

return {
	"dnlhc/glance.nvim",
	cmd = { "Glance" },
	config = function()
		require("glance").setup({})
	end,
}
