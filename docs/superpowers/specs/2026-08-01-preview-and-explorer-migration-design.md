# Preview + Explorer Migration Design

Date: 2026-08-01
Status: approved by user (Section A approved as-is; Section B approved with
delete_to_trash left at oil's default false, i.e. hard deletes)

## Background

Plugin audit (2026-08-01) findings driving this design:

* iamcco/markdown-preview.nvim is effectively unmaintained (last push
  2024-07, 264 open issues). brianhuster/live-preview.nvim is already
  installed, actively maintained, and covers markdown + HTML + asciidoc +
  SVG.
* preservim/nerdtree is maintained but vimscript-era; user chose to migrate
  to a Lua explorer. oil.nvim (directory-as-editable-buffer) was selected
  over nvim-tree/neo-tree because it matches the existing navigate-up
  workflow (open at buffer's dir, walk up with "..").

Constraint discovered during exploration: live-preview.nvim hardcodes
GitHub-style CSS for markdown (template.lua) with no custom-CSS hook. The
user accepted losing the custom Newsprint look in exchange for a fully
supported, zero-maintenance setup. mkdp/newsprint.css is archived in place.

## Section A: consolidate browser preview on live-preview.nvim

plugins.lua changes:

1. Delete the entire iamcco/markdown-preview.nvim spec (build hook, ft
   trigger, all vim.g.mkdp_* knobs, its <leader>m* keymaps, and the long
   Newsprint CSS commentary).
2. Expand the brianhuster/live-preview.nvim spec:
   * Lazy-load: cmd = "LivePreview" plus keys for the three <leader>m*
     maps below (currently the plugin loads eagerly at startup).
   * Config: require("livepreview.config").set({ picker = "telescope" }).
     This replaces require("live-preview").setup({}) - BOTH the module
     name "live-preview" and setup() are deprecated upstream.
   * Settings kept at defaults, deliberately: port = 5500,
     sync_scroll = true, dynamic_root = false (server root = cwd),
     browser = "default", address = "127.0.0.1". The only non-default is
     picker = "telescope" (explicit beats auto-detect; telescope is the
     only picker installed).
   * Keymaps (semantics change vs mkdp):
     - <leader>mp  :LivePreview start   (any supported filetype, not just
                                         markdown)
     - <leader>ms  :LivePreview close   (was MarkdownPreviewStop)
     - <leader>mt  :LivePreview pick    (was toggle; live-preview has no
                                         toggle - pick opens a telescope
                                         picker of previewable files)
3. Newsprint archive: mkdp/newsprint.css stays on disk untouched. The
   live-preview spec comment notes it is the archived mkdp-era stylesheet
   (fonts still installed user-wide) recoverable later via a fork or a
   browser-side user-CSS.
4. render-markdown.nvim spec comment: rewrite the "two BROWSER previewers"
   reference to name live-preview.nvim alone. No behavior change.

## Section B: replace nerdtree with oil.nvim

plugins.lua changes:

1. Remove "preservim/nerdtree".
2. Add stevearc/oil.nvim:
   * lazy = false - oil must own directory buffers from startup (it
     replaces netrw, so `nvim some/dir/` opens oil).
   * dependencies = { "nvim-tree/nvim-web-devicons" }.
   * Inline config (gitsigns pattern) calling require("oil").setup with:
     - default_file_explorer = true (oil's default, stated explicitly).
     - delete_to_trash left at default false per user decision: dd + :w
       permanently removes files (no freedesktop trash).
     - keymaps overrides, all buffer-local to oil buffers:
       ["<C-t>"] = "actions.close"  (default opens-in-tab; close restores
                                     toggle symmetry with the global map)
       ["<C-s>"] = false            (default vsplit would shadow the
                                     global <C-s> save; :w is how oil
                                     applies pending file operations)
       [".."]    = "actions.parent" (muscle-memory alias beside oil's
                                     native "-"; cost: "." repeat inside
                                     oil buffers waits timeoutlen)
     - Hidden files stay hidden by default; g. toggles (matches old
       nerdtree behavior, which never set NERDTreeShowHidden).

keymap.lua changes:

* Replace the NERDTree block (nerdtree_at_buffer helper, HwangfuNerdtree
  augroup with the buffer-local ".." map) with:
  - <C-t> global map: if current buffer filetype is "oil" then
    require("oil").close() else require("oil").open() - open() with no
    args shows the current buffer's directory, preserving the old
    rooted-at-buffer semantics.
* Update the file-header keymap quick-reference (line ~22) accordingly.

init.lua changes:

* Remove vim.g.NERDTreeWinSize = 23 and both NERDTree comment mentions
  (section-5 header list and the listchars note). Oil uses the full
  window; there is no sidebar width concept.

colors.lua changes:

* Group (b) FileType pattern: "nerdtree" -> "oil".

telescope.lua changes:

* Comment only: "as opposed to NERDTree's" -> reference oil.nvim.

## Error handling

* Both config() hooks rely on lazy.nvim install; no pcall wrappers are
  added, matching the config's existing style (a broken plugin surfaces
  loudly at startup rather than failing silently).
* The <C-t> map requires oil to be loaded; with lazy = false it always is.

## Verification

1. Parse-check every edited lua file (loadfile via headless nvim).
2. Headless `nvim --headless "+Lazy! sync" +qa` to install oil.nvim and
   remove the deleted plugins; confirm clean exit.
3. Headless startup smoke test: no error output on `nvim --headless +q`.
4. ASCII-only re-check on all edited files.
5. Manual (user): open a markdown file, <leader>mp, confirm browser
   preview with GitHub styling and sync scroll; <C-t> in a code buffer,
   confirm oil opens at the buffer's dir, ".." and "-" go up, <C-t>
   closes; dd + :w deletes a scratch file (permanently); `g.` toggles
   dotfiles.

## Out of scope

* nvim-cmp -> blink.cmp migration (deferred; user asked to be informed in
  a later session).
* Any restyling of live-preview's markdown output (fork / Stylus paths
  documented in the archive note only).
