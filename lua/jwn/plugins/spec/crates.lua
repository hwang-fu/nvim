-- crates.nvim: crates.io dependency intelligence for Cargo.toml.
--
-- Inline latest-version virtual text, crate / version / feature completion,
-- hover, and update / upgrade code actions - all scoped to Cargo.toml. It
-- is complementary to taplo (the general TOML language server): taplo does
-- schema + formatting, crates.nvim does crates.io-specific version data.
--
-- Integration is via crates.nvim's IN-PROCESS language server, NOT its
-- (deprecated, slated-for-removal) nvim-cmp source. With that, completion
-- rides blink.cmp's built-in `lsp` source and hover / code actions ride
-- taplo's existing K / <leader>ca bindings on Cargo.toml, so neither
-- lua/jwn/completion.lua nor the LSP keymaps need changing. See the
-- long note in lua/jwn/crates.lua for the full rationale and the
-- :Crates command reference.
--
-- tag = "stable" follows the plugin's release-channel guidance (the repo
-- ships a moving `stable` tag); `event = "BufRead Cargo.toml"` keeps it off
-- the startup path until a manifest is actually opened. All behavior lives
-- in lua/jwn/crates.lua, invoked from `config` (same lazy-from-spec
-- pattern as rust_analyzer.lua).
return {
	"saecki/crates.nvim",
	tag = "stable",
	event = { "BufRead Cargo.toml" },
	config = function()
		require("jwn.crates").setup()
	end,
}
