-- ============================================================================
-- gopls: Go language server.
--
-- semanticTokens = true makes gopls's syntax highlighting flow through
-- Neovim's semantic-tokens layer (which sits above treesitter at priority
-- 125, see `:h vim.hl.priorities`). The colors you see in Go buffers are
-- therefore gopls's type-aware ones rather than treesitter's grammar-only
-- ones. Format-on-save runs gopls's gofmt-equivalent (see lsp/format.lua).
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("gopls", {
        cmd = {
            "gopls",
        },
        filetypes = {
            "go",
            "gomod",
            "gowork",
            "gotmpl",
        },
        root_markers = {
            "go.mod",
            "go.work",
            ".git",
        },
        settings = {
            gopls = {
                semanticTokens = true,
                analyses = {
                    unusedparams = true,
                    shadow = true,
                },
                staticcheck = true,
                gofumpt = true,
                hints = {
                    assignVariableTypes = true,
                    compositeLiteralFields = true,
                    compositeLiteralTypes = true,
                    constantValues = true,
                    functionTypeParameters = true,
                    parameterNames = true,
                    rangeVariableTypes = true,
                },
            },
        },
    })
end

return M
