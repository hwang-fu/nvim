# blink.cmp Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the seven-plugin nvim-cmp stack with blink.cmp per the approved spec at `docs/superpowers/specs/2026-08-01-blink-cmp-migration-design.md`.

**Architecture:** Bare blink.cmp spec in `lua/hwangfu/plugins.lua`; behavior in a new `lua/hwangfu/completion.lua` module (renamed from `cmp.lua`) called from the root `init.lua` in plugins -> completion -> lsp order. LSP capabilities flow through the single `make_capabilities()` in `lua/hwangfu/lsp/helpers.lua`.

**Tech Stack:** Neovim >= 0.10, lazy.nvim, blink.cmp v1.x (prebuilt Rust fuzzy matcher).

## Global Constraints

- ASCII only in every config file; verify with the grep in each task.
- Indentation PER-FILE: `plugins.lua`, `completion.lua` (inherits from cmp.lua), root `init.lua` use TABS; `keymap.lua`, `crates.lua`, `lsp/helpers.lua`, `lsp/servers/*.lua` use 4 SPACES. Never run stylua.
- NOT a git repository: no commit steps; each task ends with a parse-check.
- Keybinding PARITY is the rule for insert-mode completion; cmdline popup is the one deliberate new behavior.
- The config call MUST be `require("blink.cmp").setup(...)` from the module, and capabilities MUST use `blink.get_lsp_capabilities(caps)` behind a pcall.
- Parse-check command: `nvim --clean --headless -c "lua assert(loadfile('<FILE>'))" -c q`

---

### Task 1: plugins.lua - swap the completion plugin block

**Files:**
- Modify: `lua/hwangfu/plugins.lua` (the completion/snippet block, currently lines ~643-654)

**Interfaces:**
- Produces: plugin `saghen/blink.cmp` pinned `version = "1.*"`, loaded eagerly. Task 2's module and Task 3's capabilities depend on `require("blink.cmp")` resolving after `:Lazy sync`.

- [ ] **Step 1: Replace the nvim-cmp + sources + snippet block**

Replace exactly (TAB-indented):

```lua
	-- Completion engine.
	"hrsh7th/nvim-cmp",

	-- Sources for nvim-cmp:
	"hrsh7th/cmp-nvim-lsp", -- LSP completions (from language servers)
	"hrsh7th/cmp-buffer", -- words from current buffer
	"hrsh7th/cmp-path", -- file paths
	"hrsh7th/cmp-cmdline", -- command-line completion (:, /)

	-- Snippet engine (required by nvim-cmp, even if you don't really use snippets yet)
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",
```

with (TAB-indented):

```lua
	-- Completion engine (blink.cmp): fuzzy completion with a prebuilt Rust
	-- matcher, replacing the whole nvim-cmp stack (2026-08).
	--
	-- Removed (2026-08), all superseded by this one spec:
	--   * hrsh7th/nvim-cmp       the engine (maintenance mode upstream)
	--   * hrsh7th/cmp-nvim-lsp   -> blink's built-in `lsp` source; the
	--                            capabilities half now comes from
	--                            blink.get_lsp_capabilities() in
	--                            lua/hwangfu/lsp/helpers.lua
	--   * hrsh7th/cmp-buffer     -> built-in `buffer` source
	--   * hrsh7th/cmp-path       -> built-in `path` source
	--   * hrsh7th/cmp-cmdline    -> built-in cmdline completion. NOTE: the
	--                            cmp-cmdline plugin was installed but never
	--                            wired up (no cmp.setup.cmdline call ever
	--                            existed), so blink's cmdline popup is the
	--                            first time ":" completion actually left
	--                            the native wildmenu.
	--   * L3MON4D3/LuaSnip + saadparwaiz1/cmp_luasnip
	--                            nvim-cmp required a snippet engine; blink
	--                            does not - LSP snippet items expand via
	--                            Neovim's built-in vim.snippet. No custom
	--                            snippets were ever defined. (Re-add later
	--                            via blink's snippets.preset = "luasnip"
	--                            if that changes.)
	--
	-- version = "1.*" pins to stable releases so lazy.nvim downloads the
	-- prebuilt Rust fuzzy-matcher binary for that release tag (no cargo or
	-- nightly toolchain needed). If the download fails, blink's default
	-- fuzzy.implementation = "prefer_rust_with_warning" falls back to the
	-- Lua matcher and says so.
	--
	-- Behavior config lives in lua/hwangfu/completion.lua, called from the
	-- root init.lua (plugins -> completion -> lsp order), the same wiring
	-- the old nvim-cmp module had.
	{
		"saghen/blink.cmp",
		version = "1.*",
	},
```

