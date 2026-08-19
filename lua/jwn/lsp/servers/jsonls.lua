-- ============================================================================
-- jsonls: vscode-json-language-server. Handles JSON and JSONC (with comments).
-- Uses basic_on_attach (no inlay hints). Format-on-save is LSP-driven (see
-- the *.json / *.jsonc entries in lsp/format.lua).
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("jsonls", {
        cmd = {
            "vscode-json-language-server",
            "--stdio",
        },
        filetypes = {
            "json",
            "jsonc",
        },
        root_markers = {
            ".git",
        },
        init_options = {
            provideFormatter = true,
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
