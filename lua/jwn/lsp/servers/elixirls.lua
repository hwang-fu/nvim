-- ============================================================================
-- ElixirLS (and the rest of the Elixir IDE story), via elixir-tools.nvim.
--
-- Ownership of the Elixir LSP client passes to elixir-tools.nvim: the
-- plugin does its own vim.lsp.config / vim.lsp.enable through the
-- `require("elixir").setup({...})` call below. So this module does NOT
-- call helpers.define_server(...) like the other server files; doing
-- so would race elixir-tools and either start a duplicate client or
-- clobber its :Mix / :ElixirFromPipe / :ElixirExpandMacro user
-- commands.
--
-- This module is invoked from the elixir-tools.nvim plugin spec's
-- `config` hook in lua/jwn/plugins/spec/elixir_tools.lua (NOT from lsp/init.lua's
-- SERVERS loop). The `config` ordering guarantees that elixir-tools is
-- already on the runtimepath before we `require("elixir")`.
--
-- What this file owns:
--   * The `require("elixir").setup({...})` call that selects which
--     LSP backend(s) to enable, points ElixirLS at the existing
--     installation, passes through ElixirLS server settings (Dialyzer,
--     test lenses, spec suggestions, deps fetching), wires
--     helpers.standard_on_attach into the per-LSP on_attach, and turns
--     on Projectionist.
--
-- What elixir-tools.nvim adds, browseable with `:Elixir <Tab>` and
-- the dedicated user commands:
--   * :Mix <task>          run mix tasks with completion -- e.g.
--                          `:Mix deps.get`, `:Mix ecto.migrate`,
--                          `:Mix test`, `:Mix phx.routes`.
--   * :ElixirFromPipe      rewrite `x |> f(y)` -> `f(x, y)` at cursor.
--   * :ElixirToPipe        rewrite `f(x, y)` -> `x |> f(y)` at cursor.
--   * :ElixirExpandMacro   show the expanded form of a macro in a
--                          floating split (the Elixir analogue of
--                          rustaceanvim's :RustLsp expandMacro).
--   * :ElixirRestart       restart the Elixir LSP client.
--   * :ElixirOutputPanel   open the LSP log panel.
--   * Projectionist        Phoenix-aware file scaffolding via
--                          :Esource / :Etest / :Etask / :Econtroller
--                          / :Eview / :Eliveview / :Echannel /
--                          :Ecomponent / :Elivecomponent / :Efeature
--                          / :Ehtml / :Ejson. Detect-on-demand inside
--                          a Mix project; the commands simply don't
--                          fire elsewhere.
--
-- LSP backend choice:
--   * ElixirLS:  enabled. The mature, battle-tested LSP this config
--                has used since before the elixir-tools migration.
--   * Next LS:   explicitly disabled. Newer LSP by the elixir-tools
--                team; faster and built specifically to pair with this
--                plugin, but still working toward feature parity with
--                ElixirLS (e.g. some Dialyzer / spec-suggestion paths).
--                Flip `nextls.enable` to true to evaluate it (running
--                both LSPs simultaneously is supported but produces
--                doubled diagnostics; usually you'd flip ElixirLS off
--                at the same time).
--
-- Difference from the previous helpers.define_server-based setup:
--   * `filetypes` and `root_markers` are dropped: elixir-tools picks
--     sane defaults (attaches on elixir / eelixir / heex, roots at
--     mix.exs). If you previously relied on `surface` being in the
--     filetype list, note that elixir-tools does not include it in
--     defaults; raise this if you actually open .sface files.
--   * `cmd` is preserved, pointing at the existing ElixirLS install at
--     ~/.local/share/elixir-ls/language_server.sh. With cmd set,
--     elixir-tools' auto-install (which would clone + compile into
--     ~/.cache on first run) is skipped.
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

