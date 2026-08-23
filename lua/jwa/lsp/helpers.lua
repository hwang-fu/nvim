-- ============================================================================
-- LSP helpers: capabilities, keymaps, on_attach variants, and define_server.
--
-- This module is the shared toolbox for every server file in lsp/servers/.
-- Each server file starts with
--     local helpers = require("jwa.lsp.helpers")
-- and then calls helpers.define_server(...). Application code never touches
-- this module directly; the lsp/init.lua entrypoint goes through M.setup()
-- which in turn requires each server module.
--
-- What's in here:
--   * make_capabilities      - the capability table advertised to servers.
--                              Starts from Neovim's defaults and layers on
--                              blink.cmp's snippet / additionalTextEdits
--                              bits when blink is present.
--   * set_common_keymaps     - the buffer-local LSP navigation keys (gd, K,
--                              <leader>rn, <leader>ca, <C-k>, ...). Called
--                              from on_attach so the maps only exist on the
--                              buffer that an LSP attached to.
--   * set_diagnostic_keymaps - gl (open diagnostic float). [d / ]d are
--                              deliberately not mapped here; Neovim 0.11
--                              already ships identical built-in defaults.
--   * disable_diagnostics    - replace publishDiagnostics with a no-op
--                              (used by clangd to silence its chatty output).
--   * enable_inlay_hints     - guarded for Neovim < 0.10 where the API does
--                              not exist.
--   * enable_codelens        - per-buffer codelens opt-in (codelens is OFF
--                              by default, unlike semantic tokens). Called
--                              from the on_attach of servers whose lenses
--                              we want rendered (ocamllsp, elp, elixirls).
--   * standard_on_attach     - the default attach behavior: keymaps + inlay
--                              hints. Used by most servers. (Semantic tokens
--                              need no wiring here - see the note in that
--                              function.)
--   * basic_on_attach        - same minus inlay hints. For HTML / CSS / JSON
--                              / YAML / etc. where line-level type info does
--                              not apply or just adds clutter.
--   * define_server          - the main entry point used by every server
--                              file. Wraps vim.lsp.config(name, cfg) +
--                              vim.lsp.enable(name), filling in
--                              blink-augmented capabilities and
--                              standard_on_attach when the caller does not
--                              override them.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- Capabilities
-- ----------------------------------------------------------------------------

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

-- ----------------------------------------------------------------------------
-- Keymaps (buffer-local, installed from on_attach)
-- ----------------------------------------------------------------------------

-- LSP navigation / refactor keymaps, scoped to the buffer the server attaches
-- to. These are the conventional Vim mappings (gd / K) plus a couple of
-- leader shortcuts (<leader>rn rename, <leader>ca code action). <C-k> works
-- in both normal and insert mode because signature help is most useful while
-- typing.
--
-- Bare `gr` is deliberately never mapped. Neovim 0.11 ships the default
-- LSP mappings grn / gra / grr / gri (rename / code action / references /
-- implementation); a manual `gr` map would be a prefix of all four and
-- stall each for `timeoutlen` (~1s). The full-length `grr` is fair game
-- though - it is overridden below to peek references via Glance.
function M.set_common_keymaps(bufnr)
    local map = function(mode, lhs, rhs)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true })
    end

    -- grr upgraded (2026-08-15): the built-in lists references into the
    -- quickfix list; Glance peeks them in an embedded panel instead.
    -- Same mnemonic, better view - and <C-q> inside the panel still
    -- sends everything to quickfix when process-all mode is wanted.
    map("n", "grr", "<Cmd>Glance references<CR>")

    map("n", "gd", vim.lsp.buf.definition)
    map("n", "gD", vim.lsp.buf.declaration)
    map("n", "gt", vim.lsp.buf.type_definition)
    map("n", "gi", vim.lsp.buf.implementation)
    map("n", "K", vim.lsp.buf.hover)
    map("n", "<leader>rn", vim.lsp.buf.rename)
    map("n", "<leader>ca", vim.lsp.buf.code_action)
    map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help)
end

-- Diagnostic navigation: gl opens the floating diagnostic window for the
-- current line.
--
-- [d / ]d (jump to previous / next diagnostic) are deliberately NOT mapped
-- here. Neovim 0.11 ships them as built-in defaults that do exactly the same
-- thing, so re-mapping them would only be dead duplication.
function M.set_diagnostic_keymaps(bufnr)
    local map = function(mode, lhs, rhs)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true })
    end
    map("n", "gl", vim.diagnostic.open_float)
end

-- ----------------------------------------------------------------------------
-- Per-client tweaks
-- ----------------------------------------------------------------------------

-- Replace publishDiagnostics with a no-op: silences a server's diagnostics
-- at the protocol layer without disabling the rest of the LSP integration.
-- Currently UNUSED - clangd was the only caller until 2026-08-23, when the
-- user asked for its diagnostics back. Kept for the next chatty server.
function M.disable_diagnostics(client)
    client.handlers["textDocument/publishDiagnostics"] = function() end
end

-- Inlay hints (parameter names, inferred types, etc.) became a first-class
-- API in Neovim 0.10+. Guarded by a feature check so the helper is safe to
-- call on older nvim versions where vim.lsp.inlay_hint does not exist.
function M.enable_inlay_hints(bufnr)
    if vim.lsp.inlay_hint then
        vim.lsp.inlay_hint.enable(true, {
            bufnr = bufnr,
        })
    end
end