- [ ] **Step 2: Verify**

Run: `nvim --clean --headless -c "lua assert(loadfile('/home/hwangfu/.config/nvim/lua/hwangfu/plugins.lua'))" -c q`
Expected: no output.

Run: `grep -nP '[^\x00-\x7F]' /home/hwangfu/.config/nvim/lua/hwangfu/plugins.lua`
Expected: no output.

---

### Task 2: completion.lua module + root init.lua rewire

**Files:**
- Create: `lua/hwangfu/completion.lua` (TABS)
- Delete: `lua/hwangfu/cmp.lua`
- Modify: root `init.lua` (module list line 8, leader comment lines 23-28, ordering comment lines 39-48, wire-up line 52)

**Interfaces:**
- Consumes: `saghen/blink.cmp` from Task 1.
- Produces: `require("hwangfu.completion").setup()` - the only completion entry point. Verification in Task 5 calls it via normal startup.

- [ ] **Step 1: Create lua/hwangfu/completion.lua**

Full content (TAB-indented). The LSP CODE HELPERS block is copied verbatim from cmp.lua lines 34-57 - keep it identical:

```lua
-- ============================================================================
-- blink.cmp setup: completion engine.
--
-- Migrated from nvim-cmp (2026-08); this module was lua/hwangfu/cmp.lua.
-- One plugin now covers what took five (nvim-cmp + cmp-nvim-lsp /
-- cmp-buffer / cmp-path / cmp-cmdline) plus the LuaSnip pair - see the
-- removal note in lua/hwangfu/plugins.lua.
--
-- What's wired up:
--   * Engine          - blink.cmp with its prebuilt Rust fuzzy matcher
--                       (Lua fallback if the binary is unavailable).
--   * UI behavior     - PARITY with the old nvim-cmp setup: popup on every
--                       keystroke, first item preselected but not inserted
--                       (the old completeopt "noinsert"), Enter confirms,
--                       documentation window auto-shows after 200ms.
--   * Snippets        - no snippet engine plugin. LSP snippet items
--                       (rust-analyzer's fn / match, etc.) expand through
--                       Neovim's built-in vim.snippet; jump between
--                       placeholders with <Tab> / <S-Tab>.
--   * Sources         - lsp + path primary; buffer words only appear when
--                       the LSP returns nothing (blink's default fallback
--                       chain - the same shape as the old two-group
--                       nvim-cmp setup).
--   * Cmdline         - NEW (2026-08, deliberate): popup completion for
--                       ":" commands and "/" searches via blink's built-in
--                       cmdline mode. The old cmp-cmdline plugin was
--                       installed but never wired up, so ":" completion
--                       had always been the native wildmenu until now.
--                       Blink's cmdline defaults apply: <Tab> shows and
--                       cycles, arrows navigate, <CR> accepts and runs.
--
-- ----------------------------------------------------------------------------
-- Keybinding reference: the coding helpers and how to drive them.
-- (<leader> is the Space key.)
--
-- COMPLETION MENU - mapped in this file, in the `keymap` table below.
-- The popup appears by itself as you type; a documentation window for the
-- highlighted item shows automatically beside it (after 200ms).
--   <Down> / <Up>   move down / up through the suggestion list
--   <C-n> / <C-p>   same, without leaving the home row
--   <C-Space>       open the menu on demand (if it is not already showing)
--   <CR>            accept the highlighted suggestion
--   <C-f> / <C-b>   scroll the documentation window down / up
--   <Esc>           menu open: dismiss it and STAY in insert mode;
--                   menu closed: leave insert mode as usual
--
-- LSP CODE HELPERS - jump around and act on code, active once a language
-- server has attached (rust-analyzer, lua_ls, ...).
--
-- Mapped in lua/hwangfu/lsp/init.lua:
--   K               hover: docs for the symbol under the cursor. Press K a
--                   second time to jump into that popup, then scroll it and
--                   press q to close.
--   <C-k>           signature help: parameter hints. Works in insert mode,
--                   so this is the one to call inside a function call's ().
--   gd / gD         go to definition / declaration
--   gt / gi         go to type definition / implementation
--   <leader>rn      rename the symbol everywhere
--   <leader>ca      code action: offered quick-fixes and refactors
--   gl              show the full diagnostic for the current line
--
-- Provided by Neovim 0.11+ as built-in defaults (this config does not map
-- them; Neovim already does):
--   grr             list every reference to the symbol
--   [d / ]d         jump to the previous / next diagnostic
--
-- Getting back after a jump: gd / grr can land you in a different file.
-- <C-o> jumps back to where you came from, <C-i> jumps forward again, and
-- <C-^> toggles to the previously-edited buffer. See keymap.lua's Buffers
-- section for more on moving between files.
-- ============================================================================

local M = {}

-- require("hwangfu.completion").setup()
function M.setup()
	require("blink.cmp").setup({
		-- Parity mappings - each entry is a command list tried in order;
		-- "fallback" passes the key through when the menu is not showing.
		keymap = {
			preset = "none",

			-- Move through the menu: the arrow keys, or <C-n>/<C-p> to
			-- keep your hands on the home row.
			["<Down>"] = { "select_next", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },

			-- Open the completion menu on demand.
			["<C-space>"] = { "show", "fallback" },

			-- ENTER to confirm (first item counts - it is preselected).
			["<CR>"] = { "accept", "fallback" },

			-- Scroll the documentation window of the highlighted item.
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },

			-- Esc: close the menu but STAY in insert mode (the old
			-- nvim-cmp abort behavior). With no menu showing, fallback
			-- makes Esc leave insert mode as usual.
			["<Esc>"] = { "cancel", "fallback" },
		},

		completion = {
			list = {
				-- preselect + no auto_insert = the old completeopt
				-- "menu,menuone,noinsert" plus confirm-first-item.
				selection = { preselect = true, auto_insert = false },
			},
			documentation = {
				-- nvim-cmp showed docs automatically; blink needs the
				-- opt-in. 200ms keeps the fast menu from flickering
				-- docs on every keystroke (0 = instant, 500 = blink's
				-- own default delay).
				auto_show = true,
				auto_show_delay_ms = 200,
			},
		},

		sources = {
			-- No "snippets" source: LuaSnip is gone and no snippet
			-- files exist; LSP snippet ITEMS still arrive via "lsp".
			-- blink's default source config already lists "buffer" as
			-- a fallback of "lsp" (buffer words only when the LSP has
			-- nothing), which is the old two-group behavior.
			default = { "lsp", "path", "buffer" },
		},

		-- Popup completion for ":" and "/" (blink built-in; keymaps are
		-- blink's cmdline defaults - Tab shows/cycles, arrows navigate).
		cmdline = {
			enabled = true,
		},
	})
end

return M
```

