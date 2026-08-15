-- ============================================================================
-- vim-surround: add / change / delete surrounding pairs (quotes, brackets,
-- tags). Plugin-default keymaps: ys{motion}{char} add, cs{old}{new}
-- change, ds{char} delete, visual S{char} wrap.
--
-- PILOT FILE of the per-plugin spec migration (2026-08-15): each module
-- in lua/hwangfu/plugins/spec/ returns one plugin's lazy.nvim spec (or a
-- small group of inseparable specs) and is imported automatically by the
-- { import = "hwangfu.plugins.spec" } entry in ../init.lua. Plugins
-- migrate here from ../init.lua's inline table one at a time, each move
-- its own commit.
-- ============================================================================

return {
	"tpope/vim-surround",
}
