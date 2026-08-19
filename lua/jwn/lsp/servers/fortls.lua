-- ============================================================================
-- fortls: Fortran language server.
-- Formatting is via fprettify (see lsp/format.lua), not the LSP itself.
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("fortls", {
        cmd = { "fortls" },
        filetypes = {
            "fortran",
        },
        root_markers = {
            ".fortls",
            ".fortls.json",
            ".git",
        },
    })
end

return M