- [ ] **Step 2: Delete the old module**

Run: `rm /home/hwangfu/.config/nvim/lua/hwangfu/cmp.lua`

- [ ] **Step 3: Root init.lua - module list entry**

Replace:

```lua
--        cmp       - completion engine (nvim-cmp)
```

with:

```lua
--        completion - completion engine (blink.cmp)
```

- [ ] **Step 4: Root init.lua - leader-key comment (stale markdown-preview mention)**

Replace:

```lua
-- Must be set before everything else. `<leader>` inside a mapping is resolved
-- to the value of mapleader *at the moment the mapping is created* - and some
-- plugin code creates mappings during startup (lazy.nvim runs each plugin's
-- `init` hook while the plugins module below loads; markdown-preview's
-- <leader>m* maps are defined there). Setting mapleader here guarantees those
-- mappings see the intended leader.
```

with:

```lua
-- Must be set before everything else. `<leader>` inside a mapping is resolved
-- to the value of mapleader *at the moment the mapping is created* - and some
-- plugin code creates mappings during startup (lazy.nvim registers each
-- plugin's `init` hooks and `keys` triggers while the plugins module below
-- loads; live-preview's <leader>m* keys are defined that way). Setting
-- mapleader here guarantees those mappings see the intended leader.
```

- [ ] **Step 5: Root init.lua - ordering comment + wire-up call**

