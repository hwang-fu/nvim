# nvim-cmp to blink.cmp Migration Design

Date: 2026-08-01
Status: approved by user (all sections; docs delay 200ms accepted)

## Background

Deferred from the 2026-08-01 plugin audit; user asked to revisit and chose
to proceed. Fresh status checked the same day:

* hrsh7th/nvim-cmp: not archived, last push 2026-07-09, 301 open issues -
  maintenance mode, not active development.
* saghen/blink.cmp: last push 2026-07-31, 97 open issues, stable v1.x
  releases (v1.10.2). Prebuilt Rust fuzzy-matcher binary with Lua fallback.

Findings that shrink the migration:

* cmp-cmdline was installed but NEVER configured - no cmp.setup.cmdline()
  call exists; ":"/"/" completion has been native wildmenu all along. The
  plugins.lua comment claiming otherwise is drift.
* LuaSnip + cmp_luasnip exist only to satisfy nvim-cmp's snippet-engine
  requirement; no custom snippets are defined. User chose to DROP both -
  LSP snippet items expand via Neovim's built-in vim.snippet under blink.
* LSP capabilities flow through ONE function: helpers.make_capabilities()
  (lua/hwangfu/lsp/helpers.lua). All servers - define_server users plus
  rustaceanvim / HLS / clangd - inherit from it.
* crates.nvim completion rides its in-process LSP server; blink's lsp
  source picks it up with no changes.

User decisions: migrate now; drop LuaSnip; ENABLE blink's built-in cmdline
completion (finishing what installing cmp-cmdline intended); docs popup
auto-shows at 200ms.

## Section A: plugin swap (lua/hwangfu/plugins.lua)

Remove seven specs, replaced by a dated removal note in the completion
section: hrsh7th/nvim-cmp, hrsh7th/cmp-nvim-lsp, hrsh7th/cmp-buffer,
hrsh7th/cmp-path, hrsh7th/cmp-cmdline (note: was never wired up),
L3MON4D3/LuaSnip, saadparwaiz1/cmp_luasnip.

Add one spec:

* "saghen/blink.cmp" with version = "1.*" - lazy.nvim tracks stable
  releases and downloads the prebuilt Rust fuzzy-matcher binary from the
  matching GitHub release (no cargo). fuzzy.implementation stays at its
  default "prefer_rust_with_warning": if the binary is missing, blink
  falls back to the Lua matcher and warns.
* BARE spec (no config hook, no lazy-load triggers) - the completion
  module is wired from the root init.lua exactly like nvim-cmp was
  (plugins first, then completion, then lsp). This follows the existing
  architecture: eagerly-loaded core modules are called from the root
  init.lua; only genuinely lazy plugins (dap, crates) configure from
  their spec hooks.

## Section B: module rewrite (cmp.lua -> completion.lua)

Rename lua/hwangfu/cmp.lua to lua/hwangfu/completion.lua. The old name
described the plugin (cmp); the new one describes the role and survives
engine swaps. Root init.lua line 52: require("hwangfu.cmp").setup()
becomes require("hwangfu.completion").setup() - the single call path,
kept in the root exactly as before (see Section A).

Root init.lua comment updates (verified stale on 2026-08-01):
* Line 8: module list says "cmp - completion engine (nvim-cmp)" ->
  "completion - completion engine (blink.cmp)".
* Lines 26-28: leader-key rationale still credits markdown-preview's
  <leader>m* maps (removed earlier today); reword to cite lazy.nvim
  init/keys hooks generically with live-preview as the example.
