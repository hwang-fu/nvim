-- ============================================================================
-- blink.cmp setup: completion engine.
--
-- Migrated from nvim-cmp (2026-08); this module was lua/jwa/cmp.lua.
-- One plugin now covers what took five (nvim-cmp + cmp-nvim-lsp /
-- cmp-buffer / cmp-path / cmp-cmdline) plus the LuaSnip pair - see the
-- removal note in lua/jwa/plugins/spec/blink.lua.
--
-- What's wired up:
--   * Engine          - blink.cmp with its prebuilt Rust fuzzy matcher
--                       (Lua fallback if the binary is unavailable).
--   * UI behavior     - PARITY with the old nvim-cmp setup: popup on every
--                       keystroke, first item preselected but not inserted
--                       (the old completeopt "noinsert"), Enter confirms,
--                       documentation window auto-shows after 200ms.
--   * Snippets        - no snippet engine plugin. LSP snippet items
--                       (rust-analyzer's fn / match, etc.) expand through
--                       Neovim's built-in vim.snippet; jump between
--                       placeholders with <Tab> / <S-Tab>.
--   * Sources         - lsp + path primary; buffer words only appear when
--                       the LSP returns nothing (blink's default fallback
--                       chain - the same shape as the old two-group
--                       nvim-cmp setup).
--   * Cmdline         - NEW (2026-08, deliberate): popup completion for
--                       ":" commands and "/" searches via blink's built-in
--                       cmdline mode. The old cmp-cmdline plugin was
--                       installed but never wired up, so ":" completion
--                       had always been the native wildmenu until now.
--                       Blink's cmdline defaults apply: <Tab> shows and
--                       cycles, arrows navigate, <CR> accepts and runs.
--
-- ----------------------------------------------------------------------------
-- Keybinding reference: the coding helpers and how to drive them.
-- (<leader> is the Space key.)
--
-- COMPLETION MENU - mapped in this file, in the `keymap` table below.
-- The popup appears by itself as you type; a documentation window for the
-- highlighted item shows automatically beside it (after 200ms).
--   <Down> / <Up>   move down / up through the suggestion list
--   <C-n> / <C-p>   same, without leaving the home row
--   <C-Space>       open the menu on demand (if it is not already showing)
--   <CR>            accept the highlighted suggestion
--   <C-f> / <C-b>   scroll the documentation window down / up
--   <Esc>           menu open: dismiss it and STAY in insert mode;
--                   menu closed: leave insert mode as usual
--
-- LSP CODE HELPERS - jump around and act on code, active once a language
-- server has attached (rust-analyzer, lua_ls, ...).
--
-- Mapped in lua/jwa/lsp/init.lua:
--   K               hover: docs for the symbol under the cursor. Press K a
--                   second time to jump into that popup, then scroll it and
--                   press q to close.
--   <C-k>           signature help: parameter hints. Works in insert mode,
--                   so this is the one to call inside a function call's ().
--   gd / gD         go to definition / declaration
--   gt / gi         go to type definition / implementation
--   <leader>rn      rename the symbol everywhere
--   <leader>ca      code action: offered quick-fixes and refactors
--   gl              show the full diagnostic for the current line
--
-- Provided by Neovim 0.11+ as built-in defaults (this config does not map
-- them; Neovim already does):
--   grr             list every reference to the symbol
--   [d / ]d         jump to the previous / next diagnostic
--
-- Getting back after a jump: gd / grr can land you in a different file.
-- <C-o> jumps back to where you came from, <C-i> jumps forward again, and
-- <C-^> toggles to the previously-edited buffer. See the Buffers section
-- of keymappings/navigation.lua
-- section for more on moving between files.
-- ============================================================================

local M = {}

-- require("jwa.completion").setup()
function M.setup()
	require("blink.cmp").setup({
		-- Parity mappings - each entry is a command list tried in order;
		-- "fallback" passes the key through when the menu is not showing.
		keymap = {
			preset = "none",

			-- Move through the menu: the arrow keys, or <C-n>/<C-p> to
			-- keep your hands on the home row.
			["<Down>"] = { "select_next", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },

			-- Open the completion menu on demand.
			["<C-space>"] = { "show", "fallback" },

			-- ENTER to confirm (first item counts - it is preselected).
			["<CR>"] = { "accept", "fallback" },

			-- Scroll the documentation window of the highlighted item.
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },

			-- Esc: close the menu but STAY in insert mode (the old
			-- nvim-cmp abort behavior). With no menu showing, fallback
			-- makes Esc leave insert mode as usual.
			["<Esc>"] = { "cancel", "fallback" },
		},

		completion = {
			list = {
				-- preselect + no auto_insert = the old completeopt
				-- "menu,menuone,noinsert" plus confirm-first-item.
				selection = { preselect = true, auto_insert = false },
			},
			documentation = {
				-- nvim-cmp showed docs automatically; blink needs the
				-- opt-in. 200ms keeps the fast menu from flickering
				-- docs on every keystroke (0 = instant, 500 = blink's
				-- own default delay).
				auto_show = true,
				auto_show_delay_ms = 200,
			},
		},

		sources = {
			-- No "snippets" source: LuaSnip is gone and no snippet
			-- files exist; LSP snippet ITEMS still arrive via "lsp".
			-- blink's default source config already lists "buffer" as
			-- a fallback of "lsp" (buffer words only when the LSP has
			-- nothing), which is the old two-group behavior.
			--
			-- "lazydev": module-name completion inside require("...")
			-- strings in Lua buffers (see plugins/spec/lazydev.lua).
			-- The provider module is a no-op outside Lua files; the
			-- score_offset ranks its exact module paths above the
			-- generic LSP items when both fire.
			default = { "lazydev", "lsp", "path", "buffer" },
			providers = {
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 100,
				},
			},
		},

		-- Popup completion for ":" and "/" (blink built-in; keymaps are
		-- blink's cmdline defaults - Tab shows/cycles, arrows navigate).
		cmdline = {
			enabled = true,
		},
	})
end

return M
