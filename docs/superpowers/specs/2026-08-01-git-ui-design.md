# Git UI Design: lazygit float + diffview.nvim

Date: 2026-08-01
Status: approved by user (all sections)

## Background

The config's git tooling was gitsigns.nvim only (hunks, blame, buffer-level
diffs) plus lualine's branch/diff components. User goals from brainstorming:
full git UI, diff & history browsing, terminal-tool integration. lazygit and
tig are installed system-wide (also delta); user chose lazygit-in-a-float as
the porcelain (covers both the "full git UI" and "terminal tool" goals) and
diffview.nvim for in-editor diff/history.

Upstream health, checked 2026-08-01:
* sindrets/diffview.nvim - NOT archived, but dormant: last push 2024-08-02,
  5.7k stars. Adopted DELIBERATELY: feature-complete, largest install base
  in its niche, no maintained equivalent. The dormancy must be documented
  in the spec comment; revisit if a future Neovim release breaks it.
* Hand-rolled float means no lazygit plugin dependency at all.

gitsigns.nvim stays exactly as configured.

## Section A: lua/hwangfu/git.lua - lazygit float, no plugin

New module, 4-SPACE indent (keymap.lua convention), wired from root
init.lua as require("hwangfu.git").setup().

Behavior:
* M.setup() registers ONE global keymap: <leader>gg -> open lazygit in a
  floating terminal. This opens the <leader>g* "git UI" namespace
  (previously unused; gitsigns hunks stay on <leader>h*).
* Float: scratch buffer (nofile, unlisted) + nvim_open_win, relative =
  "editor", centered, width/height = 90% of columns/lines (user approved
  90%), border = "rounded", then vim.fn.jobstart({ "lazygit" },
  { term = true, on_exit = close-window-and-wipe-buffer }) and
  vim.cmd.startinsert(). jobstart+term is the Neovim 0.11 replacement for
  the deprecated termopen().
* Git-root guard: before opening, resolve vim.fs.root(0, ".git") falling
  back to vim.fs.root(vim.fn.getcwd(), ".git"); if nil, vim.notify an
  error ("not inside a git repository") and do NOT launch - lazygit
  outside a repo offers to git-init, which a stray keypress must not
  reach.
* on_exit closes the float window (if still valid) and deletes the buffer,
  so lazygit's own q collapses everything. No autocmds needed beyond what
  jobstart's on_exit provides.
* gitsigns refresh needs no plumbing: it watches the git dir and updates
  gutters/statusline after commits or staging done inside lazygit.
* Module header documents: what it is, why no plugin (native APIs match
  the config's style - native LSP config, built-in commenting), the
  keymap, and the guard rationale.

## Section B: diffview.nvim spec (lua/hwangfu/plugins.lua, TABS)

* Spec: "sindrets/diffview.nvim", lazy-loaded via cmd = { "DiffviewOpen",
  "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles",
  "DiffviewFocusFiles", "DiffviewRefresh", "DiffviewLog" } and keys:
  - <leader>gd  <cmd>DiffviewOpen<CR>            diff working tree vs HEAD
  - <leader>gh  <cmd>DiffviewFileHistory %<CR>   history: current file
  - <leader>gH  <cmd>DiffviewFileHistory<CR>     history: whole repo
* config = function() require("diffview").setup({}) end - all defaults
  (defaults include use_icons = true; nvim-web-devicons is already
  installed via lualine/oil, so icons work without a new dependency).
* Spec comment in house style: what it does, keymap quick reference
  (including in-view keys: <Tab>/<S-Tab> cycle files, q or :DiffviewClose
  to leave, g? for the plugin's own help), relationship to gitsigns
  (hunks/blame stay gitsigns; diffview is for whole-changeset and history
  views) and to <leader>gg (lazygit acts, diffview inspects), AND the
  dormancy adoption note: "Adopted 2026-08 with upstream dormant since
  2024-08 (not archived, feature-complete, no maintained equivalent).
  If a future Neovim version breaks it, replace or drop rather than
  patch."

## Section C: housekeeping

* Root init.lua: add module-list line for git ("git - lazygit float
  keymap") and require("hwangfu.git").setup() next to keymap's call
  (order does not matter for it; after keymap keeps the list tidy).
* keymap.lua header "NOT in this file" index: add a Git UI entry:
  <leader>gg lazygit float (lua/hwangfu/git.lua); <leader>gd / gh / gH
  diffview (plugin spec keys).
* gitsigns spec comment: one-line cross-reference near the top pointing
  at <leader>g* for repo-level git UI (lazygit / diffview), so the two
  namespaces explain each other.

## Error handling

* Git-root guard covers the only silent-failure path (module A).
* No pcall around diffview's setup - failures surface loudly, config
  style.
* Float on_exit checks nvim_win_is_valid / nvim_buf_is_valid before
  closing (the user may have closed the window manually).

## Verification

1. Parse-check every edited/created lua file.
2. nvim --headless "+Lazy! sync" +qa - diffview.nvim installed, exit 0.
3. Headless startup smoke test - no errors.
4. Headless: require("hwangfu.git") loads; vim.fn.maparg("<leader>gg",
   "n") is non-empty after setup.
5. Scratch git repo in the session scratchpad: headless nvim inside it
   runs :DiffviewOpen then :DiffviewClose without error output (proves
   the lazy cmd trigger and the plugin's runtime work).
6. Manual (user): <leader>gg floats lazygit; q collapses it; a commit
   made in lazygit updates gitsigns gutters; <leader>gg outside any repo
   notifies instead of launching; <leader>gd / <leader>gh / <leader>gH
   open diffview views; q leaves them.

## Out of scope

* tig integration (lazygit covers the porcelain; add a second float
  keymap later if wanted - the float helper is written to make that a
  two-line addition).
* Any gitsigns changes.
* delta integration (terminal pager; not used by diffview or gitsigns).
