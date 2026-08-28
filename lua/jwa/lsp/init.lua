-- ============================================================================
-- LSP module entrypoint.
--
-- This is the only file outside lsp/ that any other module touches:
--     require("jwa.lsp").setup()
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
--   lsp/logrotate.lua      - startup size cap for the shared LSP log
--                            (state/nvim/lsp.log), which core never rotates.
--
-- What M.setup() does, in order:
--   1. vim.filetype.add() for filetypes Neovim does not ship rules for
--      (Containerfile, nginx configs, Verilog, VHDL).
--   2. vim.diagnostic.config() for the global diagnostic UI (signs,
--      virtual_text, float border, ...).
--   3. Override the window/showMessage handler so a server-pushed message
--      can never abort the command it happens to land inside.
--   4. require + setup() each entry in SERVERS.
--   5. require + setup() the format module (autocmds + binary check).
--   6. require + setup() the linters module.
--   7. require + setup() the logrotate module (deferred LSP-log size check).
--
-- Treesitter activation is NOT in here - it lives in the treesitter plugin's
-- `config = function() ... end` in lua/jwa/plugins/spec/treesitter.lua, where it
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
--   * ts_ls                 - replaced by tsgo (2026-08-21): the native
--                             TypeScript 7 LSP (`tsc --lsp --stdio`).
--                             typescript-language-server needs the
--                             JS-based tsserver.js, which typescript@7
--                             no longer ships, so it could not start
--                             at all. See lsp/servers/tsgo.lua.
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
    -- ts_ls was replaced by tsgo; see the "Removed servers" note in
    -- the header comment above.
    "tsgo",
    "ocamllsp",
    "buf_ls",
    "pyright",
    "perlnavigator",
    "gopls",
    -- rust_analyzer is owned by rustaceanvim; see the "Servers NOT in
    -- SERVERS by design" note in the header comment above.
    "lua_ls",
    "jdtls",
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
    "cmake_ls",
    "verible",
}

-- Exported for the :checkhealth jwa report (lua/jwa/health.lua),
-- which probes each server's binary. Same table, not a copy.
M.SERVERS = SERVERS

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
-- window/showMessage: a server-pushed message must never abort a command.
--
-- Neovim's default handler notifies at whatever severity the server asked
-- for, and vim.notify passes `err = true` to nvim_echo for ERROR and only
-- for ERROR (runtime/lua/vim/_core/editor.lua). An error message raised
-- while an autocmd runs underneath an ex command sets Vim's error state,
-- which ABORTS the enclosing command -- and under BufWritePre that means
-- the write is abandoned: buffer still modified, file never reaches disk.
--
-- The collision is routine, not a freak case. vim.lsp.buf.format() with
-- async = false blocks on request_sync, which pumps incoming traffic while
-- it waits, so every format-on-save opens a window in which any message
-- the server pushes lands inside BufWritePre. HLS pushes one on each
-- ormolu parse failure -- that is, on every save of a half-typed Haskell
-- buffer -- and each one silently cost a save.
--
-- Three choices below, all load-bearing:
--
--   * ERROR is downgraded to WARN. This is the entire fix: with
--     err = false the echo cannot abort anything. Do NOT "restore" the
--     level to match params.type -- that severity is precisely what
--     breaks. Levels other than Error are already harmless and keep
--     their meaning.
--   * One line. Whitespace is squashed and the result cut to the window
--     width, because a message that wraps forces the hit-enter prompt
--     even when it is not an error. Little is lost: a server reporting a
--     real fault also publishes it as a diagnostic on the offending line.
--   * vim.schedule. Keeps the notification out of the command chain
--     altogether, so it cannot pile up behind the "N lines, M bytes
--     written" message that :write prints in the same command.
--
-- Cost: a genuinely fatal server message now paints yellow rather than
-- red and is easier to miss. Worth it -- a notification the server sent
-- on its own schedule has no business cancelling the user's command.
--
-- The GLOBAL table is the one that reaches HLS. haskell-tools.nvim hands
-- its client a handlers table of its own, but leaves it empty except on
-- cabal files, and dispatch falls back to vim.lsp.handlers per call.
-- ----------------------------------------------------------------------------

-- lsp.MessageType -> notify level. 1 (Error) is the deliberate downgrade;
-- the rest map straight across.
local MESSAGE_LEVELS = {
    [1] = vim.log.levels.WARN,
    [2] = vim.log.levels.WARN,
    [3] = vim.log.levels.INFO,
    [4] = vim.log.levels.DEBUG,
    [5] = vim.log.levels.DEBUG,
}

-- Cut to display width, not to a character count: the two diverge as soon
-- as a message carries wide glyphs, and only the width decides whether the
-- echo wraps onto a second line.
local function fit_to_width(text, width)
    if vim.fn.strdisplaywidth(text) <= width then
        return text
    end
    while vim.fn.strchars(text) > 0 and vim.fn.strdisplaywidth(text) > width - 3 do
        text = vim.fn.strcharpart(text, 0, vim.fn.strchars(text) - 1)
    end
    return text .. "..."
end

local function setup_server_messages()
    vim.lsp.handlers["window/showMessage"] = function(_, params, ctx)
        params = params or {}
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        local name = client and client.name or ("id=" .. tostring(ctx.client_id))
        local text = (params.message or ""):gsub("%s+", " ")
        local level = MESSAGE_LEVELS[params.type] or vim.log.levels.INFO
        local line = string.format("LSP[%s] %s", name, text)

        vim.schedule(function()
            vim.notify(fit_to_width(line, math.max(20, vim.o.columns - 1)), level)
        end)
    end
end

-- ----------------------------------------------------------------------------
-- Public entrypoint. Called from lua/jwa/init.lua.
-- ----------------------------------------------------------------------------
function M.setup()
    setup_filetypes()
    setup_diagnostic_ui()
    setup_server_messages()

    -- Servers: each module's setup() does its own vim.lsp.config(...) +
    -- vim.lsp.enable(...) via helpers.define_server().
    for _, name in ipairs(SERVERS) do
        require("jwa.lsp.servers." .. name).setup()
    end

    -- Format-on-save autocmds + missing-binary warning.
    require("jwa.lsp.format").setup()

    -- External linters (shellcheck, hadolint, checkmake) as vim.diagnostic
    -- sources.
    require("jwa.lsp.linters").setup()

    -- LSP log size cap (deferred a few seconds; trims state/nvim/lsp.log
    -- when it outgrows the threshold in logrotate.lua).
    require("jwa.lsp.logrotate").setup()
end

return M