function M.setup()
    local elixir = require("elixir")
    local elixirls = require("elixir.elixirls")

    elixir.setup({
        -- ----------------------------------------------------------------
        -- Next LS: explicitly disabled.
        --
        -- The plugin already defaults to nextls.enable = false, but we set
        -- it explicitly so the choice is visible at the call site rather
        -- than implicit in an upstream default that could shift between
        -- releases (the README notes Next LS will eventually flip to
        -- enabled-by-default once it reaches feature parity).
        -- ----------------------------------------------------------------
        nextls = {
            enable = false,
        },

        -- ----------------------------------------------------------------
        -- ElixirLS: enabled, pointing at the existing system install.
        -- ----------------------------------------------------------------
        elixirls = {
            enable = true,

            -- Skip elixir-tools' auto-install path: a working ElixirLS
            -- already lives at ~/.local/share/elixir-ls/language_server.sh
            -- on this machine. Without cmd, elixir-tools would clone the
            -- elixir-ls repo into ~/.cache and compile it on first run --
            -- harmless but wasteful given we already have a build.
            --
            -- The expand() is what resolves ~ -> $HOME at runtime;
            -- elixir-tools passes the value through to vim.lsp.config
            -- which does NOT do tilde expansion itself.
            cmd = vim.fn.expand("~/.local/share/elixir-ls/language_server.sh"),

            -- ------------------------------------------------------------
            -- ElixirLS server settings.
            --
            -- Routed through elixirls.settings(...) (NOT a raw table)
            -- because elixir-tools wraps the values in the LSP's
            -- ["elixirLS"] namespace and applies a couple of internal
            -- defaults around them. Skipping the helper would send the
            -- bare keys at the top level and ElixirLS would silently
            -- ignore them.
            --
            -- All four are preserved from the previous define_server
            -- setup. Adjust freely; these are not load-bearing on the
            -- migration itself.
            -- ------------------------------------------------------------
            settings = elixirls.settings({
                -- Run Dialyzer (Erlang's static analyzer) over the
                -- project. Catches real type / pattern-match bugs the
                -- compiler doesn't, at the cost of a one-time PLT build
                -- on first project open (can take minutes on large
                -- umbrella apps; subsequent opens are fast).
                dialyzerEnabled = true,

                -- Don't auto-run `mix deps.get` when the LSP starts.
                -- Leaving this on triggers network reaches every time
                -- you open a file in a fresh checkout, which is mostly
                -- noise; do `mix deps.get` manually when you actually
                -- want fresh deps.
                fetchDeps = false,

                -- Compute "Run test" / "Run module tests" codelens above
                -- ExUnit test functions and modules. Combined with
                -- :ElixirOutputPanel below for the result view.
                --
                -- NOTE (2026-08-14): this setting makes the SERVER
                -- compute the lenses; display is a separate concern.
                -- UNLIKE ocamllsp / elp (whose lenses really were
                -- invisible until their opt-in fix), these lenses were
                -- always displayed: elixir-tools' own internal
                -- on_attach wires vim.lsp.codelens.refresh() autocmds
                -- (BufEnter / CursorHold / InsertLeave). refresh() is
                -- DEPRECATED on Neovim 0.12 (removal slated for 0.13),
                -- which has two consequences:
                --   * the one-time "codelens.refresh is deprecated"
                --     notice in Elixir buffers each session comes from
                --     UPSTREAM elixir-tools, not this config;
                --   * when 0.13 drops refresh(), upstream's display
                --     path dies. The helpers.enable_codelens chained in
                --     our on_attach below is the framework-correct
                --     opt-in that keeps lenses rendering regardless -
                --     added as future-proofing, not as a fix.
                --
                -- Unlike the OCaml / Erlang lenses (informational type
                -- signatures), these are RUNNABLE commands. No key maps
                -- vim.lsp.codelens.run() yet - run tests via :Mix test
                -- for now, or add such a map if click-to-run is missed.
                enableTestLenses = true,

                -- Offer @spec annotations as completion suggestions
                -- where Dialyzer has inferred a type. Useful when
                -- documenting library code; harmless when ignored.
                suggestSpecs = true,
            }),

            -- ------------------------------------------------------------
            -- Per-LSP on_attach.
            --
            -- elixir-tools gives each LSP its own on_attach (NOT one
            -- shared across backends). We chain helpers.standard_on_attach
            -- here so the same buffer-local LSP keymaps (K / gd / gt /
            -- gi / <C-k> / gl / <leader>rn / <leader>ca) install on
            -- Elixir buffers as on every other LSP-attached buffer.
            --
            -- No K override here, unlike the Rust setup: ElixirLS doesn't
            -- ship a "hover with code actions" extension worth replacing
            -- the standard vim.lsp.buf.hover with. Plain K stays plain K.
            --
            -- enable_codelens (2026-08-14) future-proofs the display of
            -- the enableTestLenses lenses above - see the NOTE there for
            -- why it is belt-and-suspenders today and load-bearing once
            -- Neovim 0.13 removes the deprecated refresh() that
            -- elixir-tools itself still calls.
            -- ------------------------------------------------------------
            on_attach = function(client, bufnr)
                helpers.standard_on_attach(client, bufnr)
                helpers.enable_codelens(client, bufnr)
            end,
        },

        -- ----------------------------------------------------------------
        -- Projectionist: Phoenix-aware file scaffolding.
        --
        -- Adds :Esource / :Etest / :Econtroller / :Eview / :Eliveview
        -- and friends. Each command opens (or creates) the conventional
        -- file for the current context -- e.g. inside a Phoenix project
        -- :Etest on lib/foo/bar.ex opens test/foo/bar_test.exs. The
        -- commands quietly no-op outside a Mix project, so leaving this
        -- on costs nothing in non-Elixir buffers.
        -- ----------------------------------------------------------------
        projectionist = {
            enable = true,
        },
    })
end

return M