Replace:

```lua
-- Order matters somewhat:
--   * plugins first - lazy.nvim must install and load the plugins before the
--     modules that configure them run (cmp needs nvim-cmp on the runtimepath,
--     lsp's make_capabilities() pcalls require("cmp_nvim_lsp"), etc.).
--   * cmp before lsp because make_capabilities() in lsp/init.lua pcalls
--     require("cmp_nvim_lsp"). If that fails (cmp not yet loaded), servers
--     come up without cmp-aware completion bits.
```

with (also fixing the old lsp/init.lua -> lsp/helpers.lua drift):

```lua
-- Order matters somewhat:
--   * plugins first - lazy.nvim must install and load the plugins before the
--     modules that configure them run (completion needs blink.cmp on the
--     runtimepath, lsp's make_capabilities() pcalls require("blink.cmp")).
--   * completion before lsp because make_capabilities() in lsp/helpers.lua
--     pcalls require("blink.cmp"). If that fails (blink not yet loaded),
--     servers come up without blink-augmented completion bits.
```

Then replace:

```lua
require("hwangfu.cmp").setup()
```

with:

```lua
require("hwangfu.completion").setup()
```

- [ ] **Step 6: Verify**

Run: `nvim --clean --headless -c "lua assert(loadfile('/home/hwangfu/.config/nvim/lua/hwangfu/completion.lua')); assert(loadfile('/home/hwangfu/.config/nvim/init.lua'))" -c q`
Expected: no output.

Run: `ls /home/hwangfu/.config/nvim/lua/hwangfu/cmp.lua`
Expected: "No such file or directory".

Run: `grep -nP '[^\x00-\x7F]' /home/hwangfu/.config/nvim/lua/hwangfu/completion.lua /home/hwangfu/.config/nvim/init.lua`
Expected: no output.

---

### Task 3: capabilities swap in helpers.lua + LSP server comments

**Files:**
- Modify: `lua/hwangfu/lsp/helpers.lua` (header lines ~12-15 and ~35, function comment + body lines ~46-59, define_server comment line ~163) - 4 SPACES
- Modify: `lua/hwangfu/lsp/servers/hls.lua:77` - 4 SPACES
- Modify: `lua/hwangfu/lsp/servers/rust_analyzer.lua:209-211` - 4 SPACES

**Interfaces:**
- Consumes: `require("blink.cmp").get_lsp_capabilities(caps)` from the plugin installed in Task 1.
- Produces: `M.make_capabilities()` returning blink-augmented capabilities; every server file keeps calling it unchanged. clangd.lua's own snippet tweak layers on top - do NOT modify clangd.lua.

- [ ] **Step 1: helpers.lua header entry**

Replace:

```lua
--   * make_capabilities      - the capability table advertised to servers.
--                              Starts from Neovim's defaults and layers on
--                              cmp_nvim_lsp's snippet / additionalTextEdits
--                              bits when nvim-cmp is present.
```

with:

```lua
--   * make_capabilities      - the capability table advertised to servers.
--                              Starts from Neovim's defaults and layers on
--                              blink.cmp's snippet / additionalTextEdits
--                              bits when blink is present.
```

- [ ] **Step 2: helpers.lua define_server header mention**

Replace:

```lua
--                              cmp-augmented capabilities and
```

with:

```lua
--                              blink-augmented capabilities and
```

- [ ] **Step 3: helpers.lua make_capabilities comment + body**

Replace:

```lua
-- Build the capability table advertised to language servers. We start with
-- Neovim's defaults and, if nvim-cmp is present, layer on the extra capability
-- bits cmp_nvim_lsp wants (snippet support, additionalTextEdits, etc.) so
-- completion items round-trip correctly. The pcall lets the config still load
-- if cmp is not installed yet (e.g. a fresh machine before lazy.nvim has
-- finished installing everything).
function M.make_capabilities()
    local caps = vim.lsp.protocol.make_client_capabilities()
    local ok, cmp = pcall(require, "cmp_nvim_lsp")
    if ok then
        caps = cmp.default_capabilities(caps)
    end
    return caps
end
```

with:

