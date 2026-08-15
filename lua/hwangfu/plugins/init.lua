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

	-- Statusline.
	{
		"nvim-lualine/lualine.nvim",
		-- Icon provider for the `filetype` component (per-language glyphs,
		-- e.g. for lua / rust / python). Only consulted because
		-- icons_enabled = true below; lualine works fine without it, just
		-- icon-less. The glyphs are Nerd Font private-use-area codepoints,
		-- so the TERMINAL font must be (or fall back to) a Nerd Font --
		-- several are installed user-wide at ~/.local/share/fonts. The
		-- icons live inside the plugins at runtime; this config file
		-- itself stays ASCII-only.
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
					-- Nerd Font glyphs in components: branch icon, filetype
					-- icon (via nvim-web-devicons above). If the statusline
					-- ever shows empty boxes instead (terminal without a
					-- Nerd Font, e.g. over ssh on another machine), set
					-- this back to false and drop the dependency above.
					icons_enabled = true,
					component_separators = { left = "|", right = "|" },
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = {
						"mode",
					}, -- NORMAL / INSERT / VISUAL
					lualine_b = {
						"branch", -- git branch
						{
							"diff", -- git diff (+added ~modified -removed)
							-- Pull the counts from gitsigns.nvim (spec below)
							-- instead of lualine's internal `git diff`
							-- polling, so the statusline numbers and the
							-- gutter signs come from ONE git query and always
							-- agree. gitsigns publishes per-buffer counts in
							-- vim.b.gitsigns_status_dict (fields: added /
							-- changed / removed, plus head / root / gitdir).
							--
							-- Returning nil (gitsigns not attached: buffer
							-- outside a git repo, or an untracked file) makes
							-- the component render nothing -- same as
							-- lualine's internal source showed for those
							-- buffers before, so this changes no visuals.
							source = function()
								local status = vim.b.gitsigns_status_dict
								if status then
									return {
										added = status.added,
										modified = status.changed,
										removed = status.removed,
									}
								end
							end,
						},
					},
					lualine_c = {
						{
							"filename",
							path = 1,
						}, -- 0=filename, 1=relative path, 2=absolute path
						{
							"diagnostics", -- LSP diagnostics (errors/warnings)
							symbols = {
								error = "E:",
								warn = "W:",
								info = "I:",
								hint = "H:",
							},
						},
					},
					lualine_x = {
						"encoding", -- utf-8
						-- "fileformat", -- unix/dos
						"filetype", -- lua/python/go/...
					},
					lualine_y = { "progress" }, -- file progress %
					lualine_z = { "location" }, -- line:column
				},
				inactive_sections = {
					-- Statusline for inactive windows
					lualine_a = {},
					lualine_b = {},
					lualine_c = { "filename" },
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
			})
		end,
	},

	-- Git change indicators + hunk actions (gitsigns.nvim).
	--
	-- One of three git layers: gitsigns edits hunks IN the buffer; the
	-- <leader>g* namespace holds the repo-level UI (lazygit float in
	-- lua/hwangfu/git.lua, plus the diffview.nvim spec just below this
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
	--   ]c / [c       jump to next / previous hunk
	--   <leader>hs    stage hunk (press again to unstage)
	--                 visual: stage only the selected lines
	--   <leader>hr    reset hunk to index version (recover with u)
	--                 visual: reset only the selected lines
	--   <leader>hS    stage entire buffer
	--   <leader>hR    reset entire buffer
	--   <leader>hp    preview hunk in a float
	--   <leader>hi    preview hunk inline (virtual text)
	--   <leader>hb    blame current line (full commit message)
	--   <leader>hd    diff split: buffer vs index
	--   <leader>hD    diff split: buffer vs HEAD~
	--   <leader>hq    buffer hunks -> quickfix list
	--   <leader>hQ    all repo hunks -> quickfix list
	--   <leader>tb    toggle inline blame virtual text
	--   <leader>tw    toggle word diff
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
	--                                    until toggled with <leader>tb.
	--   * max_file_length = 40000     -- gitsigns disables itself in
	--                                    files longer than this.
	--
	-- Non-default (2026-08-14): attach_to_untracked = true. Brand-new
	-- files inside a repo attach too: every line carries the ":"
	-- untracked sign (see ascii_signs below), so new-file work is
	-- visible in the gutter before the first `git add`. Was the default
	-- false ("no signs until git add"-ed) from 2026-08 until then.
	{
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
				-- lua/hwangfu/keymap.lua: they should not exist in
				-- buffers that have no git data behind them.
				--
				-- Mnemonics: <leader>h* = hunk, <leader>t* = toggle.
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

					-- Navigation. ]c / [c are Vim's built-in
					-- jump-to-next/prev-difference keys in diff mode;
					-- reusing them for hunks is the community
					-- convention. In an actual diff window (e.g. the
					-- <leader>hd split below, or `nvim -d`) fall
					-- through to the built-in behavior.
					map("n", "]c", function()
						if vim.wo.diff then
							vim.cmd.normal({ "]c", bang = true })
						else
							gitsigns.nav_hunk("next")
						end
					end, "Git: next hunk")
					map("n", "[c", function()
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
					map("n", "<leader>hb", function()
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
					map("n", "<leader>tb", gitsigns.toggle_current_line_blame, "Git: toggle inline blame")
					map("n", "<leader>tw", gitsigns.toggle_word_diff, "Git: toggle word diff")

					-- Text object: "ih" = inner hunk. Works in
					-- operator-pending and visual mode, so `vih`
					-- selects the hunk, `dih` deletes it, etc.
					map({ "o", "x" }, "ih", gitsigns.select_hunk, "Git: select hunk")
				end,
			})
		end,
	},

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
	{
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
	},

	-- (Colorschemes migrated to spec/colorschemes.lua, 2026-08-15.)

	-- Browser live preview (live-preview.nvim): markdown, HTML (+CSS/JS),
	-- AsciiDoc and SVG, served at 127.0.0.1:5500 with live updates and
	-- markdown sync-scroll. Pure Lua backend - no NodeJS or Python.
	--
	-- Replaced iamcco/markdown-preview.nvim (2026-08): upstream effectively
	-- unmaintained (last push 2024-07), and live-preview covers everything
	-- it did. Markdown renders with live-preview's built-in GitHub-style
	-- CSS; the old custom Newsprint stylesheet is archived untouched at
	-- mkdp/newsprint.css (its fonts remain installed user-wide) in case it
	-- is ever revived via a fork of live-preview or a browser-side
	-- user-CSS (Stylus) rule scoped to 127.0.0.1:5500.
	--
	-- Config goes through require("livepreview.config").set() - the
	-- current API. require("live-preview").setup() still works but both
	-- the module name and setup() are deprecated shims upstream. Settings
	-- kept at their defaults, deliberately: port = 5500, sync_scroll =
	-- true, dynamic_root = false (server root = cwd, so relative links
	-- resolve from the project root), browser = "default", address =
	-- "127.0.0.1". The one non-default is picker = "telescope" - explicit
	-- beats auto-detect, and telescope is the only picker installed.
	--
	-- Keymaps (<leader>m* namespace, shared with render-markdown's mr):
	--   <leader>mp   :LivePreview start   preview current file in browser
	--   <leader>ms   :LivePreview close   stop the preview server
	--   <leader>mt   :LivePreview pick    telescope picker of previewable files
	-- Semantics vs the old mkdp maps: mp now works on any supported
	-- filetype (not just markdown), ms was "stop" (now close), mt was
	-- "toggle" (live-preview has no toggle; pick is the nearest verb).
	--
	-- cmd + keys lazy-load the plugin on first use; it previously loaded
	-- eagerly at startup for no benefit.
	{
		"brianhuster/live-preview.nvim",
		cmd = { "LivePreview" },
		keys = {
			{ "<leader>mp", "<cmd>LivePreview start<CR>", desc = "Preview: start (browser)" },
			{ "<leader>ms", "<cmd>LivePreview close<CR>", desc = "Preview: stop server" },
			{ "<leader>mt", "<cmd>LivePreview pick<CR>", desc = "Preview: pick file (telescope)" },
		},
		config = function()
			require("livepreview.config").set({
				picker = "telescope",
			})
		end,
	},

	-- In-buffer Markdown rendering (render-markdown.nvim).
	--
	-- Decorates Markdown *inside the editing buffer* via treesitter --
	-- styled headings, code-block backgrounds, drawn tables, bullets,
	-- checkboxes, block quotes and callouts. This is the in-editor
	-- counterpart to the BROWSER previewer above: live-preview.nvim opens
	-- an external window, whereas this one restyles the text you are
	-- already looking at -- no browser, no second process, scrolls with
	-- the buffer.
	--
	-- Default ON. The setup() call below passes enabled = true (also the
	-- plugin's own default), so rendering goes live the moment a Markdown
	-- buffer loads -- no manual step. Toggle the GLOBAL render state (every
	-- Markdown buffer at once) two equivalent ways:
	--
	--   <leader>mr             keymap ("markdown render")
	--   :MarkdownRender toggle the control command -- turns rendering ON if
	--                          it is off, OFF if it is on
	--
	-- COMMAND NAME. Upstream hardcodes its command as `:RenderMarkdown`
	-- (registered from the plugin's own plugin/ directory, which lazy sources
	-- just before our config() runs). To honor the rename we delete that
	-- stock command in config() and install our own `:MarkdownRender`, a thin
	-- wrapper that forwards every subcommand to render-markdown's public API.
	-- The <leader>mr keymap runs `:MarkdownRender toggle`, so key and command
	-- still share one path. All upstream subcommands carry over under the new
	-- name, with tab-completion:
	--   :MarkdownRender enable / disable / toggle              (global)
	--   :MarkdownRender buf_enable / buf_disable / buf_toggle  (this buffer)
	--   :MarkdownRender set true|false  /  set_buf true|false
	--   :MarkdownRender preview / expand / contract / log / debug / config
	-- A bare `:MarkdownRender` with no argument enables, matching upstream.
	--
	-- The keymap sits in the <leader>m* "markdown" namespace beside the
	-- live-preview keys (mp / ms / mt) and does not collide with any
	-- existing binding. Lazy-load triggers are `ft = "markdown"` (opening a
	-- Markdown file), `keys` (the <leader>mr press) and
	-- `cmd = { "MarkdownRender" }` (typing the command); render-markdown stays
	-- unloaded until the first of these fires. The `ft` trigger is what makes
	-- "default ON" actually visible -- opening a Markdown file loads the
	-- plugin, which then renders the buffer immediately because enabled =
	-- true. (The old enabled = false setup deliberately had NO ft trigger,
	-- since there was nothing to do on open; enabling by default inverts that
	-- reasoning, so the ft trigger is now required.) `keys`/`cmd` still reach
	-- it from a cold start in a non-Markdown buffer.
	--
	-- NON-OBVIOUS side effect of the `ft` trigger: when we set no explicit
	-- `file_types`, render-markdown adopts lazy.nvim's `ft` value as its
	-- file_types (see its resolve_config). So `ft = "markdown"` ALSO scopes
	-- rendering to Markdown buffers only -- it drops `gitcommit`, which is in
	-- upstream's default file_types. To also render commit-message buffers,
	-- add "gitcommit" to the ft list below.
	--
	-- Requirements (all already satisfied by this config except the parsers,
	-- which install on demand):
	--   * Icon provider -- nvim-tree/nvim-web-devicons (already pulled in as
	--     a lualine dependency). Re-listed under `dependencies` so a fresh
	--     clone installs it and the load order is correct.
	--   * Nerd Font in the terminal -- the same one lualine's glyphs need.
	--   * Treesitter parsers `markdown` AND `markdown_inline`. Our
	--     nvim-treesitter spec installs parsers on demand (no
	--     ensure_installed), so if a toggled-on buffer shows no styling,
	--     install them once with `:TSInstall markdown markdown_inline` and
	--     confirm with `:checkhealth render-markdown`.
	--
	-- ASCII-only rule: the glyphs render-markdown draws (heading icons,
	-- bullets, table borders) are Nerd Font / Unicode, but they come from
	-- the plugin's runtime defaults, NOT from this file -- the same
	-- arrangement as lualine's icons. This spec itself stays ASCII.
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		-- Load (and therefore render) when a Markdown buffer opens. This ft
		-- value also becomes the plugin's file_types -- see the NON-OBVIOUS
		-- note above before adding more entries here.
		ft = { "markdown" },
		keys = {
			{
				"<leader>mr",
				"<cmd>MarkdownRender toggle<CR>",
				desc = "Markdown: toggle in-buffer render",
			},
		},
		cmd = { "MarkdownRender" },
		config = function()
			-- Rendering ON by default. enabled = true is also the plugin's
			-- own default; we state it explicitly so the intent is obvious.
			-- Every other knob is left at the plugin's defaults.
			require("render-markdown").setup({
				enabled = true,
			})

			-- Rename :RenderMarkdown -> :MarkdownRender. Upstream registers
			-- its command from plugin/render-markdown.lua, which lazy sources
			-- just before this config() runs, so the stock :RenderMarkdown
			-- already exists here. Delete it, then install our own command of
			-- the new name. The wrapper mirrors upstream's dispatch (see
			-- render-markdown/core/command.lua): the first argument selects an
			-- API method (default "enable"); `set` / `set_buf` take an
			-- optional true|false; no other method takes an argument. We
			-- forward to the documented public API on require("render-markdown").
			pcall(vim.api.nvim_del_user_command, "RenderMarkdown")

			-- Subcommands kept in step with render-markdown's public API.
			-- `bool_methods` are the only ones that accept a true|false arg.
			local subcommands = {
				"enable",
				"disable",
				"toggle",
				"buf_enable",
				"buf_disable",
				"buf_toggle",
				"set",
				"set_buf",
				"get",
				"preview",
				"expand",
				"contract",
				"log",
				"debug",
				"config",
			}
			local bool_methods = { set = true, set_buf = true }

			local function startswith(value, prefix)
				return vim.startswith(value, prefix)
			end

			vim.api.nvim_create_user_command("MarkdownRender", function(opts)
				local fargs = opts.fargs
				if #fargs > 2 then
					vim.notify(
						"MarkdownRender: invalid # arguments - " .. #fargs,
						vim.log.levels.ERROR
					)
					return
				end
				local method = fargs[1] or "enable"
				local fn = require("render-markdown")[method]
				if type(fn) ~= "function" or method == "render" then
					vim.notify(
						"MarkdownRender: invalid command - " .. method,
						vim.log.levels.ERROR
					)
					return
				end
				local value = fargs[2]
				if value == nil then
					fn()
				elseif not bool_methods[method] then
					vim.notify(
						"MarkdownRender: no arguments allowed - " .. method,
						vim.log.levels.ERROR
					)
				elseif value == "true" or value == "false" then
					fn(value == "true")
				else
					vim.notify(
						"MarkdownRender: invalid argument - " .. method .. "(" .. value .. ")",
						vim.log.levels.ERROR
					)
				end
			end, {
				nargs = "*",
				desc = "render-markdown.nvim commands (renamed from :RenderMarkdown)",
				complete = function(arg_lead, cmd_line)
					-- A first token already present means we are completing the
					-- second argument: only set / set_buf offer one (true|false).
					local first = cmd_line:match("MarkdownRender%s+(%S+)%s+%S*$")
					if first then
						if bool_methods[first] then
							return vim.tbl_filter(function(v)
								return startswith(v, arg_lead)
							end, { "true", "false" })
						end
						return {}
					end
					return vim.tbl_filter(function(v)
						return startswith(v, arg_lead)
					end, subcommands)
				end,
			})
		end,
	},

	-- Comment toggling: handled by Neovim's built-in gc / gcc / gbc operators
	-- (added in Neovim 0.10). Comment.nvim was previously here but is now
	-- redundant. The visual-mode <C-l> map in lua/hwangfu/keymap.lua continues
	-- to work because it remaps to `gc`, which now resolves to the built-in.

	-- (blink.cmp migrated to spec/blink.lua, 2026-08-15.)

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
	--   <C-c>   close the listing (oil default; same effect as <C-t>)
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
	-- / close it) lives in lua/hwangfu/keymap.lua with the other global
	-- maps; the keys above are buffer-local to oil listings and belong
	-- here with the plugin, same split as the gitsigns hunk maps.
	--
	-- lazy = false: oil replaces netrw as the directory handler (`nvim
	-- some/dir/` opens an oil listing), so it must be on the runtimepath
	-- from startup - lazy-loading would hand directory buffers to netrw.
	{
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
	},

	-- Telescope: fuzzy finder / popup picker (files, live-grep, buffers, ...).
	-- Configured in lua/hwangfu/telescope.lua. plenary.nvim is a required
	-- library; telescope-fzf-native is a compiled sorter (built via `make`).
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
	},

	-- Elixir IDE wrapper over ElixirLS (and optionally Next LS).
	--
	-- elixir-tools.nvim owns the Elixir LSP client end-to-end and
	-- adds Elixir-specific user commands that the standard LSP
	-- doesn't reach:
	--   * :Mix <task>          run mix tasks with completion
	--                          (deps.get, ecto.migrate, test, ...)
	--   * :ElixirFromPipe      rewrite `foo |> bar(x)` -> `bar(foo, x)`
	--   * :ElixirToPipe        rewrite `bar(foo, x)` -> `foo |> bar(x)`
	--   * :ElixirExpandMacro   expand a macro in a floating split
	--                          (the Elixir analogue of rustaceanvim's
	--                          :RustLsp expandMacro)
	--   * :ElixirRestart       restart the Elixir LSP client
	--   * :ElixirOutputPanel   open the LSP log panel
	--   * Projectionist: :Esource / :Etest / :Etask / :Econtroller /
	--                    :Eview / :Eliveview / :Echannel / :Ecomponent
	--                    / ... -- Phoenix-aware file scaffolding;
	--                    detect-on-demand inside a Mix project.
	--
	-- Configuration lives in lua/hwangfu/lsp/servers/elixirls.lua
	-- (LSP backend choice, ElixirLS settings, on_attach plumbing).
	-- We call that module's setup() from the `config` hook below, so
	-- require("elixir").setup({...}) runs AFTER elixir-tools is on the
	-- runtimepath (the plugin's require() resolves to its own lua/
	-- only after lazy.nvim adds it).
	--
	-- Lazy-loading: this plugin DOES lazy-load (via the `event` field
	-- below), unlike rustaceanvim which forbids it. The elixir-tools
	-- README's own install snippet uses `event = { "BufReadPre",
	-- "BufNewFile" }` so the plugin only loads when a buffer is first
	-- touched, which is correct because elixir-tools attaches its own
	-- autocmds on first elixir-buffer encounter.
	--
	-- IMPORTANT: elixirls is intentionally absent from the SERVERS
	-- table in lua/hwangfu/lsp/init.lua. Calling helpers.define_server
	-- there would race elixir-tools' own LSP setup and either start a
	-- duplicate client or clobber its commands.
	{
		"elixir-tools/elixir-tools.nvim",
		version = "*",
		event = {
			"BufReadPre",
			"BufNewFile",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("hwangfu.lsp.servers.elixirls").setup()
		end,
	},

	-- Haskell IDE wrapper over haskell-language-server (HLS).
	--
	-- Same author and configuration pattern as rustaceanvim
	-- (mrcjkb), so the spec mirrors it: vim.g.haskell_tools is the
	-- config table, set from the `init` hook below so it lands before
	-- the plugin's filetype handler registers itself.
	--
	-- Surfaces HLS extensions and a Hoogle-aware editor layer as
	-- `:Haskell <subcommand>` user commands:
	--   * :Haskell hover           hover with Hoogle / open-docs /
	--                              open-source / find-refs as clickable
	--                              code actions (used as our K override
	--                              in lua/hwangfu/lsp/servers/hls.lua).
	--   * :Haskell hls evalAll     evaluate `-- >>> expr` doctest
	--                              comments in-place; result written
	--                              back into the buffer.
	--   * :Haskell repl toggle     toggle a GHCi terminal scoped to
	--                              the project (or [file] arg).
	--   * :Haskell repl cword_type / cword_info
	--                              GHCi :type / :info of the symbol
	--                              under cursor.
	--   * :Haskell projectFile     open cabal.project / stack.yaml.
	--   * :Haskell definition      LSP go-to-def with Hoogle fallback.
	--   * :Haskell log openHlsLog  direct access to the HLS log file.
	--
	-- Telescope extension is loaded in lua/hwangfu/telescope.lua via
	-- pcall(telescope.load_extension, "ht"), enabling
	-- `:Telescope ht package_files / package_grep / hoogle_signature`.
	--
	-- Pinned to major version 9; semver-major bumps require an
	-- explicit change here. Like rustaceanvim, MUST NOT be lazy-
	-- loaded -- the plugin manages its own filetype-based loading,
	-- and layering lazy.nvim's lazy triggers on top breaks auto-attach.
	--
	-- IMPORTANT: hls is intentionally absent from the SERVERS table
	-- in lua/hwangfu/lsp/init.lua. Calling helpers.define_server
	-- there would race haskell-tools' own LSP setup (the README is
	-- explicit about this conflict).
	{
		"mrcjkb/haskell-tools.nvim",
		version = "^9",
		lazy = false,
		init = function()
			require("hwangfu.lsp.servers.hls").setup()
		end,
	},

	-- Rust IDE wrapper over rust-analyzer.
	--
	-- rustaceanvim owns the rust-analyzer LSP client end-to-end and
	-- surfaces rust-analyzer's custom (non-standard-LSP) protocol
	-- extensions as :RustLsp <verb> commands: expandMacro, explainError,
	-- openDocs, parentModule, runnables, debuggables, syntaxTree,
	-- viewHir, viewMir, moveItem, joinLines, ssr, ...
	--
	-- Configuration lives in lua/hwangfu/lsp/servers/rust_analyzer.lua
	-- (server settings, on_attach, notify filter, :RustFormat). We call
	-- that module's setup() from the `init` hook below so vim.g.
	-- rustaceanvim is populated BEFORE the plugin loads -- the plugin
	-- reads vim.g.rustaceanvim at filetype-handler registration time,
	-- and lazy.nvim's `init` is the only hook guaranteed to fire before
	-- the plugin's own code.
	--
	-- Pinned to major version 9 per the plugin's own install guidance;
	-- semver-major bumps require an explicit change here.
	--
	-- DO NOT add `lazy = true`, `event = ...`, `ft = ...`, or `cmd = ...`:
	-- rustaceanvim's README is explicit that it manages its own lazy
	-- loading via Neovim's filetype plugin layout (lua/plugin/), and
	-- layering lazy.nvim's lazy-load triggers on top of that breaks
	-- the auto-attach to rust buffers.
	--
	-- IMPORTANT: rust_analyzer is intentionally absent from the SERVERS
	-- table in lua/hwangfu/lsp/init.lua. Calling helpers.define_server
	-- there would race rustaceanvim's own vim.lsp.config / vim.lsp.enable
	-- and either start a duplicate client or clobber the runnables and
	-- code-action features.
	{
		"mrcjkb/rustaceanvim",
		version = "^9",
		lazy = false,
		init = function()
			require("hwangfu.lsp.servers.rust_analyzer").setup()
		end,
	},

	-- OCaml editor layer over ocamllsp's custom requests (ocaml.nvim).
	--
	-- First-party plugin from Tarides (the ocaml-lsp / Merlin / dune
	-- maintainers, released 2025-12). Exposes the Merlin features that
	-- standard LSP has no protocol for, as :OCaml* user commands.
	--
	-- OWNERSHIP MODEL - deliberately the OPPOSITE of rustaceanvim /
	-- haskell-tools / elixir-tools: ocaml.nvim does NOT own or start the
	-- LSP client. It layers commands on top of whatever ocamllsp client is
	-- already attached, which is why ocamllsp REMAINS in the SERVERS table
	-- in lua/hwangfu/lsp/init.lua (see lsp/servers/ocamllsp.lua). Do not
	-- "fix" that by removing it - without the native client this plugin
	-- has nothing to talk to.
	--
	-- Command reference (each also has a <localleader> default keymap,
	-- active in OCaml buffers; <localleader> = backslash, set in the root
	-- init.lua):
	--   :OCamlConstruct                \c   fill the typed hole under the
	--                                       cursor from a list of valid
	--                                       substitutions
	--   :OCamlJumpNextHole             \n   jump to the next typed hole
	--   :OCamlJumpPrevHole             \p   jump to the previous hole
	--   :OCamlJump [expr]              \j   syntax-aware jump (fun / let /
	--                                       match / module targets)
	--   :OCamlPhraseNext               \pn  next phrase (top-level item)
	--   :OCamlPhrasePrev               \pp  previous phrase
	--   :OCamlSwitchIntfImpl           \s   switch between .ml and .mli
	--   :OCamlInferIntf                \i   infer the interface for the
	--                                       matching .ml (run from the
	--                                       .mli buffer)
	--   :OCamlTypeEnclosing            \t   type-enclosing session; while
	--                                       active: <Up>/<Down> grow /
	--                                       shrink the enclosing
	--                                       expression, <Right>/<Left>
	--                                       raise / lower type verbosity
	--   :OCamlTypeExpression <expr>         print the type of an arbitrary
	--                                       expression
	--   :OCamlFindIdentifierDefinition/:OCamlFindIdentifierDeclaration/
	--   :OCamlDocumentIdentifier <ident>    definition / declaration /
	--                                       docs of a named identifier
	--   :OCamlSearchDefinition/:OCamlSearchDeclaration <type>
	--                                       type-based search (find
	--                                       functions by signature, e.g.
	--                                       "int -> string")
	--
	-- Note the \p / \pp / \pn prefix overlap: \p waits timeoutlen before
	-- firing. Upstream's default; left as-is to keep docs muscle-memory
	-- valid.
	--
	-- Loaded eagerly (no ft trigger) on purpose: the plugin registers
	-- treesitter parser mappings and filetype detection for .mlx and cram
	-- test files at setup time - gating that behind ft=ocaml would recreate
	-- the netrw chicken-and-egg problem oil.nvim's spec documents. Cost is
	-- one small setup() at startup. Keymaps are left at upstream defaults
	-- (the setup() table mirrors them; empty {} would disable them all).
	{
		"tarides/ocaml.nvim",
		lazy = false,
		config = function()
			require("ocaml").setup()
		end,
	},

	-- ------------------------------------------------------------------
	-- Lisp tooling cluster (2026-08-14). Four plugins, four disjoint
	-- jobs, one language family:
	--   * parinfer-rust        structural editing: parens follow indent
	--   * rainbow-delimiters   depth-colored parens (display only)
	--   * conjure              eval-from-buffer REPL (clojure / fennel /
	--                          racket / scheme)
	--   * slimv                full SLIME environment for Common Lisp
	--                          (sbcl + SWANK: debugger, inspector)
	-- Ownership fences, so they do not fight each other:
	--   * slimv's BUNDLED paredit.vim is disabled (g:paredit_mode = 0):
	--     parinfer is the one structural editor, everywhere.
	--   * slimv's clojure / scheme support is disabled: conjure +
	--     clojure-lsp own clojure; conjure owns scheme. slimv is CL-only.
	--   * conjure is pinned to the four lisp filetypes: upstream would
	--     otherwise also grab python / lua / rust buffers.
	-- ------------------------------------------------------------------

	-- parinfer-rust: parens follow indentation, automatically, on every
	-- edit. No keymaps, no commands in day-to-day use ("smart" mode, the
	-- default). The build step compiles the bundled Rust library with
	-- the system cargo. Active in the plugin's HARDCODED filetype list:
	-- clojure, scheme, lisp, racket, hy, fennel, janet, carp, wast,
	-- yuck - and notably DUNE, so dune stanzas also self-balance (their
	-- final shape still belongs to `dune format-dune-file` on save).
	-- Escape hatches when it misbehaves on weirdly-indented pastes:
	-- :ParinferOff / :ParinferOn, or paste with paren-changes suspended
	-- via g:parinfer_mode = "paren" for the session.
	{
		"eraserhd/parinfer-rust",
		build = "cargo build --release",
	},

	-- rainbow-delimiters: color parens / brackets by nesting depth via
	-- treesitter. Whitelisted to the s-expression filetypes where depth
	-- reading genuinely helps; delete the whitelist to rainbow every
	-- language. Colors only - draws no characters (ASCII rule
	-- untouched). Standalone: talks to vim.treesitter directly, no
	-- coupling to the nvim-treesitter spec.
	--
	-- dune is deliberately NOT whitelisted: no treesitter parser for
	-- dune files exists, so rainbow can never apply there
	-- (:checkhealth rainbow-delimiters flags it as a warning if added).
	-- Debugging note (2026-08-14): the plugin highlights into ANONYMOUS
	-- namespaces (nvim_create_namespace("")), so its extmarks are
	-- invisible to nvim_get_namespaces()-based inspection; look them up
	-- via require("rainbow-delimiters.lib").nsids[lang] instead.
	{
		"HiPhish/rainbow-delimiters.nvim",
		init = function()
			vim.g.rainbow_delimiters = {
				whitelist = {
					"clojure",
					"fennel",
					"racket",
					"scheme",
					"commonlisp",
				},
			}
		end,
	},

	-- conjure: evaluate the code already in the buffer, results shown
	-- inline as virtual text. All maps live under <localleader>
	-- (backslash), buffer-local to its filetypes - the essentials:
	--   \ee   eval expression under cursor    \er   eval root form
	--   \eb   eval whole buffer               \e!   eval and replace
	--   \ew   eval word (inspect a value)     \E    eval visual selection
	--   \ls   open log in split               \lv   log in vsplit
	--   gd    conjure's go-to-definition (falls back to LSP's)
	--   K     conjure doc lookup (shadows LSP hover in its buffers)
	-- Clients per filetype (upstream defaults kept):
	--   clojure -> nREPL: start one per project (e.g. `clj -M:nrepl` or
	--              any editor-nrepl alias); conjure auto-connects via
	--              the .nrepl-port file.
	--   fennel  -> nfnl: compiles + evaluates INSIDE Neovim's Lua - zero
	--              processes. Swap to "conjure.client.fennel.stdio" via
	--              vim.g["conjure#filetype#fennel"] to run standalone
	--              scripts against /usr/bin/fennel semantics instead.
	--   racket / scheme -> stdio REPL processes managed by conjure.
	-- The ft list in vim.g["conjure#filetypes"] (init below) and the
	-- lazy `ft` trigger are deliberately the SAME four entries: lazy
	-- gates the plugin's LOADING, the g: var gates which filetypes
	-- conjure claims once loaded. Without the var, opening a python or
	-- lua buffer after the first lisp buffer would grow conjure maps.
	{
		"Olical/conjure",
		ft = { "clojure", "fennel", "racket", "scheme" },
		init = function()
			vim.g["conjure#filetypes"] = {
				"clojure",
				"fennel",
				"racket",
				"scheme",
			}
		end,
	},

	-- slimv: SLIME for Vim - the full Common Lisp environment against
	-- sbcl over the SWANK protocol (bundled; first eval auto-starts the
	-- swank server in a terminal). Interactive debugger with restarts,
	-- object inspector, compile-in-image workflow. Scoped HARD to
	-- ft=lisp by the init vars below. Requires the python3 provider
	-- (pynvim installed 2026-08-14 exactly for this).
	--
	-- Keymap namespace: ',' (comma) - slimv's own documented default,
	-- kept so its help and tutorials read true. The essentials:
	--   ,c  connect swank    ,e  eval defun     ,b  eval buffer
	--   ,d  eval defun (compile)  ,i  inspect    ,h  describe symbol
	--   ,S  selector         ,g  set package    ,W  interrupt
	-- Full reference: :help slimv-keyboard.
	--
	-- CRITICAL init detail: g:slimv_leader MUST be set explicitly. When
	-- unset, slimv adopts g:mapleader - which is SPACE here - and would
	-- shadow the entire <leader> namespace inside lisp buffers.
	-- MUST load eagerly (lazy = false), not via ft: slimv's ftplugins
	-- honor the standard b:did_ftplugin guard, and with a lazy `ft`
	-- trigger Neovim's own runtime lisp ftplugin has ALREADY set that
	-- flag by the time lazy re-sources slimv's - so slimv would bail on
	-- every buffer. Eager loading puts slimv ahead of $VIMRUNTIME in
	-- normal ftplugin sourcing order, where the guard works as intended.
	{
		"kovisoft/slimv",
		lazy = false,
		init = function()
			-- Comma leader; see the CRITICAL note above.
			vim.g.slimv_leader = ","
			-- parinfer owns structural editing; slimv bundles its own
			-- paredit.vim at plugin/ level (would load globally).
			vim.g.paredit_mode = 0
			-- CL-only: conjure + clojure-lsp own clojure, conjure owns
			-- scheme. These are slimv's own ftplugin guard variables.
			vim.g.slimv_disable_clojure = 1
			vim.g.slimv_disable_scheme = 1
		end,
	},

	-- mason.nvim: in-editor package manager for external tooling binaries.
	--
	-- Scope in THIS config: debug-adapter binaries ONLY (currently codelldb,
	-- pulled in by mason-nvim-dap's ensure_installed - see the nvim-dap spec
	-- below). The LSP servers (rust-analyzer, gopls, HLS, ElixirLS, ...) are
	-- deliberately NOT managed here: each comes from its own language toolchain
	-- (rustup component, `go install`, ghcup, ...), which version-matches the
	-- server to the compiler far better than mason's generic prebuilt binaries.
	--
	-- Declared as its own spec (not merely a dependency of mason-nvim-dap) so
	-- the :Mason / :MasonInstall / :MasonUpdate commands are available on
	-- demand - e.g. `:MasonInstall codelldb` to pre-warm the adapter download
	-- instead of waiting for the first debug session to fetch it. `cmd`
	-- lazy-loads mason the first time any of those commands run; lazy.nvim
	-- merges this spec with the dependency reference below, so codelldb still
	-- auto-installs on first debug even if you never invoke :Mason yourself.
	--
	-- opts = {} is enough: handing lazy.nvim any opts table makes it call
	-- require("mason").setup(opts) on load.
	{
		"mason-org/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall", "MasonLog" },
		opts = {},
	},

	-- nvim-dap: Debug Adapter Protocol client - the debugging counterpart to
	-- the LSP client. Like LSP it speaks a JSON protocol to a separate adapter
	-- process; UNLIKE LSP it does NOT attach on file open. nvim-dap sits fully
	-- idle until a debug session is explicitly started, so this whole stack is
	-- lazy and costs nothing at startup or when opening a buffer.
	--
	-- Lazy-loading: the `keys` below are bare trigger keys (no action). The
	-- first press loads the plugin - which runs `config`, installing the real
	-- F-key mappings in lua/hwangfu/dap.lua - then lazy.nvim re-feeds the
	-- keystroke so the now-live mapping fires. rustaceanvim's :RustLsp debug /
	-- debuggables also load nvim-dap transparently: they call require("dap"),
	-- and lazy.nvim hooks require() for managed plugins, so the stack loads on
	-- demand there too. Hence no `ft` / `event` triggers are needed.
	--
	-- Dependencies (all loaded alongside nvim-dap on first debug):
	--   * nvim-dap-ui (+ nvim-nio)   the scopes / stack / breakpoints / watches
	--                                / REPL panel. Auto-opens on session start
	--                                and closes on exit (listeners in dap.lua).
	--   * nvim-dap-virtual-text      inline variable values rendered next to the
	--                                code during a session.
	--   * mason-nvim-dap (+ mason)   bridges mason <-> nvim-dap. Used ONLY for
	--                                ensure_installed = { "codelldb" } so a
	--                                fresh clone self-provisions the adapter;
	--                                rustaceanvim still OWNS the Rust adapter
	--                                (it auto-detects mason's codelldb), so
	--                                mason-nvim-dap's automatic adapter handlers
	--                                are left off in dap.lua.
	--
	-- All DAP behavior (signs, dap-ui, virtual-text, mason-nvim-dap, keymaps)
	-- lives in lua/hwangfu/dap.lua, invoked from `config` below. This mirrors
	-- how rust_analyzer.lua is invoked from rustaceanvim's `init` hook rather
	-- than from init.lua: the module is wired from its plugin spec, not the
	-- top-level module list, precisely so it stays lazy.
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text",
			{
				"jay-babu/mason-nvim-dap.nvim",
				dependencies = { "mason-org/mason.nvim" },
			},
		},
		keys = {
			"<F5>",
			"<S-F5>",
			"<F6>",
			"<F7>",
			"<F8>",
			"<F9>",
			"<S-F9>",
			"<F10>",
			"<F11>",
			"<S-F11>",
		},
		config = function()
			require("hwangfu.dap").setup()
		end,
	},

	-- crates.nvim: crates.io dependency intelligence for Cargo.toml.
	--
	-- Inline latest-version virtual text, crate / version / feature completion,
	-- hover, and update / upgrade code actions - all scoped to Cargo.toml. It
	-- is complementary to taplo (the general TOML language server): taplo does
	-- schema + formatting, crates.nvim does crates.io-specific version data.
	--
	-- Integration is via crates.nvim's IN-PROCESS language server, NOT its
	-- (deprecated, slated-for-removal) nvim-cmp source. With that, completion
	-- rides blink.cmp's built-in `lsp` source and hover / code actions ride
	-- taplo's existing K / <leader>ca bindings on Cargo.toml, so neither
	-- lua/hwangfu/completion.lua nor the LSP keymaps need changing. See the
	-- long note in lua/hwangfu/crates.lua for the full rationale and the
	-- <leader>c* keymap reference.
	--
	-- tag = "stable" follows the plugin's release-channel guidance (the repo
	-- ships a moving `stable` tag); `event = "BufRead Cargo.toml"` keeps it off
	-- the startup path until a manifest is actually opened. All behavior lives
	-- in lua/hwangfu/crates.lua, invoked from `config` (same lazy-from-spec
	-- pattern as dap.lua / rust_analyzer.lua).
	{
		"saecki/crates.nvim",
		tag = "stable",
		event = { "BufRead Cargo.toml" },
		config = function()
			require("hwangfu.crates").setup()
		end,
	},

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
