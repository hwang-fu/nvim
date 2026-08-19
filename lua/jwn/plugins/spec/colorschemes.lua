-- ============================================================================
-- Colorschemes (selected per-filetype by lua/jwn/colors.lua).
--
-- Only `dracula` below is actively set by colors.lua today; the rest are
-- kept installed for experimentation. The other theme colors.lua uses --
-- `256_noir` -- plus the currently-unused `green` and `minimo` live in
-- this config's own colors/ directory and need no plugin at all.
--
-- Note: nvim-lspconfig was previously listed alongside these. It is no
-- longer needed because we use the native vim.lsp.config() /
-- vim.lsp.enable() API in lua/jwn/lsp/, and every server file
-- supplies its own cmd, filetypes, and root_markers via
-- helpers.define_server.
--
-- Removed (2026-08), both dead upstream since 2022 and referenced nowhere:
--   * Yazeed1s/minimal.nvim -- an old comment here claimed it provided the
--     `minimo` theme; it actually provided `minimal` / `minimal-base16`.
--     `minimo` is the local colors/minimo.vim and survives the removal.
--   * cormacrelf/vim-colors-github
-- ============================================================================

return {
	"ellisonleao/gruvbox.nvim",
	"Mofiqul/dracula.nvim", -- active theme for colors.lua group (b)
	"folke/tokyonight.nvim", -- tokyonight family (night / storm / moon / day)
	"vague-theme/vague.nvim", -- moved from vague2k/vague.nvim (repo transferred)
}