* Lines 41-45: module-ordering rationale names cmp_nvim_lsp; reword for
  blink.cmp (lsp's make_capabilities() pcalls require("blink.cmp")).

require("blink.cmp").setup({...}) with keybinding PARITY as the rule:

* keymap = { preset = "none", explicit maps }:
  - <Down> / <Up>      { "select_next", "fallback" } / { "select_prev", "fallback" }
  - <C-n> / <C-p>      same as Down / Up
  - <C-Space>          { "show", "fallback" }  (open menu on demand)
  - <CR>               { "accept", "fallback" } (first item if none selected,
                       matching the old select = true)
  - <C-f> / <C-b>      { "scroll_documentation_down", "fallback" } /
                       { "scroll_documentation_up", "fallback" }
  - <Esc>              { "cancel", "fallback" } - menu open: close it and
                       STAY in insert (old cmp abort behavior); menu
                       closed: normal Esc leaves insert.
* completion.list.selection = { preselect = true, auto_insert = false } -
  parity with completeopt "menu,menuone,noinsert" + confirm-first-item.
* completion.documentation = { auto_show = true, auto_show_delay_ms = 200 }
  - nvim-cmp showed docs automatically; blink needs auto_show opted in.
  200ms accepted by user (0 = instant, 500 = blink default, if revisited).
* sources.default = { "lsp", "path", "buffer" }:
  - No "snippets" source (LuaSnip dropped; nothing to serve). LSP snippet
    ITEMS still arrive via the lsp source and expand through vim.snippet.
  - blink's default lsp source config already lists buffer as a fallback
    (buffer items only when LSP returns none) - this IS the old two-group
    behavior; keep the default and document it.
  - Accepted minor shift: path is a primary source rather than fallback;
    it only fires on path-like tokens.
* cmdline = { enabled = true } (explicit), default cmdline keymap preset
  (Tab / arrows - close to native muscle memory). This is NEW user-facing
  behavior, chosen deliberately.
* Header comment: rewrite the COMPLETION MENU keybinding reference for
  blink (same keys, plus cmdline popup); KEEP the LSP CODE HELPERS
  section unchanged - it documents lsp/init.lua mappings, not cmp.
* File uses TABS (inherited from cmp.lua; keep).

## Section C: capabilities swap + comment sweep

lua/hwangfu/lsp/helpers.lua make_capabilities():

* Replace the pcall require("cmp_nvim_lsp") +
  cmp.default_capabilities(caps) with pcall require("blink.cmp") +
  blink.get_lsp_capabilities(caps). Keep the pcall (fresh-machine
  bootstrap ordering) and the vim.lsp.protocol.make_client_capabilities()
  base. Update the function's comment and the file-header mention of
  "cmp-augmented capabilities".
* clangd.lua layers its own snippet-capability tweak on top of
  make_capabilities(); it composes unchanged - verify, don't modify.

Comment sweep for stale references to nvim-cmp / cmp.lua / cmp sources:

* plugins.lua crates.nvim spec comment (mentions the deprecated nvim-cmp
  source and "{ name = "nvim_lsp" } source in cmp.lua").
* lua/hwangfu/crates.lua long note (same topic).
* Any other grep hits for "nvim-cmp", "nvim_lsp", "cmp.lua", "cmp_luasnip",
  "LuaSnip" in comments across lua/hwangfu/ - update to name blink.cmp's
  lsp source or the completion.lua module as appropriate. Code references
  must be zero after Sections A-C.

## Error handling

* make_capabilities keeps its pcall guard so a half-installed fresh clone
  still boots.
* No pcall around blink's setup - a broken completion engine should fail
  loudly at startup, matching config style.

## Verification

1. Parse-check every edited file (loadfile via headless nvim).
2. nvim --headless "+Lazy! sync" +qa - seven plugins removed, blink.cmp
   installed (release checkout + fuzzy binary download).
3. Headless startup smoke test (no error output).
4. Headless: require("blink.cmp") loads; vim.lsp capabilities from
   helpers.make_capabilities() contain completionItem.snippetSupport =
   true (proves blink augmentation ran).
5. grep: zero live code references to cmp/luasnip modules.
6. Manual (user): insert-mode popup + <CR>/<C-Space>/<C-f> docs scroll in
   a Rust file; <Esc> closes menu staying in insert; ":" and "/" popup
   completion; crates.nvim version completion inside a Cargo.toml.

## Out of scope

* Custom snippet definitions (re-add later via blink snippets.preset =
  "luasnip" if ever wanted).
* Any tuning of blink's menu appearance / ghost text / signature help
  (all stay at blink defaults; revisit after daily use).
