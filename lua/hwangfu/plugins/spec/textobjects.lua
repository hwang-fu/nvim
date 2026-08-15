-- Treesitter textobjects: syntax-aware text objects and motions.
--
-- Runs the `main` branch to MATCH the nvim-treesitter spec
-- (spec/treesitter.lua), which is also on main - the two rewrites
-- moved API in lockstep and mixing branches breaks both. Configuration on main is manual
-- keymaps around the plugin's select / move modules (the old
-- master-branch declarative `textobjects = {...}` table inside
-- nvim-treesitter's setup no longer exists on this branch).
--
-- Queries ship per-language inside the plugin
-- (queries/<lang>/textobjects.scm); every language in daily use here
-- is covered (rust, ocaml, lua, python, go, haskell, elixir, c/cpp,
-- ...) with one notable absence: NO erlang queries upstream
-- (checked 2026-08) - these maps quietly no-op in erlang buffers.
--
-- Keymap quick reference (select maps work in visual +
-- operator-pending; moves in normal + visual + operator-pending):
--   af / if   a function / inner function (vaf selects the whole
--             definition, dif deletes just the body, ...)
--   ac / ic   a class / inner class ("class" = whatever the
--             language's queries capture as @class: struct / impl /
--             module in class-less languages)
--   aa / ia   a parameter / inner parameter ("a" = argument; the
--             outer variant includes the separating comma)
--   ]f / [f   jump to next / previous function START
--   ]F / [F   jump to next / previous function END
--   ]] / [[   jump to next / previous class START (overrides Vim's
--             built-in section motions, which do nothing useful in
--             most code; the plugin README's own convention)
--
-- ]c / [c were deliberately NOT used for class motions: gitsigns
-- owns them for hunk navigation (buffer-local in git repos).
--
-- The swap module (exchange two parameters) is available but
-- unmapped; wire <leader>sn / <leader>sp over
-- require("nvim-treesitter-textobjects.swap") if ever wanted.
--
-- init hook: vim.g.no_plugin_maps disables Neovim's BUILT-IN
-- ftplugin mappings (the python / rust ftplugins define buffer-local
-- ]] / [[ / ]m variants that would shadow the treesitter-aware maps
-- below in exactly those buffers). Upstream's README recommends
-- this. Cost: every other built-in ftplugin map vanishes too - none
-- are in known use in this config; switch to per-filetype
-- vim.g.no_<ft>_maps for a narrower disable if that ever changes.
return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	init = function()
		vim.g.no_plugin_maps = true
	end,
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = {
				-- Jump forward to the nearest textobject when the
				-- cursor is not inside one (targets.vim behavior):
				-- daf above the first function deletes THAT
				-- function instead of failing.
				lookahead = true,
				selection_modes = {
					-- Functions and classes are line-structured;
					-- selecting them linewise (V) beats charwise
					-- selections starting mid-line. Parameters
					-- stay charwise (the default).
					["@function.outer"] = "V",
					["@class.outer"] = "V",
				},
			},
			move = {
				-- Motions land in the jumplist, so <C-o> undoes a
				-- ]f overshoot like any other jump.
				set_jumps = true,
			},
		})

		local select = require("nvim-treesitter-textobjects.select")
		local move = require("nvim-treesitter-textobjects.move")

		-- No-target feedback (2026-08-15, user request): a miss warns and
		-- cancels back to normal mode instead of silently doing nothing.
		--
		-- Select objects pre-check with the SAME lookup the plugin uses
		-- internally (shared.textobject_at_point, honoring the lookahead
		-- setting); on nil the pending operator / visual mode is
		-- cancelled with a fed <Esc>. The successful path then runs the
		-- stock select, which repeats the cheap lookup - the same
		-- deliberate double-query trade as the mouse smart jump.
		--
		-- Motions detect a miss by the cursor not moving; no <Esc>
		-- needed there (a failed motion already leaves modes intact).
		local function sel(lhs, capture, desc, label)
			vim.keymap.set({ "x", "o" }, lhs, function()
				local cfg = require("nvim-treesitter-textobjects.config").select
				local found = require("nvim-treesitter-textobjects.shared").textobject_at_point(
					capture,
					"textobjects",
					0,
					nil,
					{ lookahead = cfg.lookahead, lookbehind = cfg.lookbehind }
				)
				if not found then
					vim.notify("No " .. label .. " found here", vim.log.levels.WARN)
					local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
					vim.api.nvim_feedkeys(esc, "n", false)
					return
				end
				select.select_textobject(capture, "textobjects")
			end, { silent = true, desc = desc })
		end
		local function mov(lhs, fn, capture, desc, label)
			vim.keymap.set({ "n", "x", "o" }, lhs, function()
				local before = vim.api.nvim_win_get_cursor(0)
				move[fn](capture, "textobjects")
				local after = vim.api.nvim_win_get_cursor(0)
				if before[1] == after[1] and before[2] == after[2] then
					vim.notify("No " .. label, vim.log.levels.WARN)
				end
			end, { silent = true, desc = desc })
		end

		sel("af", "@function.outer", "a function", "function")
		sel("if", "@function.inner", "inner function", "function")
		sel("ac", "@class.outer", "a class", "class")
		sel("ic", "@class.inner", "inner class", "class")
		sel("aa", "@parameter.outer", "a parameter", "parameter")
		sel("ia", "@parameter.inner", "inner parameter", "parameter")

		mov("]f", "goto_next_start", "@function.outer", "Next function start", "next function")
		mov("[f", "goto_previous_start", "@function.outer", "Previous function start", "previous function")
		mov("]F", "goto_next_end", "@function.outer", "Next function end", "next function end")
		mov("[F", "goto_previous_end", "@function.outer", "Previous function end", "previous function end")
		mov("]]", "goto_next_start", "@class.outer", "Next class start", "next class")
		mov("[[", "goto_previous_start", "@class.outer", "Previous class start", "previous class")
	end,
}
