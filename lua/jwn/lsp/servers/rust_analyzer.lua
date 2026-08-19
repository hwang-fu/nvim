-- ============================================================================
-- rust-analyzer, configured via the rustaceanvim plugin.
--
-- Ownership of the rust-analyzer LSP client passes to rustaceanvim:
-- the plugin does its own vim.lsp.config(...) + vim.lsp.enable(...) the
-- first time a Rust buffer opens, reading options from vim.g.rustaceanvim.
-- So this module does NOT call helpers.define_server(...) like the other
-- server files; doing so would race rustaceanvim and either start a
-- duplicate client or clobber its runnables / debug / code-action /
-- hover-actions features.
--
-- This module is invoked from the rustaceanvim plugin spec's `init` hook
-- in lua/jwn/plugins/spec/rustaceanvim.lua (NOT from lsp/init.lua's SERVERS loop). The
-- `init` ordering guarantees vim.g.rustaceanvim is populated before
-- rustaceanvim's filetype handler registers itself.
--
-- What this file still owns:
--   * vim.g.rustaceanvim - rust-analyzer settings (cargo, clippy,
--     inlayHints, semantic highlighting), capabilities, on_attach
--     (chains helpers.standard_on_attach so K / gd / gt / <C-k> / etc.
--     install the same way as on every other LSP buffer, then overrides
--     K with rustaceanvim's hover-with-actions), and a few tools knobs.
--   * Notification filter - drops rust-analyzer's transient -32xxx
--     errors from vim.notify, and flattens rustaceanvim's 4-line
--     "standalone mode" notice into one warning line so it cannot
--     trigger the hit-enter prompt (see long comment below).
--   * :RustFormat user command - on-demand rustfmt via the LSP, named
--     to dodge the legacy :RustFmt from runtime/rust.vim.
--
-- What rustaceanvim adds, browseable with `:RustLsp <Tab>`:
--   * expandMacro       expand the macro under cursor in a split. Useful
--                       in macro-heavy crates (serde derive, tokio,
--                       proc-macro DSLs).
--   * explainError      open rustc --explain for the diagnostic under
--                       cursor (the long-form compiler error doc).
--   * openDocs          jump to docs.rs for the symbol under cursor.
--   * parentModule      go to the enclosing `mod` declaration.
--   * runnables         popup picker of tests / examples / binaries the
--                       plugin detected in the crate; runs the choice
--                       in a terminal split.
--   * debuggables       same picker, but via DAP. NOT functional here:
--                       the nvim-dap stack was removed 2026-08-15 at the
--                       user's request (debugging happens outside the
--                       editor for now), so this subcommand errors.
--   * hover range       (visual mode) show the inferred type of the
--                       selected expression. Useful when K on a
--                       generic-fn name only shows `<T>` and you want
--                       the concrete substitution at the use site.
--   * syntaxTree, viewHir, viewMir, moveItem, joinLines, ssr, ...
--   * The K override below uses `hover actions`, which adds clickable
--     "Go to type def / impl / docs" entries to the hover popup. First
--     K opens, second K focuses (same muscle memory as before).
--
-- Difference from the previous helpers.define_server-based setup:
--   - on_attach no longer needs the openCargoToml workaround for bare
--     .rs files outside a Cargo workspace: rustaceanvim's
--     `server.standalone = true` handles that path itself.
--   - `cmd` / `filetypes` / `root_markers` are dropped: rustaceanvim
--     picks sane defaults (auto-discovers `rust-analyzer` on $PATH,
--     attaches on `rust` filetype, roots at Cargo.toml / rust-project.json
--     / .git).
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

-- ----------------------------------------------------------------------------
-- Notification filter for rust-analyzer's LSP-error spam.
--
-- rust-analyzer frequently responds to in-flight requests with JSON-RPC
-- errors while you are still typing. Common cases:
--   * -32603 Internal error  - panics inside a request handler. Triggered
--                              by incomplete code: an unfinished `match`
--                              arm, a half-typed generic, a macro mid-
--                              expansion, certain borrow-checker edge cases.
--   * -32801 Content modified - the buffer changed between request send and
--                              response, so the response is stale. Fires
--                              constantly during normal typing on top of
--                              hover / inlay-hint / semantic-tokens
--                              requests.
--   * -32800 Request cancelled - similar, server side gave up on a request.
--   * -32602 Invalid params   - usually transient, same root cause as above.
--
-- Neovim's LSP client routes ALL of these through vim.notify at ERROR
-- level, formatted as "rust_analyzer: -32xxx: <message>". At the default
-- cmdheight = 1, multi-line messages overflow the cmdline and trigger the
-- "Press ENTER or type command to continue" hit-enter prompt, blocking
-- editing mid-keystroke.
--
-- None of these errors are actionable from the editor: they are transient
-- side effects of typing into a language that demands a complete AST, and
-- rust-analyzer recovers on the next valid state. We drop them from the UI
-- while leaving the underlying entries in :LspLog (fed by vim.lsp.log, a
-- separate channel from vim.notify) for if a panic ever needs investigation.
--
-- What still passes through unchanged:
--   * "rust_analyzer: server attached", indexing progress, custom
--     showMessage / showMessageRequest output (no -32xxx prefix).
--   * Errors from any other server (pyright, clangd, ...) - the pattern
--     anchors on ^rust_analyzer:.
--   * Startup failures like "Failed to start rust_analyzer: ..." (the
--     "rust_analyzer:" token appears mid-string, not at the start).
--
-- Second filter case - the standalone-mode notice (2026-08-15, user
-- request). When a .rs file opens outside any Cargo project, rustaceanvim
-- notifies:
--
--     rustaceanvim:
--     No project root found.
--     Starting rust-analyzer client in detached/standalone mode (with
--     reduced functionality).
--
-- The level is already INFO - the blocking "Press ENTER or type command
-- to continue" prompt comes from the message being FOUR LINES tall, not
-- from its severity: any echo taller than cmdheight (1) triggers the
-- hit-enter prompt regardless of level. The plugin offers no config knob
-- for this (checked its config/internal.lua, 2026-08-15), so the wrapper
-- below rewrites the message to a single line at WARN level. One line
-- never overflows the cmdline, so opening a bare .rs file no longer
-- stops for a keypress; the notice still appears and lands in :messages.
-- Matched on the distinctive "detached/standalone mode" substring so the
-- plugin's OTHER no-root message (the ERROR when standalone is disabled)
-- passes through untouched - that one signals rust-analyzer NOT starting
-- and deserves to be loud (moot here while server.standalone = true).
--
-- Third filter case - the server-status health dump (found while testing
-- the case above, 2026-08-15). When rust-analyzer finishes initializing
-- with health != ok, rustaceanvim's server_status.lua handler notifies
-- "rust-analyzer health status is [error]: <result.message>" - and
-- result.message can embed an ENTIRE failed cargo invocation, stack
-- backtraces included (hundreds of lines on a bare .rs file, where
-- workspace discovery always fails on a stable toolchain). Same
-- hit-enter blocking as above, magnified. The alternative knob,
-- server.status_notify_level = false, silences the signal entirely;
-- flattening keeps the one-line fact and points at :RustLsp logFile,
-- where the full text already lands. The handler emits via
-- vim.notify_once, which resolves vim.notify at call time, so this
-- wrapper does intercept it.
--
-- Implementation notes:
--   * One-shot install via a module-level sentinel; re-running M.setup()
--     does not stack additional wrappers around vim.notify.
--   * Guarded on `type(msg) == "string"` because vim.notify can be invoked
--     with non-string payloads (tables from plugins, etc.).
--   * The pattern uses %-32%d+ rather than a literal "-32603" so it also
--     catches -32801 / -32800 / -32602 without listing each by hand.
-- ----------------------------------------------------------------------------
local notify_wrapped = false

local function install_notify_filter()
    if notify_wrapped then
        return
    end
    notify_wrapped = true

    local orig_notify = vim.notify
    vim.notify = function(msg, level, opts)
        if type(msg) == "string" then
            if msg:match("^rust_analyzer:%s*%-32%d+") then
                return
            end
            if msg:find("detached/standalone mode", 1, true) then
                return orig_notify(
                    "rustaceanvim: no Cargo project found; rust-analyzer runs standalone",
                    vim.log.levels.WARN,
                    opts
                )
            end
            local health = msg:match("rust%-analyzer.- health status is %[(%w+)%]")
            if health then
                return orig_notify(
                    "rustaceanvim: rust-analyzer health is [" .. health .. "]; :RustLsp logFile has details",
                    vim.log.levels.WARN,
                    opts
                )
            end
        end
        return orig_notify(msg, level, opts)
    end
end

-- ----------------------------------------------------------------------------
-- :RustFormat user command.
--
-- On-demand formatter for the current Rust buffer. format-on-save for *.rs is
-- intentionally disabled in lsp/format.lua (the autoformat would clobber
-- partially-typed code while typing), so this is the explicit, manual escape
-- hatch when you actually want rustfmt to run.
--
-- Naming: NOT :RustFmt. Neovim's runtime bundles the legacy rust-lang/rust.vim
-- ftplugin, which on every Rust buffer creates a buffer-local :RustFmt that
-- calls `rustfmt --write-mode=overwrite`. `--write-mode` was removed in
-- rustfmt 1.0 (Rust 2018), so the bundled command always errors with
-- "Unrecognized option: 'write-mode'". The buffer-local definition shadows
-- any global one we register, so the only robust workaround is to use a
-- different name; :RustFormat does not collide with the bundled ftplugin.
--
-- Why route through the LSP instead of shelling out to `rustfmt`:
--   * rust-analyzer's formatProvider already wraps rustfmt and respects the
--     project's rustfmt.toml, edition, and any toolchain override - matching
--     exactly what rust-analyzer itself uses internally.
--   * Works on unsaved buffer contents: the formatter sees the in-memory
--     buffer via textDocument/formatting and we apply the returned textEdits;
--     no need to write to disk first.
--   * Surfaces errors through the LSP layer (which :LspLog already captures)
--     rather than as raw stderr.
--
-- `async = false` makes the format finish before control returns, so a
-- `:RustFormat | w` sequence saves the *formatted* buffer rather than racing
-- the write against the in-flight format request.
--
-- `name = "rust-analyzer"` pins formatting to that one client in the
-- (currently hypothetical) case where another LSP is also attached to the
-- buffer. The HYPHEN is load-bearing: rustaceanvim hard-codes the client
-- name as `ra_client_name = 'rust-analyzer'` in its lsp/init.lua, which
-- is what shows up in vim.lsp.get_clients() / `:LspInfo`. The old
-- underscored "rust_analyzer" name was the config key from
-- helpers.define_server("rust_analyzer", ...); that path no longer
-- registers a client now that rustaceanvim owns LSP setup, so the
-- underscored filter matches nothing and the command fails with
-- "Format request failed, no matching language servers."
--
-- The filetype guard is a friendly error: running :RustFormat in a Lua
-- buffer by accident gets a clear "wrong buffer" message instead of silently
-- doing nothing because no rust-analyzer client is attached.
-- ----------------------------------------------------------------------------
local function install_rustfmt_command()
    vim.api.nvim_create_user_command("RustFormat", function()
        if vim.bo.filetype ~= "rust" then
            vim.notify(
                "RustFormat: current buffer is not a Rust file (filetype=" .. vim.bo.filetype .. ")",
                vim.log.levels.WARN
            )
            return
        end
        vim.lsp.buf.format({
            async = false,
            name = "rust-analyzer",
        })
    end, {
        desc = "Format current Rust buffer via rust-analyzer (rustfmt)",
    })
end

-- ----------------------------------------------------------------------------
-- vim.g.rustaceanvim
--
-- The rustaceanvim plugin reads this table at filetype-handler registration
-- time. Three top-level keys are accepted by the plugin: `tools`, `server`,
-- `dap`. We set the first two; `dap` is deliberately absent (see below).
--
-- tools (editor-side behavior):
--   * float_win_config.auto_focus = false keeps the existing K muscle
--     memory: first K opens the hover popup with the cursor still on
--     the code; a second K moves focus into the popup so you can scroll
--     long docs or click the new "Go to type def / impl / docs" actions
--     rustaceanvim adds at the top. With auto_focus = true the popup
--     would steal focus on the first press, which mismatches every
--     other LSP buffer's K behavior in this config.
--   * Everything else is left at rustaceanvim's defaults (runnables
--     executor = "termopen", nextest / clippy auto-detected, etc.).
--
-- server (rust-analyzer LSP client):
--   * capabilities = helpers.make_capabilities() so blink.cmp's
--     snippet / additionalTextEdits bits are advertised, matching every
--     other server in this config.
--   * on_attach chains helpers.standard_on_attach (which installs the
--     common buffer-local LSP keymaps + inlay hints + semantic tokens)
--     and then overrides K to call `:RustLsp hover actions` instead of
--     plain vim.lsp.buf.hover -- so the hover popup gains rustaceanvim's
--     clickable code actions on Rust buffers only. All other LSP keymaps
--     (gd, gD, gt, gi, <C-k>, <leader>rn, <leader>ca, gl) install
--     unchanged. The override is buffer-local so non-Rust LSP buffers
--     still get the vanilla hover.
--   * default_settings: identical contents to the previous
--     `settings = { ... }` table that helpers.define_server used to pass
--     through. `default_settings` is the static-table variant of the
--     `settings` key; we use it because we are not loading per-project
--     overrides from rust-project.json / .vscode/settings.json.
--   * standalone = true lets rustaceanvim attach to bare .rs files that
--     are NOT inside a Cargo workspace, which obsoletes the openCargoToml
--     workaround the previous on_attach had. The default is already true
--     but we set it explicitly so the intent is visible.
--
-- dap (debugger):
--   * Absent on purpose. The whole debugging stack (nvim-dap, dap-ui,
--     mason/codelldb, lua/jwn/dap.lua) was removed 2026-08-15 at the
--     user's request - debugging happens outside the editor for now.
--     :RustLsp debuggables / debug therefore error. To bring debugging
--     back, restore those pieces from git history; rustaceanvim then
--     auto-detects a mason-installed codelldb with no dap knob needed
--     here.
-- ----------------------------------------------------------------------------
local function install_rustaceanvim_config()
    vim.g.rustaceanvim = {
        tools = {
            float_win_config = {
                auto_focus = false,
            },
        },

        server = {
            capabilities = helpers.make_capabilities(),
            standalone = true,

            on_attach = function(client, bufnr)
                helpers.standard_on_attach(client, bufnr)

                -- --- K override: enhanced hover with code actions ----
                --
                -- This is a DELIBERATE behavior change on Rust buffers
                -- only. helpers.set_common_keymaps (called via
                -- helpers.standard_on_attach above) has just bound K
                -- to vim.lsp.buf.hover, the same standard LSP hover
                -- every other server in this config uses. The block
                -- below replaces that binding with rustaceanvim's
                -- `:RustLsp hover actions` -- but only on the rust-
                -- analyzer-attached buffer, via the `buffer = bufnr`
                -- option.
                --
                -- Why bother:
                --   The default vim.lsp.buf.hover already shows
                --   rust-analyzer's full hover content (type
                --   signature, doc-comments, substituted generics on
                --   recent rust-analyzer versions). What `:RustLsp
                --   hover actions` adds is a header block of
                --   *clickable* code actions inferred for the symbol
                --   under the cursor. Typical entries:
                --     * Go to Type Definition
                --     * Go to Implementation(s)
                --     * Open documentation on docs.rs
                --     * Show parent module
                --     * Run / Debug runnable (when the cursor sits on
                --       a #[test], a fn main, or an example)
                --   The list is adaptive: it depends on what
                --   rust-analyzer reports as available for that
                --   symbol; it is not a fixed menu.
                --
                -- Interaction with tools.float_win_config.auto_focus
                -- = false (set in install_rustaceanvim_config below):
                --   1st K  -> opens the popup; cursor stays on the
                --             code so reading / editing flow keeps
                --             going.
                --   2nd K  -> focuses the popup; j / k or arrow keys
                --             scroll long docs, <CR> on a code-action
                --             row invokes it, q closes. Matches the
                --             vanilla "double-K to focus the hover"
                --             muscle memory; the extra clickable
                --             rows just sit at the top of the same
                --             popup.
                --
                -- Scope: this binding is BUFFER-LOCAL (`buffer =
                -- bufnr`). Non-Rust LSP buffers (Go, Python, Lua, ...)
                -- keep K = vim.lsp.buf.hover, so the divergence is
                -- localized to the file types rustaceanvim attaches
                -- to. The cross-buffer asymmetry is intentional and
                -- justified by Rust being a primary daily-driver
                -- language in this config; revisit if that ever
                -- changes.
                --
                -- To revert to plain vim.lsp.buf.hover on Rust
                -- buffers as well: delete this vim.keymap.set block.
                -- helpers.set_common_keymaps's earlier K binding then
                -- becomes the live one (it was overwritten, not
                -- removed, so dropping the override exposes it
                -- again).
                vim.keymap.set("n", "K", function()
                    vim.cmd.RustLsp({ "hover", "actions" })
                end, {
                    buffer = bufnr,
                    silent = true,
                    desc = "LSP hover with rustaceanvim code actions",
                })
            end,

            default_settings = {
                ["rust-analyzer"] = {
                    semanticHighlighting = {
                        operator = {
                            specialization = {
                                enable = true,
                            },
                        },
                        punctuation = {
                            enable = true,
                            specialization = {
                                enable = true,
                            },
                        },
                    },

                    cargo = {
                        allFeatures = true,
                        loadOutDirsFromCheck = true,
                    },

                    checkOnSave = true,

                    check = {
                        command = "clippy",
                    },

                    procMacro = {
                        enable = true,
                    },

                    inlayHints = {
                        bindingModeHints = {
                            enable = true,
                        },
                        chainingHints = {
                            enable = true,
                        },
                        closingBraceHints = {
                            enable = true,
                        },
                        closureReturnTypeHints = {
                            enable = "with_block",
                        },
                        -- Show inferred lifetimes on every function that
                        -- has elided them, including the trivial cases
                        -- covered by Rust's three elision rules. The other
                        -- valid values are "skip_trivial" (hide hints where
                        -- the rules unambiguously fix the answer, e.g.
                        -- `fn first(s: &str) -> &str`) and "never" (off).
                        lifetimeElisionHints = {
                            enable = "always",
                        },
                        parameterHints = {
                            enable = true,
                        },
                        typeHints = {
                            enable = true,
                        },
                    },
                },
            },
        },

    }
end

function M.setup()
    install_notify_filter()
    install_rustfmt_command()
    install_rustaceanvim_config()
end

return M
