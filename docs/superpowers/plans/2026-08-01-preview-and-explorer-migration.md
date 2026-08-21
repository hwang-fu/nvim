# Preview + Explorer Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace unmaintained markdown-preview.nvim with the already-installed live-preview.nvim, and replace nerdtree with oil.nvim, per the approved spec at `docs/superpowers/specs/2026-08-01-preview-and-explorer-migration-design.md`.

**Architecture:** All plugin specs live in `lua/jwa/plugins.lua`; global keymaps in `lua/jwa/keymap.lua`; editor options in `lua/jwa/init.lua`; per-filetype colorschemes in `lua/jwa/colors.lua`. Buffer-local plugin keymaps stay in the plugin's spec (gitsigns pattern). Behavior config for the two new/changed plugins is small enough to stay inline in their specs.

**Tech Stack:** Neovim >= 0.10, lazy.nvim, live-preview.nvim (brianhuster), oil.nvim (stevearc).

## Global Constraints

- ASCII only in every config file: no box-drawing, em-dashes, smart quotes, or arrows. Verify with the grep in each task.
- Indentation is PER-FILE: `plugins.lua`, `init.lua`, `colors.lua` use TABS; `keymap.lua`, `telescope.lua` use 4 SPACES. Never run stylua.
- `/home/hwangfu/.config/nvim` is NOT a git repository: there are no commit steps. Each task ends with a parse-check instead.
- Comments are load-bearing documentation in this config ("organize, not shrink"): removed plugins get a dated removal note; new specs get full keymap/rationale comments.
- The config call for live-preview MUST be `require("livepreview.config").set(...)` - the `require("live-preview")` module and its `setup()` are deprecated upstream shims.
- Parse-check command used by every task:
  `nvim --clean --headless -c "lua assert(loadfile('<FILE>'))" -c q`

---

### Task 1: plugins.lua - retire markdown-preview.nvim, expand live-preview.nvim

**Files:**
- Modify: `lua/jwa/plugins.lua` (mkdp spec block; live-preview stanza; two comment lines in the render-markdown spec)

**Interfaces:**
- Produces: `<leader>mp` / `<leader>ms` / `<leader>mt` mapped to `:LivePreview start|close|pick` via lazy `keys`. Task 3 updates keymap.lua's header to reference these.

- [ ] **Step 1: Delete the entire markdown-preview.nvim spec**

Remove the whole block from `-- Browser preview (GitHub-like).` down to (and including) the closing `},` of the `iamcco/markdown-preview.nvim` spec - the spec starting `"iamcco/markdown-preview.nvim"` with its `build`, `ft`, and the full `init = function()` containing every `vim.g.mkdp_*` line, the Newsprint CSS commentary, and the three `<leader>m*` keymaps. Do NOT delete anything from the render-markdown spec that follows it.

- [ ] **Step 2: Replace the live-preview stanza with the expanded spec**

Replace exactly this (TAB-indented):

```lua
	-- HTML / general live preview in browser.
	-- Automatically uses 127.0.0.1:5500
	-- :LivePreview start
	{
		"brianhuster/live-preview.nvim",
		config = function()
			require("live-preview").setup({})
			-- no keymaps
		end,
	},
```

with (TAB-indented):

```lua
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
```

- [ ] **Step 3: Update the render-markdown spec's two stale references**

Replace:

```lua
	-- checkboxes, block quotes and callouts. This is the in-editor
	-- counterpart to the two BROWSER previewers above: markdown-preview.nvim
	-- and live-preview.nvim both open an external window, whereas this one
	-- restyles the text you are already looking at -- no browser, no second
	-- process, scrolls with the buffer.
```

with:

```lua
	-- checkboxes, block quotes and callouts. This is the in-editor
	-- counterpart to the BROWSER previewer above: live-preview.nvim opens
	-- an external window, whereas this one restyles the text you are
	-- already looking at -- no browser, no second process, scrolls with
	-- the buffer.
```

And replace:

```lua
	-- The keymap sits in the <leader>m* "markdown" namespace beside the
	-- markdown-preview keys (mp / ms / mt) and does not collide with any
```

with:

