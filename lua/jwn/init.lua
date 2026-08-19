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

-- require("jwn").setup()
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
		group = vim.api.nvim_create_augroup("JwnWhitespaceHl", { clear = true }),
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
	-- in its spec file under lua/jwn/plugins/spec/; the section is kept for future vim.g.*
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
	-- Phantom final-newline line (2026-08-19, user request)
	-- ------------------------------------------------------------------------
	-- Vim never shows the file's final `\n` - the buffer simply ends at the
	-- last content line and the `~` filler begins. VSCode renders that
	-- newline as one empty line at the bottom, and the user wants the same
	-- visual: it makes "this file ends with exactly one newline" visible
	-- instead of implicit.
	--
	-- Mechanics: one extmark on the last buffer line carrying a single
	-- virt_line - a display-only row below the content, before the
	-- first filler `~`. It is never part of the buffer, cannot be moved
	-- into (virtual lines are decoration; Helix-style navigation onto
	-- the final newline would need a REAL managed buffer line - assessed
	-- and declined 2026-08-19), and adds nothing on write; TrimOnSave
	-- above is unaffected.
	--
	-- Rendering (second revision, 2026-08-19): the row shows a `~` in its
	-- own PhantomEol group, linked to Comment. The first version drew an
	-- EMPTY row, which was invisible in practice: dracula hides the
	-- EndOfBuffer tildes by painting them in its own background color, so
	-- a blank phantom above blanked fillers displayed as nothing. Comment
	-- is legible in every scheme this config uses. The link is re-applied
	-- on ColorScheme because colors.lua switches schemes per filetype,
	-- and :colorscheme wipes user groups.
	--
	-- Shown only where a final newline will actually be on disk: normal
	-- file buffers (buftype == "") where 'endofline' is set or 'fixeol'
	-- will add the newline on save - i.e. it displays the file's future
	-- truth, matching what every save in this config produces. Terminals,
	-- pickers, oil listings (buftype ~= ""), and binary buffers are left
	-- alone.
	local phantom_ns = vim.api.nvim_create_namespace("jwn_phantom_eol")
	local function phantom_hl()
		vim.api.nvim_set_hl(0, "PhantomEol", { link = "Comment" })
	end
	phantom_hl()
	local function update_phantom(buf)
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end
		vim.api.nvim_buf_clear_namespace(buf, phantom_ns, 0, -1)
		if vim.bo[buf].buftype ~= "" or vim.bo[buf].binary then
			return
		end
		if not (vim.bo[buf].endofline or vim.bo[buf].fixendofline) then
			return
		end
		local last = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_buf_set_extmark(buf, phantom_ns, last - 1, 0, {
			virt_lines = { { { "~", "PhantomEol" } } },
		})
	end
	vim.api.nvim_create_augroup("PhantomEol", { clear = true })
	vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI" }, {
		group = "PhantomEol",
		pattern = "*",
		callback = function(args)
			update_phantom(args.buf)
		end,
	})
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = "PhantomEol",
		pattern = "*",
		callback = phantom_hl,
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
