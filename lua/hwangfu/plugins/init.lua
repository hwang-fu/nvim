-- ============================================================================
-- Plugin manager entrypoint (lazy.nvim).
--
-- This module owns *how* plugins are installed; *which* plugins exist
-- lives in the per-plugin files next door. It does NOT configure editor
-- behavior - that lives in the other lua/hwangfu/* modules (init for
-- options, keymap for keybinds, lsp, completion, colors), each wired up
-- from the root init.lua.
--
-- STRUCTURE (per-plugin layout; migrated from one 1569-line plugins.lua
-- on 2026-08-15, one commit per plugin - see git log for the steps):
--   * lua/hwangfu/plugins/init.lua  - THIS file: bootstrap + setup().
--   * lua/hwangfu/plugins/spec/<name>.lua - one file per plugin (or per
--     inseparable group: colorschemes.lua, lisp.lua), returning its
--     lazy.nvim spec. Imported automatically via
--     { import = "hwangfu.plugins.spec" } below. Each plugin carries its
--     keymaps and documentation with it - the keys-live-with-their-
--     plugin convention survives the split.
--
-- Add a new plugin -> create lua/hwangfu/plugins/spec/<name>.lua
-- returning its spec, then restart Neovim (lazy installs missing plugins
-- automatically) or run `:Lazy sync`. Manage plugins interactively with
-- `:Lazy`. A spec file with no lazy-load trigger (event/ft/cmd/keys) and
-- no `lazy = true` loads eagerly at startup.
--
-- Migrated from packer.nvim (unmaintained since 2023). The packer ->
-- lazy.nvim spec translation, for reference when adding plugins:
--   use("owner/repo")           ->  "owner/repo"
--   use({ "owner/repo", ... })  ->  { "owner/repo", ... }
--   config = function() end     ->  config = function() end   (unchanged)
--   run = ...                   ->  build = ...
--   setup = function() end     ->  init  = function() end     (pre-load hook)
--   ft = { ... }                ->  ft = { ... }               (unchanged)
--
-- Not-a-plugin note (kept from the old inline table): comment toggling
-- is handled by Neovim's built-in gc / gcc / gbc operators (0.10+).
-- Comment.nvim was previously installed but is now redundant; the
-- visual-mode <C-l> map in lua/hwangfu/keymappings/editor.lua still works because it
-- remaps to `gc`, which resolves to the built-in.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- 1. Bootstrap lazy.nvim
-- ----------------------------------------------------------------------------

-- Auto-install lazy.nvim into ~/.local/share/nvim/lazy/lazy.nvim on first run,
-- so a fresh clone of this config just needs `nvim` once: lazy clones itself
-- here, then installs every plugin in the spec files automatically.
--
--   --filter=blob:none  partial clone (skip blob contents, fetch on demand) -
--                       lazy.nvim's recommended bootstrap; smaller and faster
--                       than a full clone.
--   --branch=stable     track lazy's stable release tag rather than HEAD.
--
-- vim.opt.rtp:prepend puts lazy on the runtimepath so require("lazy") resolves.
local function bootstrap_lazy()
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not (vim.uv or vim.loop).fs_stat(lazypath) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable",
			lazypath,
		})
	end
	vim.opt.rtp:prepend(lazypath)
end

-- ----------------------------------------------------------------------------
-- 2. Module entrypoint
-- ----------------------------------------------------------------------------

-- require("hwangfu.plugins").setup()
function M.setup()
	bootstrap_lazy()
	require("lazy").setup({
		spec = {
			-- Every module under lua/hwangfu/plugins/spec/ is imported
			-- automatically; each returns one plugin's spec (or a group).
			{ import = "hwangfu.plugins.spec" },
		},
	})
end

return M