```lua
	-- The keymap sits in the <leader>m* "markdown" namespace beside the
	-- live-preview keys (mp / ms / mt) and does not collide with any
```

- [ ] **Step 4: Verify**

Run: `nvim --clean --headless -c "lua assert(loadfile('/home/hwangfu/.config/nvim/lua/jwa/plugins.lua'))" -c q`
Expected: no output (parse OK).

Run: `grep -n "mkdp\|markdown-preview\|iamcco" /home/hwangfu/.config/nvim/lua/jwa/plugins.lua`
Expected: matches ONLY inside the new live-preview comment (the archive note naming mkdp/newsprint.css and the "Replaced iamcco/markdown-preview.nvim" line). No `vim.g.mkdp_*` code lines.

Run: `grep -nP '[^\x00-\x7F]' /home/hwangfu/.config/nvim/lua/jwa/plugins.lua`
Expected: no output (ASCII only).

---

### Task 2: plugins.lua - replace nerdtree with oil.nvim

**Files:**
- Modify: `lua/jwa/plugins.lua` (the `-- File explorer.` + `"preservim/nerdtree",` lines)

**Interfaces:**
- Produces: `require("oil").open()` / `require("oil").close()` available from startup (`lazy = false`), oil buffers with filetype `oil`. Task 3's `<C-t>` map and Task 4's colors.lua pattern depend on these.

- [ ] **Step 1: Replace the nerdtree entry with the oil.nvim spec**

Replace exactly (TAB-indented):

```lua
	-- File explorer.
	"preservim/nerdtree",
```

with (TAB-indented):

```lua
	-- File explorer (oil.nvim): edit the filesystem like a buffer.
	--
	-- Replaced preservim/nerdtree (2026-08). Instead of a sidebar tree,
	-- oil opens a directory LISTING as a normal editable buffer: create
	-- files by adding lines, rename by editing a name, delete with dd --
	-- then :w (or the global <C-s>, which is :w) applies the pending
	-- operations after a confirmation prompt. Deletions are PERMANENT:
	-- delete_to_trash stays at its default false by explicit choice, so
	-- dd + :w removes the file for real, no freedesktop trash.
	--
	-- Keys inside an oil buffer (defaults unless marked custom):
	--   <CR>   open entry
	--   -      go up one directory
	--   ..     go up one directory (custom alias for `-`, shell muscle
	--          memory carried over from the old NERDTree map; cost: `.`
	--          repeat waits timeoutlen inside oil buffers only)
	--   <C-t>  close the listing (custom override; oil's default <C-t>
	--          is open-in-new-tab, which would shadow the global <C-t>
	--          toggle from keymap.lua inside oil buffers)
	--   <C-s>  save, i.e. apply pending operations (custom: oil's default
	--          <C-s> vsplit binding is disabled with `false` so the global
	--          <C-s> :w map shows through - :w is how oil applies edits)
	--   g.     toggle hidden files (hidden by default, matching the old
	--          nerdtree setup, which never enabled NERDTreeShowHidden)
	--   g?     help listing every oil binding
	--
	-- The global <C-t> toggle (open oil at the current buffer's directory
	-- / close it) lives in lua/jwa/keymap.lua with the other global
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
					["<C-t>"] = "actions.close",
					["<C-s>"] = false,
					[".."] = "actions.parent",
				},
			})
		end,
	},
```

- [ ] **Step 2: Verify**

Run: `nvim --clean --headless -c "lua assert(loadfile('/home/hwangfu/.config/nvim/lua/jwa/plugins.lua'))" -c q`
Expected: no output.

Run: `grep -n "nerdtree\|NERDTree" /home/hwangfu/.config/nvim/lua/jwa/plugins.lua`
Expected: matches only inside the new oil comment (the removal note and NERDTreeShowHidden reference).

Run: `grep -nP '[^\x00-\x7F]' /home/hwangfu/.config/nvim/lua/jwa/plugins.lua`
Expected: no output.

---

### Task 3: keymap.lua - oil toggle replaces the NERDTree block

**Files:**
- Modify: `lua/jwa/keymap.lua` (header lines ~22 and ~30-31; the NERDTree section ~lines 408-483)

**Interfaces:**
- Consumes: `require("oil").open()` / `require("oil").close()` and filetype `oil` from Task 2.

