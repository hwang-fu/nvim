-- ============================================================================
-- cssls: vscode-css-language-server. Also handles SCSS and LESS.
-- Uses basic_on_attach (no inlay hints).
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("cssls", {
        cmd = {
            "vscode-css-language-server",
            "--stdio",
        },
        filetypes = {
            "css",
            "scss",
            "less",
        },
        root_markers = {
            "package.json",
            ".git",
        },
        settings = {
            css = {
                validate = true,
            },
            scss = {
                validate = true,
            },
            less = {
                validate = true,
            },
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
