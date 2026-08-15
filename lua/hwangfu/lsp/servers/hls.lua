-- ============================================================================
-- haskell-language-server (HLS), via haskell-tools.nvim.
--
-- Ownership of the HLS client passes to haskell-tools.nvim: the plugin
-- does its own vim.lsp.config / vim.lsp.enable using options read from
-- vim.g.haskell_tools. So this module does NOT call
-- helpers.define_server(...) like the other server files; doing so
-- would race haskell-tools and either start a duplicate client or
-- clobber its :Haskell user commands. The plugin README is explicit
-- about this conflict.
--
-- This module is invoked from the haskell-tools.nvim plugin spec's
-- `init` hook in lua/hwangfu/plugins/spec/haskell_tools.lua (NOT from lsp/init.lua's
-- SERVERS loop). The `init` ordering guarantees vim.g.haskell_tools is
-- populated before haskell-tools' filetype handler registers itself.
--
-- What this file owns:
--   * vim.g.haskell_tools - HLS settings (Ormolu formatter, whole-
--     project loading), capabilities, on_attach (chains
--     helpers.standard_on_attach so K / gd / gt / <C-k> install the
--     same way as on every other LSP buffer, then overrides K with
--     haskell-tools' Hoogle-aware hover).
--
-- What haskell-tools.nvim adds, browseable with `:Haskell <Tab>`:
--   * hls evalAll        evaluate `-- >>> expr` style doctest comments
--                        inline and write the result back into the
--                        buffer (HLS Eval plugin).
--   * repl toggle [file] toggle a GHCi terminal scoped to the project
--                        (or a single file with [file] argument).
--                        repl quit / load / reload manage the session.
--   * repl cword_type    GHCi :type of the symbol under cursor; faster
--                        than full LSP hover for type-only queries.
--   * repl cword_info    same but GHCi :info (typeclass instances,
--                        kind, etc.).
--   * hover              hover with Hoogle / open-docs / open-source /
--                        find-refs as clickable code actions. Used as
--                        our K override below.
--   * projectFile        open cabal.project / stack.yaml.
--   * packageYaml /
--     packageCabal       jump to package metadata.
--   * definition         LSP go-to-def with Hoogle fallback when HLS
--                        can't find the symbol locally (typically
--                        because the source isn't loaded into the
--                        current session, e.g. an unimported library).
--   * log openLog /
--     openHlsLog         direct access to plugin / HLS log files.
--
-- And via the Telescope extension (loaded in lua/hwangfu/telescope.lua
-- via `pcall(telescope.load_extension, "ht")`):
--   * :Telescope ht package_files     all files in the current package
--   * :Telescope ht package_hsfiles   .hs files only
--   * :Telescope ht package_grep      grep within the package
--   * :Telescope ht package_hsgrep    grep restricted to .hs files
--   * :Telescope ht hoogle_signature  Hoogle search by type signature
--
-- Difference from the previous helpers.define_server-based setup:
--   * `cmd`, `filetypes`, and `root_markers` are dropped: haskell-tools
--     picks sane defaults (haskell-language-server-wrapper on $PATH,
--     attaches on `haskell` / `lhaskell`, roots at hie.yaml /
--     stack.yaml / cabal.project / *.cabal / package.yaml / .git --
--     the same list we used to pass through).
-- ============================================================================

local helpers = require("hwangfu.lsp.helpers")

local M = {}

function M.setup()
    vim.g.haskell_tools = {
        -- Editor-side options. Defaults are good across the board
        -- (log level, hover focus behavior, REPL backend selection
        -- of toggleterm / builtin / etc.); leaving this empty so the
        -- plugin's own defaults apply.
        tools = {},

        hls = {
            -- blink.cmp's snippet / additionalTextEdits bits, same
            -- as every other server in this config.
            capabilities = helpers.make_capabilities(),

            on_attach = function(client, bufnr)
                helpers.standard_on_attach(client, bufnr)

                -- --- K override: enhanced hover with Hoogle actions --
                --
                -- This is a DELIBERATE behavior change on Haskell
                -- buffers only, mirroring the K override in
                -- lua/hwangfu/lsp/servers/rust_analyzer.lua.
                --
                -- helpers.set_common_keymaps (called via
                -- helpers.standard_on_attach above) has just bound K
                -- to vim.lsp.buf.hover, the same standard LSP hover
                -- every other server in this config uses. The block
                -- below replaces that binding with haskell-tools'
                -- `:Haskell hover` -- but only on the HLS-attached
                -- buffer, via the `buffer = bufnr` option.
                --
                -- Why bother:
                --   Plain vim.lsp.buf.hover shows HLS's hover content
                --   (type signature, docs, source if available).
                --   `:Haskell hover` shows the same content AND adds
                --   a header of clickable code actions inferred for
                --   the symbol -- typically:
                --     * Hoogle Search (search Hoogle for this type)
                --     * Open docs.haskell.org / Hackage page
                --     * Open source on Hackage in a browser
                --     * Find references
                --     * Go to type / definition
                --   The Hoogle search is the killer entry: it works
                --   even when HLS doesn't have the surrounding library
                --   loaded.
                --
                -- Scope: BUFFER-LOCAL via `buffer = bufnr`. Non-Haskell
                -- LSP buffers (Rust, Go, Python, Lua, ...) keep K =
                -- vim.lsp.buf.hover (or, on Rust, the rustaceanvim
                -- variant). The cross-buffer asymmetry is intentional.
                --
                -- To revert: delete this vim.keymap.set block. The
                -- earlier helpers.set_common_keymaps K binding becomes
                -- the live one (it was overwritten, not removed).
                vim.keymap.set("n", "K", function()
                    vim.cmd.Haskell({ "hover" })
                end, {
                    buffer = bufnr,
                    silent = true,
                    desc = "LSP hover with haskell-tools Hoogle actions",
                })
            end,

            -- ----------------------------------------------------------
            -- HLS server settings.
            --
            -- Same two keys we previously passed through `settings =
            -- { haskell = { ... } }` to helpers.define_server; the
            -- shape under `default_settings.haskell.*` matches HLS's
            -- LSP `workspace/configuration` schema.
            -- ----------------------------------------------------------
            default_settings = {
                haskell = {
                    -- Pick which formatter HLS runs on
                    -- vim.lsp.buf.format(). HLS bundles ormolu,
                    -- fourmolu, stylish-haskell, brittany, and floskell;
                    -- this flag selects one. Ormolu is the modern
                    -- community default (zero-config, opinionated,
                    -- maintained).
                    formattingProvider = "ormolu",

                    -- Have HLS load the entire project at startup so
                    -- cross-module diagnostics, renames, and find-refs
                    -- work the moment any buffer in the project is
                    -- open. Without this, HLS lazy-loads only the
                    -- module the cursor is in plus its direct deps,
                    -- missing some warnings and slowing down the first
                    -- rename / find-refs in each new module. Costs more
                    -- memory on large projects; usually the right trade
                    -- for interactive editing.
                    checkProject = true,
                },
            },
        },

        -- DAP integration: empty placeholder. This config ships no
        -- debugger stack (the nvim-dap setup was removed 2026-08-15 at
        -- the user's request). If one ever returns, haskell-tools
        -- auto-detects nvim-dap + haskell-debug-adapter and `:Haskell
        -- dap` subcommands appear. See :h haskell-tools-dap.
        dap = {},
    }
end

return M