```lua
-- Build the capability table advertised to language servers. We start with
-- Neovim's defaults and, if blink.cmp is present, layer on the extra
-- capability bits blink wants (snippet support, additionalTextEdits, etc.)
-- so completion items round-trip correctly. The pcall lets the config still
-- load if blink is not installed yet (e.g. a fresh machine before lazy.nvim
-- has finished installing everything).
function M.make_capabilities()
    local caps = vim.lsp.protocol.make_client_capabilities()
    local ok, blink = pcall(require, "blink.cmp")
    if ok then
        caps = blink.get_lsp_capabilities(caps)
    end
    return caps
end
```

- [ ] **Step 4: helpers.lua define_server numbered comment**

Replace:

```lua
--   2. Fills in cmp-aware capabilities and the standard on_attach when the
```

with:

```lua
--   2. Fills in blink-aware capabilities and the standard on_attach when the
```

- [ ] **Step 5: hls.lua and rust_analyzer.lua comment mentions**

In `lua/hwangfu/lsp/servers/hls.lua`, replace:

```lua
            -- cmp_nvim_lsp's snippet / additionalTextEdits bits, same
            -- as every other server in this config.
```

with:

```lua
            -- blink.cmp's snippet / additionalTextEdits bits, same
            -- as every other server in this config.
```

In `lua/hwangfu/lsp/servers/rust_analyzer.lua`, replace:

```lua
--   * capabilities = helpers.make_capabilities() so cmp_nvim_lsp's
--     snippet / additionalTextEdits bits are advertised, matching every
--     other server in this config.
```

with:

```lua
--   * capabilities = helpers.make_capabilities() so blink.cmp's
--     snippet / additionalTextEdits bits are advertised, matching every
--     other server in this config.
```

- [ ] **Step 6: Verify**

Run: `nvim --clean --headless -c "lua assert(loadfile('/home/hwangfu/.config/nvim/lua/hwangfu/lsp/helpers.lua')); assert(loadfile('/home/hwangfu/.config/nvim/lua/hwangfu/lsp/servers/hls.lua')); assert(loadfile('/home/hwangfu/.config/nvim/lua/hwangfu/lsp/servers/rust_analyzer.lua'))" -c q`
Expected: no output.

Run: `grep -rn "cmp_nvim_lsp" /home/hwangfu/.config/nvim/lua/ /home/hwangfu/.config/nvim/init.lua`
Expected: no matches at all.

---

### Task 4: crates + keymap comment sweep

**Files:**
- Modify: `lua/hwangfu/plugins.lua` (crates.nvim spec comment, ~line 977-985) - TABS
- Modify: `lua/hwangfu/crates.lua` (header lines ~24-27, entry-point comment lines ~117-119) - 4 SPACES
- Modify: `lua/hwangfu/keymap.lua:107` - 4 SPACES

**Interfaces:**
- Consumes: module name `lua/hwangfu/completion.lua` from Task 2 (comments must reference it, not cmp.lua).

- [ ] **Step 1: plugins.lua crates comment**

Replace (TAB-indented):

```lua
	-- Integration is via crates.nvim's IN-PROCESS language server, NOT its
	-- (deprecated, slated-for-removal) nvim-cmp source. With that, completion
	-- rides the existing { name = "nvim_lsp" } source in cmp.lua and hover /
	-- code actions ride taplo's existing K / <leader>ca bindings on Cargo.toml,
	-- so neither cmp.lua nor the LSP keymaps need changing. See the long note
	-- in lua/hwangfu/crates.lua for the full rationale and the <leader>c*
	-- keymap reference.
```

with:

```lua
	-- Integration is via crates.nvim's IN-PROCESS language server, NOT its
	-- (deprecated, slated-for-removal) nvim-cmp source. With that, completion
	-- rides blink.cmp's built-in `lsp` source and hover / code actions ride
	-- taplo's existing K / <leader>ca bindings on Cargo.toml, so neither
	-- lua/hwangfu/completion.lua nor the LSP keymaps need changing. See the
	-- long note in lua/hwangfu/crates.lua for the full rationale and the
	-- <leader>c* keymap reference.
```

- [ ] **Step 2: crates.lua header consequence bullet**

Replace (4-space file, comment at column 0):

