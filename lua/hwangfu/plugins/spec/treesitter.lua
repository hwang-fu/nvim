-- Treesitter: syntax-aware highlighting and parsing.
--
-- build = ":TSUpdate" keeps the compiled parsers current on install/update.
--
-- The runtimepath line below is load-bearing. On nvim-treesitter's `main`
-- branch the query files (highlights / injections / folds) ship under the
-- plugin's own `runtime/queries/` directory, which is NOT on the
-- runtimepath by default. With no queries on the runtimepath,
-- vim.treesitter.start() attaches a highlighter that paints nothing, and
-- every buffer silently falls back to Neovim's slow regex `syntax` engine.
-- Prepending `<plugin>/runtime` exposes the bundled queries so treesitter
-- highlighting actually runs. `plugin.dir` is the install path lazy.nvim
-- passes into the config function.
return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function(plugin)
		vim.opt.runtimepath:prepend(plugin.dir .. "/runtime")

		require("nvim-treesitter").setup()

		-- Start treesitter highlighting on every buffer whose filetype
		-- has a parser available (pcall: filetypes without one are
		-- skipped silently).
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "*",
			callback = function()
				pcall(vim.treesitter.start)
			end,
		})
	end,
}
