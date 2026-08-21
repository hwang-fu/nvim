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
return {
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

			-- --- nREPL forgot-to-start reminder (2026-08-17, user request) ---
			--
			-- Conjure never starts the Clojure REPL (deliberate: the REPL is
			-- a long-lived process the user owns in a terminal), so the
			-- classic slip is opening a project and evaluating into nothing.
			-- This check runs once per PROJECT per session, on the first
			-- clojure FileType event for that project, deferred so it never
			-- slows the file open:
			--   * no deps.edn / project.clj up-tree -> not a project, stay
			--     silent (lone .edn scratch files deserve no nagging);
			--   * no .nrepl-port file found          -> warn: forgot to start;
			--   * port file found                   -> TCP-probe it. nREPL
			--     deletes the file on clean shutdown but crashes leave it
			--     behind, so existence alone proves nothing. A refused
			--     connection means stale -> warn; an accepted one means the
			--     server is up -> total silence.
			-- Both notices are single lines (no hit-enter prompt) and name
			-- the exact command plus \cf, since conjure will not retro-
			-- connect on its own once the buffer is already open. ERROR
			-- level, not WARN (user preference 2026-08-17: "I wanna be
			-- explicitly reminded") - red is the point. Registered
			-- from `init`, not `config`: config runs on the plugin's lazy
			-- ft load, AFTER the first FileType event has already fired.
			-- Conjure opens every log buffer with a hardcoded sponsor
			-- line ("; Sponsored by @somebody <3") - no config option
			-- exists to disable it (checked source and :help,
			-- 2026-08-21; the line is written unconditionally in
			-- log.lua's on_new_log_buf). The user does not want ads in
			-- the HUD, so the line is scrubbed when a log buffer first
			-- reaches a window. Everything else in the log (the divider,
			-- connection notices, eval output) is untouched.
			vim.api.nvim_create_autocmd("BufWinEnter", {
				pattern = "*conjure-log-*",
				group = vim.api.nvim_create_augroup("JwaConjureNoSponsor", { clear = true }),
				callback = function(args)
					local first = vim.api.nvim_buf_get_lines(args.buf, 0, 1, false)[1] or ""
					if first:find("Sponsored by", 1, true) then
						vim.api.nvim_buf_set_lines(args.buf, 0, 1, false, {})
					end
				end,
			})

			local checked_roots = {}
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "clojure",
				group = vim.api.nvim_create_augroup("JwaNreplReminder", { clear = true }),
				callback = function(args)
					vim.defer_fn(function()
						if not vim.api.nvim_buf_is_valid(args.buf) then
							return
						end
						local root = vim.fs.root(args.buf, { "deps.edn", "project.clj" })
						if not root or checked_roots[root] then
							return
						end
						checked_roots[root] = true
						local file_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(args.buf))
						local port_file = vim.fs.find(".nrepl-port", { upward = true, path = file_dir })[1]
						if not port_file then
							vim.notify(
								"Clojure: no nREPL server; run 'clj -M:nrepl:portal' at "
									.. vim.fn.fnamemodify(root, ":~")
									.. ", then \\cf",
								vim.log.levels.ERROR
							)
							return
						end
						local port = tonumber(((vim.fn.readfile(port_file)[1] or ""):match("%d+")) or "")
						if not port then
							return
						end
						local tcp = vim.uv.new_tcp()
						tcp:connect("127.0.0.1", port, function(err)
							tcp:close()
							if err then
								vim.schedule(function()
									vim.notify(
										"Clojure: stale .nrepl-port (port " .. port .. " not answering); restart 'clj -M:nrepl:portal', then \\cf",
										vim.log.levels.ERROR
									)
								end)
							end
						end)
					end, 1000)
				end,
			})
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
}
