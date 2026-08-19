-- ============================================================================
-- glance.nvim: VSCode-style "peek" for LSP locations.
--
-- :Glance references / definitions / implementations / type_definitions
-- opens an embedded panel AT THE CURSOR - a list of locations beside a
-- live preview - so call sites can be inspected and visited without
-- leaving the code being read. This is the third consumption mode for
-- LSP locations alongside telescope pickers (find one, transient) and
-- the quickfix list (process all, persistent).
--
-- Command-driven; the one keymap pointing here is grr (peek references),
-- bound buffer-locally in lsp/helpers.lua. Inside an open panel glance
-- has its own keys: <CR> jump, o jump, <Tab>/<S-Tab> next/previous
-- location, q or <Esc> close, <C-q> send the locations to quickfix.
--
-- Readability tuning (2026-08-19, user report: the panel fused with the
-- buffer behind it into one unreadable block):
--   * border: horizontal rules above and below the panel (the plugin
--     supports horizontal borders only). Since parent and preview share
--     a colorscheme, these lines are what marks where the panel begins
--     and ends.
--   * theme.mode = "darken": the default "auto" derives the panel
--     shades from the Normal background, and against this config's
--     dark-green it produced near-identical colors - no visual
--     separation at all. "darken" pushes the panel backgrounds
--     decisively darker than the surrounding buffer.
--   * preview: line numbers on, wrap OFF - long signature lines wrapping
--     inside the small preview were half the visual noise in the report.
--     Horizontal scroll (zl / zh) covers the rare need to see the tail.
-- ============================================================================

return {
	"dnlhc/glance.nvim",
	cmd = { "Glance" },
	config = function()
		-- --- <C-w>w window cycling through the panel (2026-08-19) --------
		-- Neovim's CTRL-W w cycle NEVER includes floating windows - even
		-- focusable ones (verified: from the list it drops to the main
		-- buffer and cycles there forever; the mouse works because
		-- focusability governs clicks, not the cycle). Glance's own
		-- answer is <leader>l to hop between its two windows, but the
		-- user's muscle memory is <C-w>w. So while a glance panel is
		-- open, <C-w>w walks the full triangle deterministically:
		-- main -> list -> preview -> main. Everywhere else (and whenever
		-- glance is not even loaded) it falls through to the native
		-- wincmd w.
		-- Glance's two windows are told apart from unrelated floats (LSP
		-- hover popups, ...) by its zindex, 45 - the plugin default, kept
		-- in the setup below. The list is the one with the Glance
		-- filetype; the other 45-float is the preview.
		local function glance_wins()
			local list, preview
			for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				local cfg = vim.api.nvim_win_get_config(w)
				if cfg.relative ~= "" and cfg.zindex == 45 then
					if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "Glance" then
						list = w
					else
						preview = w
					end
				end
			end
			return list, preview
		end
		local function cycle_with_glance()
			local glance = package.loaded["glance"]
			if not (glance and glance.is_open()) then
				vim.cmd("wincmd w")
				return
			end
			local list, preview = glance_wins()
			local cur = vim.api.nvim_get_current_win()
			if cur == list and preview then
				vim.api.nvim_set_current_win(preview)
			elseif cur == preview then
				-- Back to the main buffer: the first non-floating window.
				-- (Native wincmd w from a float lands on an arbitrary
				-- neighbor - from the preview it bounced back to the
				-- list, verified - so the target is picked explicitly.)
				for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
					if vim.api.nvim_win_get_config(w).relative == "" then
						vim.api.nvim_set_current_win(w)
						return
					end
				end
			elseif list then
				vim.api.nvim_set_current_win(list)
			else
				vim.cmd("wincmd w")
			end
		end
		vim.keymap.set("n", "<C-w>w", cycle_with_glance, { desc = "Next window (cycles through the glance panel)" })
		vim.keymap.set("n", "<C-w><C-w>", cycle_with_glance, { desc = "Next window (cycles through the glance panel)" })

		require("glance").setup({
			border = {
				enable = true,
				top_char = "-",
				bottom_char = "-",
			},
			theme = {
				enable = true,
				mode = "darken",
			},
			preview_win_opts = {
				cursorline = true,
				number = true,
				wrap = false,
			},
		})
	end,
}
