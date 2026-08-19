-- Git change indicators + hunk actions (gitsigns.nvim).
--
-- One of three git layers: gitsigns edits hunks IN the buffer; the
-- <leader>g* namespace holds the repo-level UI (lazygit float in
-- lua/jwn/git.lua, plus the diffview.nvim spec in spec/diffview.lua, formerly below this
-- one).
--
-- Runs an async `git diff` for every attached buffer and keeps it
-- updated as you edit (debounced, no save needed). Three things come
-- out of that:
--   1. Sign-column markers on every added / changed / deleted line.
--   2. Hunk operations: jump between hunks, preview a hunk, stage or
--      reset a single hunk, whole-buffer stage / reset, diff splits,
--      line blame. Exposed as the buffer-local keymaps defined in
--      on_attach below (only active in git-tracked buffers; in any
--      other buffer those keys keep their defaults).
--   3. Per-buffer counts in vim.b.gitsigns_status_dict, which the
--      lualine `diff` component above consumes as its `source` -- one
--      git query feeding both the gutter and the statusline.
--
-- A "hunk" is one contiguous block of changed lines (what `git diff`
-- prints between @@ markers). Diffs are computed against the INDEX,
-- not HEAD: staging a hunk switches its signs to the staged set
-- (same characters, dimmer GitSignsStaged* highlights, enabled by
-- default) rather than removing them, so staged-but-uncommitted
-- changes stay visible until you commit.
--
-- Keymap quick reference. All maps are buffer-local and exist only in
-- git-tracked buffers (created by on_attach below). Mnemonics:
-- h = hunk, t = toggle; lowercase acts on the hunk under the cursor,
-- uppercase on the whole buffer. <leader> is space.
--
--   ]h / [h       jump to next / previous hunk
--   <leader>hs    stage hunk (press again to unstage)
--                 visual: stage only the selected lines
--   <leader>hr    reset hunk to index version (recover with u)
--                 visual: reset only the selected lines
--   <leader>hS    stage entire buffer
--   <leader>hR    reset entire buffer
--   <leader>hp    preview hunk in a float
--   <leader>hi    preview hunk inline (virtual text)
--   <leader>hb    toggle inline blame virtual text
--   <leader>hd    diff split: buffer vs index
--   <leader>hD    diff split: buffer vs HEAD~
--   <leader>hq    buffer hunks -> quickfix list
--   <leader>hQ    all repo hunks -> quickfix list
--   <leader>hB    blame current line (full commit message)
--   <leader>hw    toggle word diff
--   ih            hunk text object (vih selects, dih deletes, ...)
--
-- Command-line access: every action is also an ex-command,
-- `:Gitsigns <subcommand> [args]` with tab completion. The keymapped
-- actions above (stage_hunk, reset_hunk, stage_buffer, reset_buffer,
-- nav_hunk, preview_hunk, preview_hunk_inline, blame_line, diffthis,
-- setqflist, select_hunk, toggle_current_line_blame, toggle_word_diff)
-- all work that way too - e.g. :Gitsigns diffthis ~, :Gitsigns
-- setqflist all. The subcommands below have NO keymap and are
-- reachable only as commands:
--
--   :Gitsigns blame              whole-buffer blame in a side window
--                                (per-line commits; <CR> on a line
--                                opens a menu of blame actions)
--   :Gitsigns show [rev]         open THIS file as it was at [rev],
--                                e.g. :Gitsigns show HEAD~2
--   :Gitsigns show_commit [rev]  show a commit itself in a split
--                                (default HEAD)
--   :Gitsigns change_base <rev>  diff signs against <rev> instead of
--                                the index (e.g. change_base HEAD~);
--                                :Gitsigns reset_base restores the
--                                index as the base
--   :Gitsigns setloclist         buffer hunks -> location list (the
--                                window-local sibling of <leader>hq's
--                                setqflist)
--   :Gitsigns toggle_signs       hide / show the sign-column marks
--   :Gitsigns toggle_numhl       also highlight changed line NUMBERS
--   :Gitsigns toggle_linehl      also highlight whole changed lines
--   :Gitsigns refresh            re-read git state (rarely needed;
--                                gitsigns watches the git dir itself)
--   :Gitsigns attach / detach / detach_all
--                                manual per-buffer attach control
--
-- Deprecated subcommands (tab completion still offers them; avoid in
-- new muscle memory): next_hunk / prev_hunk -> nav_hunk,
-- undo_stage_hunk -> stage_hunk (it toggles), toggle_deleted ->
-- preview_hunk_inline.
--
-- Defaults left as-is (the notable ones):
--   * current_line_blame = false  -- inline blame virtual text is OFF
--                                    until toggled with <leader>hb.
--   * max_file_length = 40000     -- gitsigns disables itself in
--                                    files longer than this.
--
-- Non-default (2026-08-14): attach_to_untracked = true. Brand-new
-- files inside a repo attach too: every line carries the ":"
-- untracked sign (see ascii_signs below), so new-file work is
-- visible in the gutter before the first `git add`. Was the default
-- false ("no signs until git add"-ed) from 2026-08 until then.
return {
	"lewis6991/gitsigns.nvim",
	config = function()
		-- ASCII sign characters. The plugin's defaults are UTF-8
		-- box-drawing characters (vertical bars, overline), which
		-- violates this config's ASCII-only rule. changedelete
		-- shares "~" with change -- that mirrors upstream, which
		-- also gives them the same glyph and distinguishes them by
		-- highlight group (GitSignsChangedelete vs GitSignsChange).
		--
		-- The same table is used for `signs_staged` because staged
		-- hunks have their OWN character set (also box-drawing by
		-- default); staged vs unstaged then differ only by their
		-- highlight groups, exactly as upstream intends.
		local ascii_signs = {
			add = { text = "+" }, -- new line
			change = { text = "~" }, -- modified line
			delete = { text = "_" }, -- line(s) deleted below this line
			topdelete = { text = "^" }, -- line(s) deleted above line 1
			changedelete = { text = "~" }, -- modified + deletion below
			untracked = { text = ":" }, -- line in a new untracked file
		}

		require("gitsigns").setup({
			signs = ascii_signs,
			signs_staged = ascii_signs,

			-- Attach to untracked files (non-default; see the header
			-- note): new files show ":" on every line until added.
			attach_to_untracked = true,

			-- Buffer-local keymaps, created only when gitsigns
			-- attaches to a buffer (i.e. the file is inside a git
			-- repo). This is the plugin's recommended pattern and
			-- the reason these maps live here rather than in
			-- lua/jwn/keymappings/: they should not exist in
			-- buffers that have no git data behind them.
			--
			-- Mnemonics: everything lives under <leader>h (hunk/git);
			-- the toggles moved here from <leader>t* on 2026-08-15 to
			-- free that key for the telescope picker.
			-- Lowercase acts on the hunk under the cursor,
			-- uppercase on the whole buffer.
			on_attach = function(bufnr)
				local gitsigns = require("gitsigns")

				local function map(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, {
						buffer = bufnr,
						silent = true,
						desc = desc,
					})
				end

				-- Navigation. ]h / [h, h for hunk (moved off the
				-- community-conventional ]c / [c on 2026-08-15; those
				-- now keep their built-in diff-mode meaning
				-- untouched). The diff-window fallthrough is kept so
				-- the keys still behave sensibly in `nvim -d` or the
				-- <leader>hd split.
				map("n", "]h", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gitsigns.nav_hunk("next")
					end
				end, "Git: next hunk")
				map("n", "[h", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gitsigns.nav_hunk("prev")
					end
				end, "Git: previous hunk")

				-- Stage / reset. stage_hunk on an already-staged
				-- hunk un-stages it (it is a toggle). reset_hunk
				-- rewrites the lines back to the index version --
				-- destructive to unstaged edits, but recoverable
				-- with plain undo (u) since it edits the buffer.
				-- The visual variants act on the selected lines
				-- only, for splitting a hunk into finer pieces.
				map("n", "<leader>hs", gitsigns.stage_hunk, "Git: stage hunk (toggles)")
				map("n", "<leader>hr", gitsigns.reset_hunk, "Git: reset hunk to index")
				map("v", "<leader>hs", function()
					gitsigns.stage_hunk({
						vim.fn.line("."),
						vim.fn.line("v"),
					})
				end, "Git: stage selected lines")
				map("v", "<leader>hr", function()
					gitsigns.reset_hunk({
						vim.fn.line("."),
						vim.fn.line("v"),
					})
				end, "Git: reset selected lines")
				map("n", "<leader>hS", gitsigns.stage_buffer, "Git: stage entire buffer")
				map("n", "<leader>hR", gitsigns.reset_buffer, "Git: reset entire buffer")

				-- Inspection. preview_hunk floats the before/after
				-- of the hunk under the cursor; the inline variant
				-- shows it as virtual text in the buffer instead.
				-- blame_line({ full = true }) includes the full
				-- commit message, not just the summary line.
				-- diffthis opens a native side-by-side diff split
				-- of the buffer against the index; the "~" variant
				-- diffs against HEAD~ (the commit before the last
				-- one) -- useful right after committing.
				map("n", "<leader>hp", gitsigns.preview_hunk, "Git: preview hunk (float)")
				map("n", "<leader>hi", gitsigns.preview_hunk_inline, "Git: preview hunk (inline)")
				map("n", "<leader>hB", function()
					gitsigns.blame_line({ full = true })
				end, "Git: blame line")
				map("n", "<leader>hd", gitsigns.diffthis, "Git: diff against index")
				map("n", "<leader>hD", function()
					gitsigns.diffthis("~")
				end, "Git: diff against HEAD~")

				-- Hunk lists. Send hunks to the quickfix list to
				-- review every pending change in one place
				-- (:copen, then jump entry by entry).
				map("n", "<leader>hq", gitsigns.setqflist, "Git: buffer hunks to quickfix")
				map("n", "<leader>hQ", function()
					gitsigns.setqflist("all")
				end, "Git: all repo hunks to quickfix")

				-- Toggles.
				map("n", "<leader>hb", gitsigns.toggle_current_line_blame, "Git: toggle inline blame")
				map("n", "<leader>hw", gitsigns.toggle_word_diff, "Git: toggle word diff")

				-- Text object: "ih" = inner hunk. Works in
				-- operator-pending and visual mode, so `vih`
				-- selects the hunk, `dih` deletes it, etc.
				map({ "o", "x" }, "ih", gitsigns.select_hunk, "Git: select hunk")
			end,
		})
	end,
}
