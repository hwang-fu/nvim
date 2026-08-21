-- Elixir IDE wrapper over ElixirLS (and optionally Next LS).
--
-- elixir-tools.nvim owns the Elixir LSP client end-to-end and
-- adds Elixir-specific user commands that the standard LSP
-- doesn't reach:
--   * :Mix <task>          run mix tasks with completion
--                          (deps.get, ecto.migrate, test, ...)
--   * :ElixirFromPipe      rewrite `foo |> bar(x)` -> `bar(foo, x)`
--   * :ElixirToPipe        rewrite `bar(foo, x)` -> `foo |> bar(x)`
--   * :ElixirExpandMacro   expand a macro in a floating split
--                          (the Elixir analogue of rustaceanvim's
--                          :RustLsp expandMacro)
--   * :ElixirRestart       restart the Elixir LSP client
--   * :ElixirOutputPanel   open the LSP log panel
--   * Projectionist: :Esource / :Etest / :Etask / :Econtroller /
--                    :Eview / :Eliveview / :Echannel / :Ecomponent
--                    / ... -- Phoenix-aware file scaffolding;
--                    detect-on-demand inside a Mix project.
--
-- Configuration lives in lua/jwa/lsp/servers/elixirls.lua
-- (LSP backend choice, ElixirLS settings, on_attach plumbing).
-- We call that module's setup() from the `config` hook below, so
-- require("elixir").setup({...}) runs AFTER elixir-tools is on the
-- runtimepath (the plugin's require() resolves to its own lua/
-- only after lazy.nvim adds it).
--
-- Lazy-loading: this plugin DOES lazy-load (via the `event` field
-- below), unlike rustaceanvim which forbids it. The elixir-tools
-- README's own install snippet uses `event = { "BufReadPre",
-- "BufNewFile" }` so the plugin only loads when a buffer is first
-- touched, which is correct because elixir-tools attaches its own
-- autocmds on first elixir-buffer encounter.
--
-- IMPORTANT: elixirls is intentionally absent from the SERVERS
-- table in lua/jwa/lsp/init.lua. Calling helpers.define_server
-- there would race elixir-tools' own LSP setup and either start a
-- duplicate client or clobber its commands.
return {
	"elixir-tools/elixir-tools.nvim",
	version = "*",
	event = {
		"BufReadPre",
		"BufNewFile",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("jwa.lsp.servers.elixirls").setup()
	end,
}