```lua
--     * completion  - crate / version / feature completions are served as a
--                     normal LSP completionProvider, so they flow through the
--                     EXISTING { name = "nvim_lsp" } source in cmp.lua. No
--                     change to cmp.lua is needed.
```

with:

```lua
--     * completion  - crate / version / feature completions are served as a
--                     normal LSP completionProvider, so they flow through
--                     blink.cmp's built-in `lsp` source (configured in
--                     lua/hwangfu/completion.lua). No change needed there.
```

- [ ] **Step 3: crates.lua entry-point comment**

Replace:

```lua
-- completion.cmp is left at its default (off) on purpose - see the header note
-- about the deprecated nvim-cmp source. completion.crates (crates.nvim's own
-- built-in source) and smart_insert / autoload stay at their defaults (on).
```

with:

```lua
-- completion.cmp is left at its default (off) on purpose - it is the bridge
-- to nvim-cmp, which is deprecated upstream AND no longer installed here
-- (blink.cmp consumes the in-process LSP server instead; see the header
-- note). completion.crates (crates.nvim's own built-in source) and
-- smart_insert / autoload stay at their defaults (on).
```

- [ ] **Step 4: keymap.lua LuaSnip mention**

Replace:

```lua
    -- <C-g> from Visual (the path snippet plugins like LuaSnip take when
```

with:

```lua
    -- <C-g> from Visual (the path snippet engines like vim.snippet take when
```

- [ ] **Step 5: Verify**

Run: `nvim --clean --headless -c "lua assert(loadfile('/home/hwangfu/.config/nvim/lua/hwangfu/plugins.lua')); assert(loadfile('/home/hwangfu/.config/nvim/lua/hwangfu/crates.lua')); assert(loadfile('/home/hwangfu/.config/nvim/lua/hwangfu/keymap.lua'))" -c q`
Expected: no output.

Run: `grep -rn "LuaSnip\|luasnip\|cmp\.lua\|{ name = \"nvim_lsp\" }" /home/hwangfu/.config/nvim/lua/ /home/hwangfu/.config/nvim/init.lua`
Expected: matches ONLY in comments that intentionally record history (plugins.lua removal note's LuaSnip lines, completion.lua's "was lua/hwangfu/cmp.lua" line). No code references.

---

### Task 5: sync and verification battery

**Files:**
- None modified.

**Interfaces:**
- Consumes: everything from Tasks 1-4.

- [ ] **Step 1: Sync plugins**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5`
Expected: clean completion; blink.cmp installed at a v1.x tag; nvim-cmp, cmp-nvim-lsp, cmp-buffer, cmp-path, cmp-cmdline, LuaSnip, cmp_luasnip removed.

Run: `ls ~/.local/share/nvim/lazy/ | grep -iE "cmp|snip|blink"`
Expected: only `blink.cmp`.

- [ ] **Step 2: Startup smoke test**

Run: `nvim --headless -c "lua print('startup OK')" -c q 2>&1`
Expected: contains `startup OK`, no error lines. (blink may print a one-time fuzzy-binary download message on the very first start; rerun once if so - it must not error.)

- [ ] **Step 3: Capabilities prove-out**

Run: `nvim --headless -c "lua local h = require('hwangfu.lsp.helpers'); local c = h.make_capabilities(); print('snippetSupport:', c.textDocument.completion.completionItem.snippetSupport)" -c q 2>&1`
Expected: `snippetSupport: true` (proves blink.get_lsp_capabilities ran, not the bare-defaults fallback).

- [ ] **Step 4: Manual checklist for the user**

1. Rust file: typing pops the menu with first item highlighted but NOT inserted; `<CR>` accepts; `<C-Space>` reopens after `<Esc>`; docs float appears ~200ms after highlighting an item; `<C-f>`/`<C-b>` scroll it.
2. `<Esc>` with the menu open closes the menu and stays in insert; a second `<Esc>` leaves insert.
3. `:` then typing shows the popup cmdline completion (Tab cycles); same for `/` search.
4. Cargo.toml: version completion inside a dependency string still works (crates.nvim via LSP).
5. rust-analyzer snippet items (e.g. accepting a `fn` completion) expand with placeholders; `<Tab>`/`<S-Tab>` jump between them.