- [ ] **Step 1: Update the header quick-reference**

Replace (4-space indent context, inside the top comment):

```lua
--   * NERDTree          - Ctrl-T toggle (at buffer's dir); `..` goes up
```

with:

```lua
--   * Oil explorer      - Ctrl-T toggle (at buffer's dir); `..` goes up
```

And replace:

```lua
--   * Markdown preview  - <leader>mp / <leader>ms / <leader>mt
--                         (markdown-preview.nvim spec)
```

with:

```lua
--   * Browser preview   - <leader>mp start / ms close / mt pick
--                         (live-preview.nvim spec)
```

- [ ] **Step 2: Replace the NERDTree section**

Replace the entire block from `-- --- NERDTree -------------------------------------------------------` through the end of the `JwaNerdtree` autocmd (the line `    })` that closes `vim.api.nvim_create_autocmd("FileType", {...})`, just before the `-- --- Buffers` section) with (4-SPACE indented):

```lua
    -- --- Oil (file explorer) --------------------------------------------
    -- <C-t> toggles an oil listing at the *current buffer's* directory.
    --
    -- oil.open() with no argument already resolves to the directory of
    -- the current buffer (falling back to cwd for unnamed buffers). That
    -- is exactly the re-root-on-every-press behavior the old NERDTree
    -- wrapper here implemented by hand: after jumping (gd, telescope,
    -- ...) into a file somewhere else on disk, <C-t> shows THAT file's
    -- directory, not where nvim was launched.
    --   * If the current buffer IS an oil listing -> close it, returning
    --     to the buffer that was showing before.
    --   * Otherwise -> open the buffer's directory as an oil listing.
    --
    -- Side-effect free: does NOT change Neovim's :cwd, so plugins keyed
    -- off cwd (lazy, telescope's default scope, etc.) keep behaving the
    -- same. If you also want :cwd to follow, see `:h 'autochdir'`.
    --
    -- Buffer-local keys inside oil listings (`..` up-dir alias, <C-t>
    -- close override, <C-s> passthrough to save) are configured in oil's
    -- spec in lua/jwa/plugins.lua, next to the plugin they belong to
    -- -- the same split used for the gitsigns hunk maps.
    map("n", "<C-t>", function()
        if vim.bo.filetype == "oil" then
            require("oil").close()
        else
            require("oil").open()
        end
    end, {
        silent = true,
        desc = "Toggle oil file explorer at current buffer's directory",
    })
```

- [ ] **Step 3: Verify**

Run: `nvim --clean --headless -c "lua assert(loadfile('/home/hwangfu/.config/nvim/lua/jwa/keymap.lua'))" -c q`
Expected: no output.

Run: `grep -n "nerdtree\|NERDTree" /home/hwangfu/.config/nvim/lua/jwa/keymap.lua`
Expected: at most the single historical mention inside the new oil comment ("the old NERDTree wrapper"). No live code references.

Run: `grep -nP '[^\x00-\x7F]' /home/hwangfu/.config/nvim/lua/jwa/keymap.lua`
Expected: no output.

---

### Task 4: init.lua, colors.lua, telescope.lua - remaining touchpoints

**Files:**
- Modify: `lua/jwa/init.lua` (header line ~14, ToggleWS comment ~106, section 5 ~130-133) - TABS
- Modify: `lua/jwa/colors.lua` (group (b) pattern entry "nerdtree") - TABS
- Modify: `lua/jwa/telescope.lua` (header comment lines 6-7) - 4 SPACES (comment at column 0)

**Interfaces:**
- Consumes: filetype `oil` from Task 2.

- [ ] **Step 1: init.lua header list entry**

Replace:

```lua
--   5.  Plugin-side knobs     - vim.g.* tweaks for plugins (NERDTree)
```

with:

```lua
--   5.  Plugin-side knobs     - vim.g.* tweaks for plugins (none today)
```

- [ ] **Step 2: init.lua ToggleWS comment**

Replace:

```lua
	-- :ToggleWS - flip whitespace visibility for the current window.
	-- Scoped to the window (not global) so you can have, say, your code
	-- buffer with whitespace shown and a NERDTree pane with it off.
```

