-- ============================================================================
-- Per-filetype colorscheme switcher.
--
-- Strategy: rather than picking a single global theme, swap colorscheme on
-- FileType so that each language family gets the look that suits it best.
-- Two groups today:
--
--   (a) Web/markup files (html/htmlangular/css/scss) -> 256_noir
--       (high-contrast dark theme), with a black sign column and red/grey
--       diagnostic accents. (An older version of this comment also listed
--       json/yaml here - those have always been in group (b)'s pattern.)
--
--   (b) Programming languages, structured config and markdown -> dracula
--       (Mofiqul/dracula.nvim), with a dark-green Normal background and a
--       few keyword / inlay-hint tweaks layered on top.
--
-- (Until 2026-08 markdown was a third group (c) with its own look: the
-- local colors/green.vim plus a black ColorColumn. It now rides group (b)
-- so prose renders the same as code, per user preference; green.vim stays
-- in colors/ if that ever reverts.)
--
-- Every colorscheme listed in plugins/spec/colorschemes.lua is fair game here,
-- as is anything in this config's colors/ directory (256_noir, minimo, green,
-- ...); swap in gruvbox / tokyonight / vague etc. if you want to experiment.
--
-- IMPORTANT: highlight overrides only stick if they're set AFTER the
-- colorscheme call, because `:colorscheme X` runs `:highlight clear` and
-- redefines everything from scratch. Both autocmds below follow that
-- order: colorscheme first, highlight tweaks after.
-- ============================================================================

local M = {}

-- require("jwa.colors").setup()
function M.setup()
	-- (a) Web / markup files -> 256_noir + diagnostic palette tweaks.
	vim.api.nvim_create_autocmd("FileType", {
		pattern = {
			"html",
			"htmlangular",
			"css",
			"scss",
		},
		callback = function()
			vim.cmd.colorscheme("256_noir")
			vim.cmd.highlight("SignColumn guibg=#000000")
			vim.cmd.highlight("DiagnosticHint guifg=grey")
			vim.cmd.highlight("DiagnosticError guifg=red")
			vim.cmd.highlight("DiagnosticSignWarn guifg=grey")
			vim.cmd.highlight("DiagnosticSignError guifg=red")
			vim.cmd.highlight("DiagnosticUnderlineError guisp=red")
		end,
	})

	-- (b) Programming languages, prose, structured config -> dracula.
	-- The pattern list spans nearly every language we touch; anything missing
	-- here falls through to whatever colorscheme was last set (typically the
	-- one set globally on startup, or the (a) theme if the previous buffer
	-- was web/markup).
	vim.api.nvim_create_autocmd("FileType", {
		pattern = {
			"lisp",
			"scheme",
			"clojure",
			"fennel", -- joined (b) 2026-08-14 alongside the fennel-ls wiring
			"haskell",
			"lua",
			"go",
			"rust",
			"pascal",
			"py",
			"python",
			"javascript",
			"typescript",
			"sh",
			"bash",
			"c",
			"cpp",
			"proto",
			"zig",
			"perl",
			"dune",
			"ocaml",
			"elixir",
			"erlang",
			"toml",
			"yml",
			"yaml",
			"json",
			"jsonc",
			"vim",
			"make",

			"json",
			"yml",
			"yaml",

			"fortran",
			"vhdl",

			"text",
			"markdown", -- joined (b) 2026-08; had its own green-theme group before

			"oil",

			"cabal",

			"gitignore",
			"gitcommit",
		},
		callback = function()
			-- NOTE: `:colorscheme X` runs `:highlight clear` and redefines
			-- everything from scratch. If you want highlight overrides,
			-- set them AFTER this line.
			vim.cmd.colorscheme("dracula")
			-- vim.cmd.highlight("Normal guibg=#32324e")
			vim.cmd.highlight("Normal guibg=#022800")
			vim.cmd.highlight("LspInlayHint guibg=#022800 guifg=#6272a4")
			vim.cmd.highlight("@keyword guifg=#0078cd")
			vim.cmd.highlight("@type.builtin gui=none")
		end,
	})
end

return M
