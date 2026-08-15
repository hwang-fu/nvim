-- Whole-changeset diffs + history browsing (diffview.nvim).
--
-- The read-only INSPECTION layer of the git tooling. Complements
-- rather than overlaps the other two git pieces:
--   * gitsigns (above)      edits hunks inside the buffer (<leader>h*).
--   * lazygit (<leader>gg,  acts on the repo: stage / commit / branch /
--     lua/hwangfu/git.lua)  push, in a floating terminal.
--   * diffview (this spec)  shows changesets and history in native
--                           nvim windows with real syntax highlighting.
--
-- ADOPTION NOTE (2026-08): upstream is dormant - last push 2024-08,
-- not archived, feature-complete, the largest install base in its
-- niche, and no maintained equivalent exists. Adopted with eyes open:
-- if a future Neovim version breaks it, replace or drop it rather
-- than patch it.
--
-- Keymap quick reference (lazy `keys` below; global, normal mode):
--   <leader>gd   DiffviewOpen             working tree vs INDEX (not
--                                         HEAD: staged changes drop
--                                         out of the view - the same
--                                         base gitsigns diffs against)
--   <leader>gh   DiffviewFileHistory %    history of the current file
--   <leader>gH   DiffviewFileHistory      history of the whole repo
-- Inside a diffview tab:
--   <Tab> / <S-Tab>         next / previous changed file
--   g?                      diffview's own help for the current panel
--   q (or :DiffviewClose)   leave the view
--
-- Command reference (the full set; each lazy-loads this spec):
--   :DiffviewOpen [rev] [opts] [-- paths]
--                             compare the working tree against [rev];
--                             no rev = the index. Takes ranges and
--                             path filters, e.g.
--                               :DiffviewOpen HEAD~2
--                               :DiffviewOpen main...HEAD -- lua/
--   :DiffviewClose            close the active diffview tab
--   :[range]DiffviewFileHistory [paths] [opts]
--                             porcelain over git-log. No paths =
--                             whole repo; git pathspec supported.
--                             With a visual [range] it traces the
--                             history of just those LINES - great
--                             for "who touched this function".
--   :DiffviewToggleFiles      toggle the file panel
--   :DiffviewFocusFiles       focus (and open) the file panel
--   :DiffviewRefresh          re-read stats / entries for the view
--   :DiffviewLog              open diffview's debug log
--
-- Defaults kept throughout; diffview's default use_icons = true rides
-- the nvim-web-devicons already installed for lualine / oil.
return {
	"sindrets/diffview.nvim",
	cmd = {
		"DiffviewOpen",
		"DiffviewClose",
		"DiffviewFileHistory",
		"DiffviewToggleFiles",
		"DiffviewFocusFiles",
		"DiffviewRefresh",
		"DiffviewLog",
	},
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Git: diffview (working tree vs index)" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Git: file history (current file)" },
		{ "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Git: repo history" },
	},
	config = function()
		require("diffview").setup({})
	end,
}
