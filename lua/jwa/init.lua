-- ============================================================================
-- Editor options + general autocmds.
--
-- This is the catch-all "make Vim feel right" module. It runs after the
-- plugin set is declared and the language-specific modules (lsp, colors,
-- keymap, cmp) have their own setup() called from the root init.lua.
--
-- Sections:
--   1.  Display & cursor      - line numbers, cursor style, status bar
--   2.  Indent & whitespace   - global tab/space defaults
--   2b. Whitespace visibility - listchars config + :ToggleWS toggle command
--   3.  Persistence           - backup/swap/undo behavior
--   4.  Misc UX               - clipboard, wildmenu, mouse, leader key
--   5.  Plugin-side knobs     - vim.g.* tweaks for plugins (none today)
--   6.  Autocmds              - trim-trailing-whitespace + EOF blank lines,
--                               lisp-style indent override, ARM assembly
--                               filetype detection
-- ============================================================================

local M = {}

-- require("jwa").setup()
function M.setup()
	-- ------------------------------------------------------------------------
	-- 1. Display & cursor
	-- ------------------------------------------------------------------------
	-- Block cursor in normal/visual/cmdline; disable blinking everywhere.
	vim.o.guicursor = "n-v-c:block-Cursor,a:blinkon0"
	vim.o.showcmd = true -- show partial commands in the bottom-right
	vim.wo.number = true -- absolute line number for the current line
	vim.wo.relativenumber = true -- relative numbers above/below (jump-friendly)
	vim.wo.cursorline = true -- highlight the line the cursor is on...
	vim.wo.cursorlineopt = "number" -- ...but only the line number, not the row
	vim.o.ruler = true -- line/col indicator in the bottom-right
	vim.o.laststatus = 2 -- always show the status line (not just multi-window)
	vim.o.title = true -- set the terminal/window title to the filename
	vim.opt.termguicolors = true -- 24-bit color (required by most modern themes)
	-- Optional: hide the command line until you type ":"
	-- vim.opt.cmdheight = 0

	-- ------------------------------------------------------------------------
	-- 2. Indent & whitespace defaults (per-language overrides come from the
	--    LispIndent autocmd below, and from filetype plugins)
	-- ------------------------------------------------------------------------
	vim.o.expandtab = true -- spaces, not tabs, on <Tab>
	vim.o.autoindent = true -- carry indent across newlines
	vim.o.tabstop = 4 -- a literal tab renders as 4 spaces
	vim.o.shiftwidth = 4 -- >> / << shifts by 4 columns
	vim.o.wrap = false -- no soft-wrap of long lines

	-- ------------------------------------------------------------------------
	-- 2b. Whitespace visualization (off by default; toggle with :ToggleWS)
	-- ------------------------------------------------------------------------
	-- We configure `listchars` up-front but leave `list` itself OFF. The
	-- :ToggleWS user command flips `list` on/off for the current buffer, so
	-- whitespace visibility is opt-in per buffer rather than a global
	-- always-on (always-on dots in every blank cell turns out to be very
	-- noisy in normal editing -- the previous commented-out attempt used
	-- space="." which dotted every single space).
	--
	-- Marker characters chosen to be ASCII-only and visually low-noise:
	--   tab = ">."  - tab start marked with `>`, the rest filled with `.`
	--                 so a 4-wide tab reads as `>...`
	--   lead = "."  - leading space gets a single dot. Combined with the
	--                 dim Whitespace color below, leading indentation
	--                 reads as a faint dot grid -- enough to see indent
	--                 structure, not enough to compete with code.
	--   trail = "." - trailing space marker (most useful: catches that
	--                 line you accidentally left hanging spaces on)
	--   nbsp = "_"  - non-breaking space. Worth surfacing because they
	--                 sneak in from copy-paste out of docs / web pages
	--                 and cause silent bugs (your indenter / linter sees
	--                 a space, but the byte is U+00A0).
	--   extends/precedes = ">"/"<" - shown only when `wrap = false` and a
	--                 line runs off-screen; the marker hints at which
	--                 direction the offscreen content goes.
	vim.opt.listchars = {
		tab = ">.",
		lead = ".",
		trail = ".",
		nbsp = "_",
		extends = ">",
		precedes = "<",
	}

	-- Subtle color for the markers. Apply now AND on every :colorscheme
	-- (which runs `:highlight clear` and would otherwise reset our tweak).
	--
	-- The color is picked to be barely-visible against the active
	-- background: a dark dim-grey on dark themes, a light grey on light
	-- themes. `Whitespace` colors the tab/space/trail markers; `NonText`
	-- covers extends/precedes (and the empty-line `~` markers).
	local function apply_dim_whitespace()
		local hl = vim.o.background == "dark" and { fg = "#2a2a2a" } or { fg = "#ececec" }
		vim.api.nvim_set_hl(0, "Whitespace", hl)
		vim.api.nvim_set_hl(0, "NonText", hl)
	end
	apply_dim_whitespace()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("JwaWhitespaceHl", { clear = true }),
		callback = apply_dim_whitespace,
	})

	-- :ToggleWS - flip whitespace visibility for the current window.
	-- Scoped to the window (not global) so you can have, say, your code
	-- buffer with whitespace shown and an oil listing with it off.
	vim.api.nvim_create_user_command("ToggleWS", function()
		vim.wo.list = not vim.wo.list
	end, {
		desc = "Toggle whitespace visualization (tabs / leading / trailing / nbsp) for this window",
	})

	-- ------------------------------------------------------------------------
	-- 3. Persistence (backup files, swap files, undo history)
	-- ------------------------------------------------------------------------
	vim.o.backup = false -- no ~-suffixed backup files
	vim.o.swapfile = false -- no .swp files (mild risk on crashes; usually fine)
	vim.o.undofile = true -- persistent undo across sessions (~/.local/share/nvim/undo)
	vim.o.history = 300 -- ":" command and search history depth
	vim.o.autoread = true -- reload files changed outside nvim if buffer is clean

	-- ------------------------------------------------------------------------
	-- 4. Misc UX
	-- ------------------------------------------------------------------------
	vim.o.encoding = "utf-8"
	vim.o.wildmenu = true -- ":<Tab>" pops up a menu of completions
	vim.o.clipboard = "unnamedplus" -- y/p use the system clipboard by default
	vim.g.mapleader = " " -- <leader> = space (used by mappings in keymappings/)
	vim.g.maplocalleader = "\\" -- <localleader> = backslash (filetype-scoped maps, e.g. ocaml.nvim)

	-- ------------------------------------------------------------------------
	-- 5. Plugin-side knobs
	-- ------------------------------------------------------------------------
	-- (Empty since 2026-08. vim.g.NERDTreeWinSize lived here until nerdtree
	-- was replaced by oil.nvim; oil uses the full window, so there is no
	-- pane-width knob. Plugin behavior is configured in each plugin's spec
	-- in its spec file under lua/jwa/plugins/spec/; the section is kept for future vim.g.*
	-- knobs that must be set before a plugin loads.)

	-- ------------------------------------------------------------------------
	-- 6. Autocmds
	-- ------------------------------------------------------------------------

	-- ------------------------------------------------------------------------
	-- Whitespace cleanup on save
	-- ------------------------------------------------------------------------
	-- Two passes run just before the buffer is written to disk:
	--
	--   (a) Strip end-of-line whitespace on every line.
	--       The `\s\+$` pattern matches one-or-more whitespace anchored to
	--       end-of-line. The trailing `/e` flag means "no error if the
	--       pattern doesn't match," which avoids beeping on already-clean
	--       files. `keeppatterns` prevents this substitution from clobbering
	--       the user's last search pattern (so `n` after a save still
	--       repeats whatever they were searching for).
	--
	--   (b) Strip trailing blank lines at end-of-file.
	--       We walk backwards from the last line, dropping any line whose
	--       content is the empty string, then truncate the buffer.
	--
	--       Subtlety: Neovim/Vim doesn't store the file's final `\n` as a
	--       separate buffer line - it's implicit, controlled by the
	--       'endofline'/'fixeol' options. So "buffer with no trailing blank
	--       lines" maps to "file ending in exactly one `\n`" on disk, which
	--       is the POSIX-clean convention most formatters and linters
	--       expect. We do NOT strip the implicit final newline itself.
	--
	-- Cursor position is saved and restored with winsaveview/winrestview so
	-- writing the buffer doesn't jump the view (the bare `:%s/.../` would
	-- leave the cursor on the last match line).
	vim.api.nvim_create_augroup("TrimOnSave", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = "TrimOnSave",
		pattern = "*",
		callback = function()
			local view = vim.fn.winsaveview()

			-- (a) End-of-line whitespace
			vim.cmd([[silent! keeppatterns %s/\s\+$//e]])

			-- (b) Trailing blank lines at EOF
			local last = vim.api.nvim_buf_line_count(0)
			while last > 1 do
				local line = vim.api.nvim_buf_get_lines(0, last - 1, last, true)[1]
				if line ~= "" then
					break
				end
				last = last - 1
			end
			if last < vim.api.nvim_buf_line_count(0) then
				vim.api.nvim_buf_set_lines(0, last, -1, true, {})
			end

			vim.fn.winrestview(view)
		end,
	})

	-- ------------------------------------------------------------------------
	-- Phantom final-newline line (third revision 2026-08-19: REACHABLE)
	-- ------------------------------------------------------------------------
	-- The file's final `\n`, rendered as a `~` line the cursor can LAND
	-- ON, Helix-style. Two earlier revisions drew it as a virtual line
	-- (first empty and invisible under dracula's hidden tildes, then a
	-- visible `~`) - but virtual lines are pure decoration and can never
	-- host the cursor, so this revision makes it a REAL managed buffer
	-- line, fully approved by the user with the costs on the table.
	--
	-- The contract:
	--   * On load, a real empty line is appended (not undoable, buffer
	--     stays unmodified). It renders as a comment-colored `~` with no
	--     line number via a custom statuscolumn.
	--   * On disk, NOTHING changes: TrimOnSave (above) strips trailing
	--     blank lines on every write, so files keep their single POSIX
	--     final newline; the phantom is re-appended after the write.
	--   * SELF-HEALING: whenever an edit leaves the last line non-empty
	--     (typing on the phantom, pasting, dd'ing it), a fresh phantom is
	--     appended, undojoin'd into the user's change so `u` sees one
	--     step. dd on the phantom is therefore a natural no-op.
	--   * Keys ON the phantom (user spec, Helix semantics): `a` and `i`
	--     both append at the END of the last content line; `o` and `O`
	--     open a new content line at end of file. `G` lands on the
	--     phantom - intended: it IS end of file.
	--   * Accepted cost: every consumer of the buffer (LSP, formatters,
	--     buffer grep, \eb-style whole-buffer evals) sees one trailing
	--     empty line. Content positions are unaffected.
	--
	-- statuscolumn note: setting it takes over the ENTIRE gutter, so
	-- every branch below must start with %C%s (fold + sign segments) or
	-- gitsigns / diagnostic signs would silently vanish. The column is
	-- set per-window and only for participating buffers; plugin windows
	-- (oil, telescope, ...) keep the stock gutter.
	--
	-- Participation: normal file buffers (buftype == "") that are not
	-- binary, where 'endofline'/'fixeol' put a real newline on disk, and
	-- not in diff mode (a phantom would render as a fake extra-line
	-- diff). PhantomEol links to Comment, re-applied on ColorScheme
	-- because colors.lua switches schemes per filetype and :colorscheme
	-- wipes user groups.
	local phantom_group = vim.api.nvim_create_augroup("PhantomEol", { clear = true })

	local function phantom_hl()
		vim.api.nvim_set_hl(0, "PhantomEol", { link = "Comment" })
	end
	phantom_hl()

	-- --- gitsigns shim (2026-08-19, same-day fix) -------------------------
	-- gitsigns treats the buffer as truth: with a real phantom line it
	-- showed every clean file as +1 - and, far worse, stage_buffer WROTE
	-- the phantom into the git index (verified: staged blob ended 0a 0a,
	-- a non-POSIX trailing blank line headed for a commit). Both the sign
	-- diff (manager.lua) and the staging path (cache.lua) read the buffer
	-- through ONE choke point, gitsigns.util.buf_lines(); the wrapper
	-- below drops the managed trailing line from what gitsigns sees, so
	-- signs, counts, and staging all describe the file as it exists on
	-- disk. Hunk line numbers are unaffected: the phantom is strictly
	-- trailing, so removing it shifts nothing above it.
	--
	-- This IS a reach into plugin internals - accepted deliberately, with
	-- two guards: lazy-lock.json pins the gitsigns revision between
	-- deliberate updates, and if an update ever removes buf_lines the
	-- shim REFUSES: it screams at ERROR level and phantom lines are
	-- disabled entirely (phantom_eligible below checks shim_failed),
	-- because a cosmetic feature must never be allowed to corrupt the
	-- index again. :checkhealth jwa reports the shim state.
	--
	-- Install timing: at the User LazyLoad event for gitsigns.nvim (fires
	-- right after the plugin loads, before its scheduled buffer attach
	-- ever diffs), plus one immediate attempt for reload scenarios.
	local phantom_shim_state = "pending"
	local function install_gitsigns_shim()
		if phantom_shim_state ~= "pending" or not package.loaded["gitsigns.util"] then
			return
		end
		local util = package.loaded["gitsigns.util"]
		if type(util.buf_lines) ~= "function" then
			phantom_shim_state = "failed"
			vim.schedule(function()
				vim.notify(
					"PhantomEol: gitsigns.util.buf_lines is gone (gitsigns update?) - phantom EOF lines disabled to protect the git index",
					vim.log.levels.ERROR
				)
			end)
			return
		end
		local orig = util.buf_lines
		util.buf_lines = function(bufnr, ...)
			local lines = orig(bufnr, ...)
			if vim.b[bufnr].jwa_phantom and #lines > 1 and lines[#lines] == "" then
				lines[#lines] = nil
			end
			return lines
		end
		phantom_shim_state = "ok"
	end
	M.phantom_shim_state = function()
		return phantom_shim_state
	end

	local function phantom_eligible(buf)
		return phantom_shim_state ~= "failed"
			and vim.bo[buf].buftype == ""
			and not vim.bo[buf].binary
			and (vim.bo[buf].endofline or vim.bo[buf].fixendofline)
			and not vim.wo.diff
	end

	-- True when the cursor sits on the managed trailing line and there is
	-- content above it for the a / i redirects to target.
	local function on_phantom()
		local buf = vim.api.nvim_get_current_buf()
		if not vim.b[buf].jwa_phantom then
			return false
		end
		local row = vim.api.nvim_win_get_cursor(0)[1]
		local last = vim.api.nvim_buf_line_count(buf)
		return row == last
			and last > 1
			and vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1] == ""
	end

	-- Append the managed trailing line when missing. quiet = true (load,
	-- post-write): not undoable and the buffer stays unmodified. quiet =
	-- false (mid-session self-heal): undojoin'd into the user's change,
	-- so undo treats edit + heal as one step; falls back to a plain
	-- append when undojoin is not permitted (e.g. right after undo).
	local function ensure_phantom(buf, quiet)
		if not (vim.api.nvim_buf_is_valid(buf) and phantom_eligible(buf)) then
			return
		end
		local last = vim.api.nvim_buf_line_count(buf)
		if vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1] == "" then
			vim.b[buf].jwa_phantom = true
			return
		end
		if quiet then
			local ul = vim.bo[buf].undolevels
			vim.bo[buf].undolevels = -1
			vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "" })
			vim.bo[buf].undolevels = ul
			vim.bo[buf].modified = false
		else
			pcall(vim.cmd, "undojoin")
			vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "" })
		end
		vim.b[buf].jwa_phantom = true
	end

	-- The gutter: `~` (no number) for the phantom line, the stock
	-- number / relativenumber look everywhere else, signs preserved.
	function _G.JwaPhantomStatuscol()
		if vim.v.virtnum ~= 0 then
			return "%C%s"
		end
		local buf = vim.api.nvim_get_current_buf()
		local lnum = vim.v.lnum
		if
			vim.b[buf].jwa_phantom
			and lnum == vim.api.nvim_buf_line_count(buf)
			and vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] == ""
		then
			return "%C%s%=%#PhantomEol#~ "
		end
		if vim.v.relnum == 0 then
			return "%C%s%=%#CursorLineNr#" .. lnum .. " "
		end
		return "%C%s%=%#LineNr#" .. vim.v.relnum .. " "
	end

	-- a / i / o / O redirects, active ONLY on the phantom line (expr
	-- maps; everywhere else the key falls through untouched). Helix
	-- semantics per the user: both a and i append at the end of the
	-- last content line; o / O open a new content line at end of file
	-- (O on the phantom already does exactly that, so both map to it).
	local function phantom_key(fallback, redirect)
		return function()
			if on_phantom() then
				return redirect
			end
			return fallback
		end
	end
	vim.keymap.set("n", "a", phantom_key("a", "kA"), { expr = true, desc = "Append (end of file on the phantom line)" })
	vim.keymap.set("n", "i", phantom_key("i", "kA"), { expr = true, desc = "Insert (end of file on the phantom line)" })
	vim.keymap.set("n", "o", phantom_key("o", "O"), { expr = true, desc = "Open line (at end of file on the phantom line)" })
	vim.keymap.set("n", "O", phantom_key("O", "O"), { expr = true, desc = "Open line (at end of file on the phantom line)" })

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		group = phantom_group,
		pattern = "*",
		callback = function(args)
			ensure_phantom(args.buf, true)
		end,
	})
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = phantom_group,
		pattern = "*",
		callback = function(args)
			ensure_phantom(args.buf, false)
		end,
	})
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = phantom_group,
		pattern = "*",
		callback = function(args)
			if phantom_eligible(args.buf) then
				ensure_phantom(args.buf, vim.bo[args.buf].modified == false)
				vim.wo.statuscolumn = "%{%v:lua.JwaPhantomStatuscol()%}"
			elseif vim.wo.statuscolumn:find("JwaPhantomStatuscol", 1, true) then
				vim.wo.statuscolumn = ""
			end
		end,
	})
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = phantom_group,
		pattern = "*",
		callback = phantom_hl,
	})
	-- Shim install: on gitsigns' lazy load (fires before its scheduled
	-- attach can diff anything), plus one immediate attempt so a config
	-- reload with gitsigns already resident is covered too.
	vim.api.nvim_create_autocmd("User", {
		group = phantom_group,
		pattern = "LazyLoad",
		callback = function(ev)
			if ev.data == "gitsigns.nvim" then
				install_gitsigns_shim()
			end
		end,
	})
	install_gitsigns_shim()
	-- Diff mode: a phantom would render as a fake extra-line difference
	-- in diffview / :Gitsigns diffthis, so it is pulled out (quietly,
	-- preserving the modified flag) when a window enters diff mode and
	-- restored when diff mode ends.
	vim.api.nvim_create_autocmd("OptionSet", {
		group = phantom_group,
		pattern = "diff",
		callback = function()
			local buf = vim.api.nvim_get_current_buf()
			if vim.v.option_new == true then
				if not vim.b[buf].jwa_phantom then
					return
				end
				local last = vim.api.nvim_buf_line_count(buf)
				if last > 1 and vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1] == "" then
					local mod = vim.bo[buf].modified
					local ul = vim.bo[buf].undolevels
					vim.bo[buf].undolevels = -1
					vim.api.nvim_buf_set_lines(buf, last - 1, last, false, {})
					vim.bo[buf].undolevels = ul
					vim.bo[buf].modified = mod
				end
				vim.b[buf].jwa_phantom = false
			else
				ensure_phantom(buf, vim.bo[buf].modified == false)
			end
		end,
	})

	-- Re-arm filetype + syntax (Neovim usually has these on by default; setting
	-- them explicitly is harmless and makes the config self-contained).
	vim.api.nvim_command("filetype on")
	vim.api.nvim_command("filetype plugin indent on")
	vim.api.nvim_command("syntax on")

	-- Force 2-space indents for languages where that's the community norm
	-- (Lisp family, FP-heavy languages, structured text formats). Wrapped in
	-- an augroup so reloading this file doesn't stack duplicate autocmds.
	vim.api.nvim_create_augroup("LispIndent", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		pattern = {
			"lisp",
			"scheme",
			"clojure",
			"fennel",
			"haskell",
			"yml",
			"yaml",
			"prisma",
			"typescript",
			"json",
			"jsonc",
			"ocaml",
			"dune", -- s-expressions; dune format-dune-file has the last word on save
			"elixir",
			"erlang",
			"vhdl",
			"cabal",
			"fortran",
			"markdown",
		},
		callback = function()
			vim.bo.tabstop = 2
			vim.bo.shiftwidth = 2
			vim.bo.softtabstop = 2
			vim.bo.expandtab = true
		end,
		group = "LispIndent",
	})

	-- ARM assembly: Neovim doesn't ship a filetype detector for .s files
	-- (it's ambiguous between several flavors), so force ARM syntax. Pairs
	-- with the ARM9/arm-syntax-vim plugin declared in the root init.lua.
	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		pattern = "*.s",
		callback = function()
			vim.bo.filetype = "arm"
		end,
	})
end

return M