-- Codelens display: per-buffer OPT-IN, the mirror image of semantic tokens
-- (which the runtime enables globally - see the note in standard_on_attach).
-- The single enable() call flips the buffer's flag in Neovim 0.12's
-- capability framework; the framework then requests lenses on attach and
-- re-requests them automatically (debounced) on every buffer change - no
-- refresh autocmds needed. Timing: on_attach callbacks run BEFORE the core
-- client's scheduled capability-attach pass, by design, precisely so they
-- can opt capabilities in or out; the pass then sees the flag set here.
-- Guarded on the server actually advertising lenses so servers without
-- them are unaffected.
-- Codelens title sanitizer (2026-08-21, user report). ocamllsp can send
-- MULTI-LINE lens titles - long type signatures with embedded newlines -
-- and the lens virtual line renders each newline as a ^@ glyph
-- ("year:int ->^@day:int -> ...").
--
-- Seam choice, learned the hard way twice the same day: on 0.12,
-- vim.lsp.codelens.display/save/on_codelens are DEPRECATED STUBS that
-- ignore their arguments - wrapping them intercepts nothing (a first
-- version of this sanitizer did exactly that; its synthetic test only
-- proved the wrapper mutated its own input). The framework's real path
-- is Provider:request -> client:request('textDocument/codeLens', ...)
-- with an explicit callback, bypassing client.handlers. So the wrap
-- goes on the CLIENT's request method, narrowly: codeLens responses
-- only, titles flattened before the framework stores them. The
-- _jwa_lens_flatten_hits counter on the client exists so tests (and
-- :checkhealth debugging) can PROVE the live path routes through the
-- wrap - the capture(...) rust shim shipped without that proof and
-- turned out dead on arrival.
local function install_codelens_sanitizer(client)
    if client._jwa_lens_flatten then
        return
    end
    client._jwa_lens_flatten = true
    client._jwa_lens_flatten_hits = 0

    local orig_request = client.request
    client.request = function(self, method, params, handler, bufnr)
        if method ~= "textDocument/codeLens" or not handler then
            return orig_request(self, method, params, handler, bufnr)
        end
        return orig_request(self, method, params, function(err, result, ctx)
            self._jwa_lens_flatten_hits = self._jwa_lens_flatten_hits + 1
            for _, lens in ipairs(result or {}) do
                local cmd = lens.command
                if cmd and cmd.title and cmd.title:find("\n", 1, true) then
                    cmd.title = cmd.title:gsub("%s*\n%s*", " ")
                end
            end
            return handler(err, result, ctx)
        end, bufnr)
    end
end

function M.enable_codelens(client, bufnr)
    if not client.server_capabilities.codeLensProvider then
        return
    end
    install_codelens_sanitizer(client)
    vim.lsp.codelens.enable(true, {
        bufnr = bufnr,
    })
end

-- ----------------------------------------------------------------------------
-- on_attach variants
-- ----------------------------------------------------------------------------

-- The "standard" on_attach: keymaps, diagnostics, and inlay hints. Most
-- servers want exactly this, which is why define_server defaults to it.
--
-- Semantic tokens: nothing to do here, on purpose. On Neovim 0.12 the
-- vim.lsp.semantic_tokens module ENABLES ITSELF GLOBALLY when loaded
-- (M.enable(true) at module scope, runtime semantic_tokens.lua), and the
-- core client loads that module for every started client - so highlighting
-- auto-attaches wherever the server advertises the capability, with no
-- call from us. (Codelens is the opposite: opt-in per buffer - see
-- lsp/servers/ocamllsp.lua.) This function previously called the
-- per-buffer vim.lsp.semantic_tokens.start(bufnr, id) - a redundant
-- re-assertion of that default, and deprecated in 0.12 (removal slated
-- for 0.13). Removed 2026-08 with no behavior change (verified: tokens
-- still delivered after removal). To opt OUT for a chatty server, call
-- vim.lsp.semantic_tokens.enable(false, { client_id = client.id }) from
-- that server's own on_attach.
function M.standard_on_attach(_, bufnr) -- (client, bufnr) contract; client unused
    M.set_common_keymaps(bufnr)
    M.set_diagnostic_keymaps(bufnr)
    M.enable_inlay_hints(bufnr)
end

-- Same as standard_on_attach but without inlay hints. Used for servers whose
-- inlay hints are noisy / distracting (HTML / CSS / JSON / YAML / Docker /
-- shell), where the type-info-by-line idea does not really apply or just adds
-- clutter. (Semantic tokens: default-on, same note as standard_on_attach.)
function M.basic_on_attach(_, bufnr) -- (client, bufnr) contract; client unused
    M.set_common_keymaps(bufnr)
    M.set_diagnostic_keymaps(bufnr)
end

-- ----------------------------------------------------------------------------
-- define_server: the main entry point used by every server file
-- ----------------------------------------------------------------------------

-- Shorthand for "define this server and enable it." Two roles:
--   1. Hides the boilerplate of vim.lsp.config(name, cfg) + vim.lsp.enable(name)
--      (the modern Neovim 0.11+ API, replacing the old lspconfig setup{} call).
--   2. Fills in blink-aware capabilities and the standard on_attach when the
--      caller does not specify them, so most servers reduce to "here's my cmd
--      and filetypes, handle the rest." Servers that want different behavior
--      pass their own `capabilities = ...` or `on_attach = ...`.
function M.define_server(name, cfg)
    cfg.capabilities = cfg.capabilities or M.make_capabilities()
    cfg.on_attach = cfg.on_attach or M.standard_on_attach
    vim.lsp.config(name, cfg)
    vim.lsp.enable(name)
end

return M
