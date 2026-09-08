-- C# / Blazor: Microsoft's Roslyn language server, driven by roslyn.nvim
-- (2026-09-08, user request).
--
-- This is the same server VS Code's C# extension runs, not a community
-- reimplementation - which is the reason to take a plugin here at all. The
-- rest of this config hand-writes a small table per server in
-- lua/jwa/lsp/servers/ and lets vim.lsp.enable start it; Roslyn cannot be
-- driven that way. It negotiates a solution or project target before it will
-- answer anything, speaks a pipe protocol rather than plain stdio, and needs
-- a restart when the target changes. roslyn.nvim exists to do that
-- bookkeeping.
--
-- Razor and Blazor come with it. They used to need a SECOND server (rzls) and
-- a second plugin, version-matched to this one by hand; upstream's README now
-- opens by telling anyone with that setup to remove it, because the Roslyn
-- server has handled .razor and .cshtml itself since 5.8.0-1.26262.10.
-- Anything older silently has no Razor support at all, which is the one
-- version-sensitive fact in this whole arrangement.
--
-- The server is NOT bundled. It is a .NET global tool:
--
--   dotnet tool install -g roslyn-language-server --prerelease \
--     --source https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json
--
-- installed to ~/.dotnet/tools, which section 2 of ~/.bashrc appends to PATH
-- (Neovim inherits it from the shell). The Azure feed is upstream's
-- recommendation over nuget.org, which lags. ~/.local/bin/freshup keeps it
-- current alongside the other user-level installs.
--
-- Filetypes need no work: Neovim already maps .cs to `cs` and both .razor and
-- .cshtml to `razor` out of the box (runtime/lua/vim/filetype.lua).
--
-- Server settings are NOT here. Upstream directs them through the ordinary
-- vim.lsp.config("roslyn", ...) interface, so they live with every other
-- server's in lua/jwa/lsp/servers/roslyn.lua and read the same as the rest.
--
-- `:Roslyn target` picks between solutions when a repository has several; the
-- current one is in vim.g.roslyn_nvim_selected_solution.
return {
	"seblyng/roslyn.nvim",
	ft = { "cs", "razor" },
	-- Same hook the rustaceanvim, elixir-tools and haskell-tools specs use for
	-- their servers: register the config before the plugin that starts the
	-- client loads, and stay out of the SERVERS loop in lsp/init.lua, which
	-- would call vim.lsp.enable and race it.
	init = function()
		require("jwa.lsp.servers.roslyn").setup()
	end,
	opts = {},
}
