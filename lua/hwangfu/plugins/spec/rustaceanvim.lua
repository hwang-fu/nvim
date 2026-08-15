-- Rust IDE wrapper over rust-analyzer.
--
-- rustaceanvim owns the rust-analyzer LSP client end-to-end and
-- surfaces rust-analyzer's custom (non-standard-LSP) protocol
-- extensions as :RustLsp <verb> commands: expandMacro, explainError,
-- openDocs, parentModule, runnables, debuggables, syntaxTree,
-- viewHir, viewMir, moveItem, joinLines, ssr, ...
--
-- Configuration lives in lua/hwangfu/lsp/servers/rust_analyzer.lua
-- (server settings, on_attach, notify filter, :RustFormat). We call
-- that module's setup() from the `init` hook below so vim.g.
-- rustaceanvim is populated BEFORE the plugin loads -- the plugin
-- reads vim.g.rustaceanvim at filetype-handler registration time,
-- and lazy.nvim's `init` is the only hook guaranteed to fire before
-- the plugin's own code.
--
-- Pinned to major version 9 per the plugin's own install guidance;
-- semver-major bumps require an explicit change here.
--
-- DO NOT add `lazy = true`, `event = ...`, `ft = ...`, or `cmd = ...`:
-- rustaceanvim's README is explicit that it manages its own lazy
-- loading via Neovim's filetype plugin layout (lua/plugin/), and
-- layering lazy.nvim's lazy-load triggers on top of that breaks
-- the auto-attach to rust buffers.
--
-- IMPORTANT: rust_analyzer is intentionally absent from the SERVERS
-- table in lua/hwangfu/lsp/init.lua. Calling helpers.define_server
-- there would race rustaceanvim's own vim.lsp.config / vim.lsp.enable
-- and either start a duplicate client or clobber the runnables and
-- code-action features.
return {
	"mrcjkb/rustaceanvim",
	version = "^9",
	lazy = false,
	init = function()
		require("hwangfu.lsp.servers.rust_analyzer").setup()
	end,
}
