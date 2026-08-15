-- ============================================================================
-- Completion engine (blink.cmp): fuzzy completion with a prebuilt Rust
-- matcher, replacing the whole nvim-cmp stack (2026-08).
--
-- Removed (2026-08), all superseded by this one spec:
--   * hrsh7th/nvim-cmp       the engine (maintenance mode upstream)
--   * hrsh7th/cmp-nvim-lsp   -> blink's built-in `lsp` source; the
--                            capabilities half now comes from
--                            blink.get_lsp_capabilities() in
--                            lua/hwangfu/lsp/helpers.lua
--   * hrsh7th/cmp-buffer     -> built-in `buffer` source
--   * hrsh7th/cmp-path       -> built-in `path` source
--   * hrsh7th/cmp-cmdline    -> built-in cmdline completion. NOTE: the
--                            cmp-cmdline plugin was installed but never
--                            wired up (no cmp.setup.cmdline call ever
--                            existed), so blink's cmdline popup is the
--                            first time ":" completion actually left
--                            the native wildmenu.
--   * L3MON4D3/LuaSnip + saadparwaiz1/cmp_luasnip
--                            nvim-cmp required a snippet engine; blink
--                            does not - LSP snippet items expand via
--                            Neovim's built-in vim.snippet. No custom
--                            snippets were ever defined. (Re-add later
--                            via blink's snippets.preset = "luasnip"
--                            if that changes.)
--
-- version = "1.*" pins to stable releases so lazy.nvim downloads the
-- prebuilt Rust fuzzy-matcher binary for that release tag (no cargo or
-- nightly toolchain needed). If the download fails, blink's default
-- fuzzy.implementation = "prefer_rust_with_warning" falls back to the
-- Lua matcher and says so.
--
-- Behavior config lives in lua/hwangfu/completion.lua, called from the
-- root init.lua (plugins -> completion -> lsp order), the same wiring
-- the old nvim-cmp module had.
-- ============================================================================

return {
	"saghen/blink.cmp",
	version = "1.*",
}
