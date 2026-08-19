-- Haskell IDE wrapper over haskell-language-server (HLS).
--
-- Same author and configuration pattern as rustaceanvim
-- (mrcjkb), so the spec mirrors it: vim.g.haskell_tools is the
-- config table, set from the `init` hook below so it lands before
-- the plugin's filetype handler registers itself.
--
-- Surfaces HLS extensions and a Hoogle-aware editor layer as
-- `:Haskell <subcommand>` user commands:
--   * :Haskell hover           hover with Hoogle / open-docs /
--                              open-source / find-refs as clickable
--                              code actions (used as our K override
--                              in lua/jwn/lsp/servers/hls.lua).
--   * :Haskell hls evalAll     evaluate `-- >>> expr` doctest
--                              comments in-place; result written
--                              back into the buffer.
--   * :Haskell repl toggle     toggle a GHCi terminal scoped to
--                              the project (or [file] arg).
--   * :Haskell repl cword_type / cword_info
--                              GHCi :type / :info of the symbol
--                              under cursor.
--   * :Haskell projectFile     open cabal.project / stack.yaml.
--   * :Haskell definition      LSP go-to-def with Hoogle fallback.
--   * :Haskell log openHlsLog  direct access to the HLS log file.
--
-- Telescope extension is loaded in lua/jwn/telescope.lua via
-- pcall(telescope.load_extension, "ht"), enabling
-- `:Telescope ht package_files / package_grep / hoogle_signature`.
--
-- Pinned to major version 9; semver-major bumps require an
-- explicit change here. Like rustaceanvim, MUST NOT be lazy-
-- loaded -- the plugin manages its own filetype-based loading,
-- and layering lazy.nvim's lazy triggers on top breaks auto-attach.
--
-- IMPORTANT: hls is intentionally absent from the SERVERS table
-- in lua/jwn/lsp/init.lua. Calling helpers.define_server
-- there would race haskell-tools' own LSP setup (the README is
-- explicit about this conflict).
return {
	"mrcjkb/haskell-tools.nvim",
	version = "^9",
	lazy = false,
	init = function()
		require("jwn.lsp.servers.hls").setup()
	end,
}
