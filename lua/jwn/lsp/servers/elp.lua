-- ============================================================================
-- elp: Erlang Language Platform (WhatsApp's Erlang LSP, replaces erlang_ls).
--
-- Capabilities verified against elp 1.1.0 on 2026-08-14: hover,
-- completion, semantic tokens, inlay hints (enabled client-side by
-- standard_on_attach) and codelens are all advertised;
-- documentFormattingProvider is FALSE - ELP does not format. Two
-- consequences wired up that day:
--
--   * Formatting: "*.erl" / "*.hrl" were removed from the LSP-driven
--     format-on-save list (every save was a silent no-op) and Erlang now
--     formats through the external erlfmt CLI in lsp/format.lua
--     (~/.local/bin/erlfmt, built from the WhatsApp repo with
--     `rebar3 escriptize`). If a future ELP release starts advertising
--     formatting, pick ONE path - do not let both run.
--
--   * Codelens: ELP computed lenses all along, but Neovim renders none
--     without the per-buffer opt-in; on_attach below adds
--     helpers.enable_codelens - the same arrangement as ocamllsp.
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("elp", {
        cmd = {
            "elp",
            "server",
        },
        filetypes = {
            "erlang",
        },
        root_markers = {
            "rebar.config",
            "erlang.mk",
            ".git",
        },
        on_attach = function(client, bufnr)
            helpers.standard_on_attach(client, bufnr)
            helpers.enable_codelens(client, bufnr)
        end,
    })
end

return M