with:

```lua
	-- :ToggleWS - flip whitespace visibility for the current window.
	-- Scoped to the window (not global) so you can have, say, your code
	-- buffer with whitespace shown and an oil listing with it off.
```

- [ ] **Step 3: init.lua section 5 body**

Replace (TAB-indented):

```lua
	-- ------------------------------------------------------------------------
	-- 5. Plugin-side knobs
	-- ------------------------------------------------------------------------
	vim.g.NERDTreeWinSize = 23 -- narrower NERDTree pane than default 31
```

with:

```lua
	-- ------------------------------------------------------------------------
	-- 5. Plugin-side knobs
	-- ------------------------------------------------------------------------
	-- (Empty since 2026-08. vim.g.NERDTreeWinSize lived here until nerdtree
	-- was replaced by oil.nvim; oil uses the full window, so there is no
	-- pane-width knob. Plugin behavior is configured in each plugin's spec
	-- in lua/jwa/plugins.lua; the section is kept for future vim.g.*
	-- knobs that must be set before a plugin loads.)
```

- [ ] **Step 4: colors.lua filetype pattern**

In the group (b) pattern list, replace the entry:

```lua
			"nerdtree",
```

with:

```lua
			"oil",
```

- [ ] **Step 5: telescope.lua header comment**

Replace:

```lua
-- This is search-first file navigation, as opposed to NERDTree's
-- browse-the-sidebar style; the two can happily coexist.
```

with:

```lua
-- This is search-first file navigation, as opposed to oil.nvim's
-- browse-the-directory style; the two can happily coexist.
```

- [ ] **Step 6: Verify**

Run: `nvim --clean --headless -c "lua assert(loadfile('/home/hwangfu/.config/nvim/lua/jwa/init.lua')); assert(loadfile('/home/hwangfu/.config/nvim/lua/jwa/colors.lua')); assert(loadfile('/home/hwangfu/.config/nvim/lua/jwa/telescope.lua'))" -c q`
Expected: no output.

Run: `grep -rn "nerdtree\|NERDTree" /home/hwangfu/.config/nvim/lua/ /home/hwangfu/.config/nvim/init.lua`
Expected: only historical-note mentions inside comments added by Tasks 2-4 (plugins.lua oil spec, keymap.lua oil block, init.lua section-5 note). Zero live code references.

Run: `grep -rnP '[^\x00-\x7F]' /home/hwangfu/.config/nvim/lua/`
Expected: no output.

---

### Task 5: Sync plugins and smoke-test

**Files:**
- None modified. Runs lazy.nvim sync and headless startup.

**Interfaces:**
- Consumes: everything from Tasks 1-4.

- [ ] **Step 1: Sync the plugin set**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5`
Expected: completes without error lines; oil.nvim installed; markdown-preview.nvim, nerdtree, minimal.nvim, vim-colors-github removed (the last two from the earlier cleanup).

- [ ] **Step 2: Startup smoke test**

Run: `nvim --headless -c "lua print('startup OK')" -c q 2>&1`
Expected: output contains `startup OK` and no error/stack-trace lines.

- [ ] **Step 3: Confirm oil and live-preview are reachable**

Run: `nvim --headless -c "lua require('oil'); print(vim.fn.exists(':LivePreview') > 0 and 'cmds OK' or 'MISSING :LivePreview')" -c q 2>&1`
Expected: `cmds OK` (the :LivePreview stub exists via lazy's cmd trigger; require('oil') loads because lazy = false).

- [ ] **Step 4: Hand the user the manual checklist**

Manual verification only a human with a browser can do:
1. Open a markdown file, press `<leader>mp` - browser opens 127.0.0.1:5500 with GitHub-styled preview; scrolling nvim scrolls the browser.
2. `<leader>mt` - telescope picker of previewable files appears.
3. `<leader>ms` - server stops.
4. In a code buffer, `<C-t>` - oil listing of that file's directory appears; `..` and `-` both go up; `<C-t>` again closes back to the file.
5. In an oil listing of a scratch dir: create a line `test.txt`, `:w`, confirm - file exists. `dd` on it, `:w`, confirm - file is permanently gone.
6. `g.` toggles dotfiles.
