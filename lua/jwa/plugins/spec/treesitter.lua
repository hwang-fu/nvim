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

		-- --- Fresh-machine parser provisioning (2026-08-17) -------------
		-- The main branch has no `ensure_installed` option; without this
		-- block a fresh clone has only Neovim's bundled parsers (lua, c,
		-- markdown, vimdoc, ...) and every other language silently falls
		-- back to regex highlighting - taking the textobjects and
		-- rainbow-delimiters layers down with it - until someone hand-runs
		-- :TSInstall per language. This closes that gap: compare the list
		-- below against get_installed() and asynchronously install only
		-- what is missing. On a provisioned machine the diff is empty and
		-- this costs one table scan.
		--
		-- The list = the languages this config actually supports (the
		-- SERVERS table in lsp/init.lua, the language plugins, the lisp
		-- cluster) plus nvim's own core parsers kept current. To add one:
		-- append the name; valid names come from
		-- require("nvim-treesitter").get_available(). All 38 below were
		-- validated against get_available() on 2026-08-17.
		--
		-- Parsers install asynchronously; buffers opened before a parser
		-- lands need :e (or a restart) to pick up highlighting - the
		-- FileType autocmd below only fires on buffer load.
		local ensure = {
			-- core (bundled with nvim, kept updatable)
			"lua", "vim", "vimdoc", "query", "c", "cpp",
			"markdown", "markdown_inline", "regex", "diff",
			-- primary languages
			"rust", "ocaml", "ocaml_interface",
			"clojure", "fennel", "scheme", "racket", "commonlisp",
			"elixir", "heex", "erlang", "haskell", "go", "python",
			-- web / config / the rest of SERVERS
			"javascript", "typescript", "vue", "html", "css",
			"json", "yaml", "toml", "bash", "dockerfile",
			"proto", "make", "perl", "fortran",
			"java", "cmake",
		}
		local installed = {}
		for _, lang in ipairs(require("nvim-treesitter").get_installed()) do
			installed[lang] = true
		end
		local missing = {}
		for _, lang in ipairs(ensure) do
			if not installed[lang] then
				missing[#missing + 1] = lang
			end
		end
		if #missing > 0 then
			vim.notify(
				"treesitter: installing " .. #missing .. " missing parsers in the background",
				vim.log.levels.INFO
			)
			require("nvim-treesitter").install(missing)
		end

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
