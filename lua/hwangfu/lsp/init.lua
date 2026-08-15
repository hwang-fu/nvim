-- ============================================================================
-- LSP module entrypoint.
--
-- This is the only file outside lsp/ that any other module touches:
--     require("hwangfu.lsp").setup()
--
-- Directory layout:
--   lsp/init.lua           - this file. Filetypes + diagnostic UI + wire-up.
--   lsp/helpers.lua        - shared toolbox: capabilities, on_attach variants,
--                            define_server. Every server file requires it.
--   lsp/servers/<name>.lua - one file per language server, each exposing a
--                            setup() function. The SERVERS table below lists
--                            them in registration order.
--   lsp/format.lua         - format-on-save autocmds (LSP-driven + external
--                            CLI formatters) plus the binary-presence warning
--                            that fires at VimEnter.
--   lsp/linters.lua        - external diagnostic-producing CLIs (shellcheck,
--                            hadolint, checkmake) wrapped as vim.diagnostic
--                            sources.
--
-- What M.setup() does, in order:
--   1. vim.filetype.add() for filetypes Neovim does not ship rules for
--      (Containerfile, nginx configs, Verilog, VHDL).
--   2. vim.diagnostic.config() for the global diagnostic UI (signs,
--      virtual_text, float border, ...).
--   3. require + setup() each entry in SERVERS.
--   4. require + setup() the format module (autocmds + binary check).
--   5. require + setup() the linters module.
--
-- Treesitter activation is NOT in here - it lives in the treesitter plugin's
-- `config = function() ... end` in lua/hwangfu/plugins/spec/treesitter.lua, where it
-- attaches to every filetype via `pattern = "*"`.
--
-- Adding a new server:
--   1. Create lsp/servers/<name>.lua exposing M.setup() (copy a small one
--      like fortls.lua as a template).
--   2. Add "<name>" to the SERVERS table below.
--   3. Restart Neovim. No other file needs touching.
--
-- Removed servers (kept here as commented breadcrumbs so future re-enables
-- have context):
--   * zls (Zig)             - no longer actively writing Zig. To re-enable:
--                             add lsp/servers/zls.lua, then add "zls" to
--                             SERVERS below.
--   * nginx-language-server - broken under Python 3.14 + pydantic v2
--                             (RuntimeError: no validator found for
--                             pydantic.fields.UndefinedType). To re-enable:
--                             add lsp/servers/nginx_ls.lua, then add
--                             "nginx_ls" to SERVERS below.
--
-- Servers NOT in SERVERS by design:
--   * rust_analyzer         - owned by the rustaceanvim plugin (see
--                             plugins/spec/rustaceanvim.lua and lsp/servers/
--                             rust_analyzer.lua). rustaceanvim does its
--                             own vim.lsp.config + vim.lsp.enable, and
--                             calling helpers.define_server here would
--                             race it. The server module is invoked
--                             from the plugin spec's `init` hook
--                             instead of from this SERVERS loop.
--   * elixirls              - owned by the elixir-tools.nvim plugin
--                             (see plugins/spec/elixir_tools.lua and
--                             lsp/servers/elixirls.lua). Same reasoning
--                             as rust_analyzer: the plugin owns LSP
--                             setup end-to-end via require("elixir").
--                             setup({...}). Invoked from the plugin
--                             spec's `config` hook (not `init`, because
--                             elixir-tools needs to be on the runtime-
--                             path before require("elixir") resolves).
--   * hls                   - owned by the haskell-tools.nvim plugin
--                             (see plugins/spec/haskell_tools.lua and
--                             lsp/servers/hls.lua). Same author and
--                             pattern as rust_analyzer / rustaceanvim:
--                             configuration goes through vim.g.
--                             haskell_tools and is set from the plugin
--                             spec's `init` hook.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- Server registry
--
-- Each name corresponds to a file at lsp/servers/<name>.lua exposing
-- M.setup(). Order is preserved when iterating below: nothing currently
-- depends on it, but keeping it stable makes the startup log easier to read.
-- ----------------------------------------------------------------------------
local SERVERS = {
    "clangd",
    "fortls",
    "ts_ls",
    "ocamllsp",
    "buf_ls",
    "pyright",
    "perlnavigator",
    "gopls",
    -- rust_analyzer is owned by rustaceanvim; see the "Servers NOT in
    -- SERVERS by design" note in the header comment above.
    "lua_ls",
    -- hls is owned by haskell-tools.nvim; see the "Servers NOT in
    -- SERVERS by design" note in the header comment above.
    -- elixirls is owned by elixir-tools.nvim; see the "Servers NOT in
    -- SERVERS by design" note in the header comment above.
    "elp",
    "vue_ls",
    "bashls",
    "html",
    "cssls",
    "jsonls",
    "yamlls",
    "dockerls",
    "clojure_lsp",
    "racket_langserver",
    "fennel_ls",
    "taplo",
    "autotools_ls",
    "verible",
}

-- ----------------------------------------------------------------------------
-- Filetype detection augmentations for files Neovim does not ship rules for.
-- ----------------------------------------------------------------------------
local function setup_filetypes()
    vim.filetype.add({
        filename = {
            ["Containerfile"] = "dockerfile",

            ["nginx.conf"] = "nginx",
            ["fastcgi.conf"] = "nginx",
            ["mime.types"] = "nginx",
        },

        extension = {
            -- Verilog / SystemVerilog
            v = "verilog",
            vh = "verilog",
            sv = "systemverilog",
            svh = "systemverilog",
            -- VHDL
            vhd = "vhdl",
            vhdl = "vhdl",
        },

        pattern = {
            ["Containerfile%..*"] = "dockerfile",

            [".*/nginx/.*%.conf"] = "nginx",
            [".*/nginx/conf%.d/.*%.conf"] = "nginx",
            [".*/nginx/sites%-available/.*"] = "nginx",
            [".*/nginx/sites%-enabled/.*"] = "nginx",
        },
    })
end

-- ----------------------------------------------------------------------------
-- Global diagnostic UI (signs, virtual_text, float border, severity sort).
--
-- Called once from M.setup(), NOT per-buffer: vim.diagnostic.config()'s
-- second arg is a *namespace* ID (not a bufnr), so passing a buffer number
-- would silently create per-namespace overrides rather than buffer-scoped
-- settings. One global call covers every buffer.
-- ----------------------------------------------------------------------------
local function setup_diagnostic_ui()
    vim.diagnostic.config({
        virtual_text = true, -- inline error messages at end of line
        signs = true, -- gutter signs (E/W/I/H by default)
        underline = true, -- underline the offending span
        update_in_insert = false, -- don't re-lint while typing; less flicker
        severity_sort = true, -- errors above warnings, etc.
        float = {
            border = "rounded", -- the gl / hover popup border
            source = true, -- show which server / linter produced each item
        },
    })
end

-- ----------------------------------------------------------------------------
-- Public entrypoint. Called from lua/hwangfu/init.lua.
-- ----------------------------------------------------------------------------
function M.setup()
    setup_filetypes()
    setup_diagnostic_ui()

    -- Servers: each module's setup() does its own vim.lsp.config(...) +
    -- vim.lsp.enable(...) via helpers.define_server().
    for _, name in ipairs(SERVERS) do
        require("hwangfu.lsp.servers." .. name).setup()
    end

    -- Format-on-save autocmds + missing-binary warning.
    require("hwangfu.lsp.format").setup()

    -- External linters (shellcheck, hadolint, checkmake) as vim.diagnostic
    -- sources.
    require("hwangfu.lsp.linters").setup()
end

return M
