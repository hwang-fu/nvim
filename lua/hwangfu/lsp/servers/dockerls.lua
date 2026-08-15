-- ============================================================================
-- dockerls: docker-langserver, for Dockerfile / Containerfile.
--
-- Lint diagnostics come from hadolint (see lsp/linters.lua); this LSP
-- provides completion / hover only. Uses basic_on_attach (no inlay hints).
-- ============================================================================

local helpers = require("hwangfu.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("dockerls", {
        cmd = {
            "docker-langserver",
            "--stdio",
        },
        filetypes = {
            "dockerfile",
        },
        root_markers = {
            "Dockerfile",
            ".git",
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
