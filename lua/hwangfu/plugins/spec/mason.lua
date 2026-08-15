-- mason.nvim: in-editor package manager for external tooling binaries.
--
-- Scope in THIS config: debug-adapter binaries ONLY (currently codelldb,
-- pulled in by mason-nvim-dap's ensure_installed - see the nvim-dap spec
-- below). The LSP servers (rust-analyzer, gopls, HLS, ElixirLS, ...) are
-- deliberately NOT managed here: each comes from its own language toolchain
-- (rustup component, `go install`, ghcup, ...), which version-matches the
-- server to the compiler far better than mason's generic prebuilt binaries.
--
-- Declared as its own spec (not merely a dependency of mason-nvim-dap) so
-- the :Mason / :MasonInstall / :MasonUpdate commands are available on
-- demand - e.g. `:MasonInstall codelldb` to pre-warm the adapter download
-- instead of waiting for the first debug session to fetch it. `cmd`
-- lazy-loads mason the first time any of those commands run; lazy.nvim
-- merges this spec with the dependency reference below, so codelldb still
-- auto-installs on first debug even if you never invoke :Mason yourself.
--
-- opts = {} is enough: handing lazy.nvim any opts table makes it call
-- require("mason").setup(opts) on load.
return {
	"mason-org/mason.nvim",
	cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall", "MasonLog" },
	opts = {},
}
