-- File explorer (oil.nvim): edit the filesystem like a buffer.
--
-- Replaced preservim/nerdtree (2026-08). Oil opens a directory
-- LISTING as a normal editable buffer; each listing is a real buffer,
-- so the <C-o> / <C-i> jumplist motions walk through folder history
-- like any other buffers.
--
-- SIDEBAR (2026-08-14): the global <C-t> presents the listing in a
-- fixed 35-column left split via lua/hwangfu/explorer.lua, restoring
-- NERDTree's shape: files selected in the sidebar open in the MAIN
-- window (and close the sidebar); folders replace the sidebar's
-- listing in place. Inline tree expansion is deliberately absent -
-- oil is one-directory-per-buffer by architecture and cannot show a
-- nested tree; that trade-off was accepted explicitly (the
-- alternative was a tree plugin like nvim-tree). Width, auto-close,
-- and fallback rules live in explorer.lua's header.
--
-- Keymap quick reference. All keys below are buffer-local to oil
-- listings; oil defaults unless marked (custom). Press g? inside an
-- oil buffer for the live version of this table.
--
-- Navigation:
--   <CR>    open entry - sidebar-aware (explorer.select): in the
--           sidebar, folders replace the listing there and files open
--           in the main window (closing the sidebar); in full-window
--           listings it is oil's stock select
--   ../     FIRST ROW of every listing: <CR> on it goes up one
--           directory - the NERDTree ".. (up a dir)" entry (2026-08).
--           Oil always renders this row (reserved entry ID 0; the
--           save-parser ignores ID 0, so dd-ing it or :w can never
--           turn it into a filesystem operation), but it is filtered
--           through the same is_hidden_file test as ordinary entries,
--           and the default "starts with a dot" rule swallowed it
--           along with the dotfiles. The view_options override below
--           exempts ".." specifically; real dotfiles stay hidden
--           behind g. exactly as before.
--   -       go up one directory
--   ..      go up one directory (custom alias for `-`, shell muscle
--           memory carried over from the old NERDTree map; cost: `.`
--           repeat waits timeoutlen inside oil buffers only)
--   _       open listing of Neovim's current working directory
--   `       :cd into the directory being viewed (changes nvim's cwd)
--   <C-t>   sidebar: close the sidebar window; full-window listing:
--           close the listing back to the previous buffer
--           (explorer.smart_close - a plain actions.close in the
--           sidebar would strand the previous buffer in the 35-col
--           split. Still overrides oil's default <C-t>
--           open-in-new-tab, which would shadow the global toggle)
--   <C-c>   DISABLED (2026-08-15): <C-t> is the one close key; the
--           key falls back to its harmless built-in
--
-- Opening / inspecting:
--   <C-h>   open entry in a horizontal split
--   <C-p>   preview entry in a float (moving the cursor re-previews)
--   <C-l>   refresh the listing from disk
--   <C-s>   save = apply pending operations (custom: oil's default
--           <C-s> open-in-vsplit is disabled with `false` so the
--           global <C-s> :w map shows through. Consequence: there is
--           currently NO open-in-vsplit key in oil -- use <C-h> and
--           move the window, or bind a replacement here if missed.)
--
-- File operations: edit the listing like text, then :w (or <C-s>).
-- Every :w shows a confirmation summary before touching disk.
--   create file     open a new line, type `name.ext`, :w
--   create folder   same, but end with a slash: `newdir/`, :w
--   rename          edit the name in place (ciw, ...), :w
--   delete          dd the line, :w -- PERMANENT: delete_to_trash
--                   stays at its default false by explicit choice,
--                   so there is no freedesktop-trash safety net
--   copy / move     yy (copy) or dd (move) a line, p it into another
--                   oil listing -- or the same one -- then :w
--
-- Misc:
--   g?      help float listing every oil binding
--   g.      toggle hidden dotfiles (hidden by default, matching the
--           old nerdtree setup, which never enabled NERDTreeShowHidden)
--   gs      change sort order
--   gx      open entry with the system handler (browser, viewer, ...)
--
-- The global <C-t> toggle (open oil at the current buffer's directory
-- / close it) lives in lua/hwangfu/keymappings/navigation.lua with the other global
-- maps; the keys above are buffer-local to oil listings and belong
-- here with the plugin, same split as the gitsigns hunk maps.
--
-- lazy = false: oil replaces netrw as the directory handler (`nvim
-- some/dir/` opens an oil listing), so it must be on the runtimepath
-- from startup - lazy-loading would hand directory buffers to netrw.
return {
	"stevearc/oil.nvim",
	lazy = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({
			-- Hijack netrw so directory buffers open as oil listings.
			-- This is oil's default; stated explicitly for clarity.
			default_file_explorer = true,
			keymaps = {
				-- Sidebar-aware overrides; both delegate to
				-- lua/hwangfu/explorer.lua (see the Navigation
				-- comment above for what each does where).
				["<CR>"] = {
					callback = function()
						require("hwangfu.explorer").select()
					end,
					desc = "Open entry (sidebar-aware)",
				},
				["<C-t>"] = {
					callback = function()
						require("hwangfu.explorer").smart_close()
					end,
					desc = "Close sidebar / listing",
				},
				["<C-s>"] = false,
				["<C-c>"] = false,
				[".."] = "actions.parent",
			},
			view_options = {
				-- Default rule, minus one case: the ".." parent row
				-- (see the Navigation comment above). Everything else
				-- keeps oil's stock "dotfile = hidden" behavior, so
				-- g. still toggles real dotfiles and show_hidden
				-- stays at its default false.
				is_hidden_file = function(name, _) -- (name, bufnr) contract; bufnr unused
					if name == ".." then
						return false
					end
					return name:match("^%.") ~= nil
				end,
			},
		})
	end,
}
