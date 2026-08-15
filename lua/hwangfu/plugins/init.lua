-- ============================================================================
-- Plugin manager + plugin declarations (lazy.nvim).
--
-- This module owns *which* plugins exist and *how* they are installed. It does
-- NOT configure editor behavior - that lives in the other lua/hwangfu/* modules
-- (init for options, keymap for keybinds, lsp, cmp, colors), each wired up from
-- the root init.lua.
--
-- STRUCTURE (migration in progress, started 2026-08-15): this file is
-- becoming the thin entrypoint of a per-plugin layout.
--   * lua/hwangfu/plugins/init.lua  - THIS file (was lua/hwangfu/
--     plugins.lua): bootstrap + setup() + the not-yet-migrated inline
--     spec table below.
--   * lua/hwangfu/plugins/spec/<name>.lua - one file per plugin (or per
--     inseparable group), returning its lazy.nvim spec. Imported
--     automatically via { import = "hwangfu.plugins.spec" } in setup().
--     Each plugin carries its keymaps and documentation with it.
-- Plugins move from the inline table to spec/ files one at a time, one
-- commit per move; when the table empties, it and its entry in setup()
-- get deleted.
--
-- Responsibilities, in order:
--   1. Bootstrap lazy.nvim (clone it on first run).
--   2. Declare the (remaining inline) plugin set as a lazy.nvim spec table.
--   3. Hand spec-dir import + inline table to require("lazy").setup(...).
--
-- Add a new plugin -> create lua/hwangfu/plugins/spec/<name>.lua returning
-- its spec, then restart Neovim (lazy installs missing plugins
-- automatically) or run `:Lazy sync`. Manage plugins interactively with
-- `:Lazy`.
--
-- Migrated from packer.nvim (unmaintained since 2023). The packer -> lazy.nvim
-- spec translation, for reference when adding plugins:
--   use("owner/repo")           ->  "owner/repo"
--   use({ "owner/repo", ... })  ->  { "owner/repo", ... }
--   config = function() end     ->  config = function() end   (unchanged)
--   run = ...                   ->  build = ...
--   setup = function() end      ->  init  = function() end     (pre-load hook)
--   ft = { ... }                ->  ft = { ... }               (unchanged)
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- 1. Bootstrap lazy.nvim
-- ----------------------------------------------------------------------------

-- Auto-install lazy.nvim into ~/.local/share/nvim/lazy/lazy.nvim on first run,
-- so a fresh clone of this config just needs `nvim` once: lazy clones itself
-- here, then installs every plugin in the spec below automatically.
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
-- 2. Plugin declarations
--
-- Each entry is a lazy.nvim spec. A plugin with no lazy-load trigger
-- (event/ft/cmd/keys) and no `lazy = true` loads eagerly at startup - the same
-- timing packer used by default, so this migration changes no load behavior.
-- ----------------------------------------------------------------------------
local plugins = {
	-- (vim-surround migrated to spec/surround.lua, 2026-08-15.)

	-- (nvim-treesitter migrated to spec/treesitter.lua, 2026-08-15.)

	-- (textobjects migrated to spec/textobjects.lua, 2026-08-15.)

	-- (which-key.nvim migrated to spec/which_key.lua, 2026-08-15.)

	-- (lualine migrated to spec/lualine.lua, 2026-08-15.)

	-- (gitsigns migrated to spec/gitsigns.lua, 2026-08-15.)

	-- (diffview migrated to spec/diffview.lua, 2026-08-15.)

	-- (Colorschemes migrated to spec/colorschemes.lua, 2026-08-15.)

	-- (live-preview migrated to spec/live_preview.lua, 2026-08-15.)

	-- (render-markdown migrated to spec/render_markdown.lua, 2026-08-15.)

	-- Comment toggling: handled by Neovim's built-in gc / gcc / gbc operators
	-- (added in Neovim 0.10). Comment.nvim was previously here but is now
	-- redundant. The visual-mode <C-l> map in lua/hwangfu/keymap.lua continues
	-- to work because it remaps to `gc`, which now resolves to the built-in.

	-- (blink.cmp migrated to spec/blink.lua, 2026-08-15.)

	-- (oil migrated to spec/oil.lua, 2026-08-15.)

	-- (telescope migrated to spec/telescope.lua, 2026-08-15.)

	-- (elixir-tools migrated to spec/elixir_tools.lua, 2026-08-15.)

	-- (haskell-tools migrated to spec/haskell_tools.lua, 2026-08-15.)

	-- (rustaceanvim migrated to spec/rustaceanvim.lua, 2026-08-15.)

	-- (ocaml.nvim migrated to spec/ocaml.lua, 2026-08-15.)

	-- (Lisp cluster - parinfer, rainbow-delimiters, conjure, slimv -
	-- migrated to spec/lisp.lua, 2026-08-15.)

	-- (mason migrated to spec/mason.lua, 2026-08-15.)

	-- (nvim-dap stack migrated to spec/dap.lua, 2026-08-15.)

	-- (crates migrated to spec/crates.lua, 2026-08-15.)

	-- (arm-syntax-vim migrated to spec/arm_syntax.lua, fhir.nvim to
	-- spec/fhir.lua, 2026-08-15.)
}

-- ----------------------------------------------------------------------------
-- 3. Module entrypoint
-- ----------------------------------------------------------------------------

-- require("hwangfu.plugins").setup()
function M.setup()
	bootstrap_lazy()
	require("lazy").setup({
		spec = {
			-- Per-plugin files: every module under
			-- lua/hwangfu/plugins/spec/ is imported automatically.
			{ import = "hwangfu.plugins.spec" },
			-- Not-yet-migrated inline specs (lazy flattens nested
			-- lists). Shrinks as the migration proceeds; delete this
			-- entry together with the table when it empties.
			plugins,
		},
	})
end

return M
