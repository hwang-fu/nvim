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

	-- (lualine migrated to spec/lualine.lua, 2026-08-15.)

	-- (gitsigns migrated to spec/gitsigns.lua, 2026-08-15.)

	-- (diffview migrated to spec/diffview.lua, 2026-08-15.)

	-- (Colorschemes migrated to spec/colorschemes.lua, 2026-08-15.)

	-- (live-preview migrated to spec/live_preview.lua, 2026-08-15.)

	-- (render-markdown migrated to spec/render_markdown.lua, 2026-08-15.)

	-- Comment toggling: handled by Neovim's built-in gc / gcc / gbc operators
	-- (added in Neovim 0.10). Comment.nvim was previously here but is now
	-- redundant. The visual-mode <C-l> map in lua/hwangfu/keymap.lua continues
	-- to work because it remaps to `gc`, which now resolves to the built-in.

	-- (blink.cmp migrated to spec/blink.lua, 2026-08-15.)

	-- (oil migrated to spec/oil.lua, 2026-08-15.)

	-- (telescope migrated to spec/telescope.lua, 2026-08-15.)

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
