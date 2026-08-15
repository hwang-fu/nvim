-- nvim-dap: Debug Adapter Protocol client - the debugging counterpart to
-- the LSP client. Like LSP it speaks a JSON protocol to a separate adapter
-- process; UNLIKE LSP it does NOT attach on file open. nvim-dap sits fully
-- idle until a debug session is explicitly started, so this whole stack is
-- lazy and costs nothing at startup or when opening a buffer.
--
-- Lazy-loading: the `keys` below are bare trigger keys (no action). The
-- first press loads the plugin - which runs `config`, installing the real
-- F-key mappings in lua/hwangfu/dap.lua - then lazy.nvim re-feeds the
-- keystroke so the now-live mapping fires. rustaceanvim's :RustLsp debug /
-- debuggables also load nvim-dap transparently: they call require("dap"),
-- and lazy.nvim hooks require() for managed plugins, so the stack loads on
-- demand there too. Hence no `ft` / `event` triggers are needed.
--
-- Dependencies (all loaded alongside nvim-dap on first debug):
--   * nvim-dap-ui (+ nvim-nio)   the scopes / stack / breakpoints / watches
--                                / REPL panel. Auto-opens on session start
--                                and closes on exit (listeners in dap.lua).
--   * nvim-dap-virtual-text      inline variable values rendered next to the
--                                code during a session.
--   * mason-nvim-dap (+ mason)   bridges mason <-> nvim-dap. Used ONLY for
--                                ensure_installed = { "codelldb" } so a
--                                fresh clone self-provisions the adapter;
--                                rustaceanvim still OWNS the Rust adapter
--                                (it auto-detects mason's codelldb), so
--                                mason-nvim-dap's automatic adapter handlers
--                                are left off in dap.lua.
--
-- All DAP behavior (signs, dap-ui, virtual-text, mason-nvim-dap, keymaps)
-- lives in lua/hwangfu/dap.lua, invoked from `config` below. This mirrors
-- how rust_analyzer.lua is invoked from rustaceanvim's `init` hook rather
-- than from init.lua: the module is wired from its plugin spec, not the
-- top-level module list, precisely so it stays lazy.
return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"theHamsta/nvim-dap-virtual-text",
		{
			"jay-babu/mason-nvim-dap.nvim",
			dependencies = { "mason-org/mason.nvim" },
		},
	},
	keys = {
		"<F5>",
		"<S-F5>",
		"<F6>",
		"<F7>",
		"<F8>",
		"<F9>",
		"<S-F9>",
		"<F10>",
		"<F11>",
		"<S-F11>",
	},
	config = function()
		require("hwangfu.dap").setup()
	end,
}
