-- ============================================================================
-- lazydev.nvim: lua_ls integration for editing Neovim Lua.
--
-- Solves the plugin-typing gap (2026-08-21, Lua round): lua_ls's static
-- workspace.library only carried the Neovim runtime, so plugin modules
-- resolved half-typed - hover on the result of require("telescope")
-- showed `load_extension: unknown`, meaning no completion, docs, or
-- type checking for any plugin API. lazydev watches the require() calls
-- in open buffers and feeds each required plugin's source to lua_ls on
-- demand (via workspace/didChangeConfiguration), so a file's actual
-- dependencies are fully typed without indexing every installed plugin
-- up front.
--
-- It also owns the Neovim runtime typings per workspace, replacing the
-- manual workspace.library entries that lua_ls.lua used to carry - and
-- unlike the static list, it works no matter where the workspace root
-- lands, which retires the old "Undefined global `vim` when opened
-- outside ~/.config/nvim" caveat.
--
-- Completion side: lua/jwa/completion.lua registers lazydev's blink.cmp
-- source, which completes module names inside require("...") strings.
--
-- ft = "lua": loads with the first Lua buffer, nothing at startup.
-- ============================================================================

return {
	"folke/lazydev.nvim",
	ft = "lua",
	opts = {
		library = {
			-- luv (vim.uv) types, pulled in when a file mentions vim.uv.
			-- Same "${3rd}" pointer lua_ls.lua used to pass statically.
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		},
	},
}
