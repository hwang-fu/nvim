-- ============================================================================
-- pyright: Python type checker / LSP.
--
-- typeCheckingMode = "off" is intentional: linting / formatting are
-- delegated to ruff (see lsp/format.lua), and we only want pyright's
-- navigation / hover / completion. Flip to "basic" or "strict" to get type
-- errors in your editor as well.
-- ============================================================================

local helpers = require("hwangfu.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("pyright", {
        cmd = {
            "pyright-langserver",
            "--stdio",
        },
        filetypes = { "python" },
        root_markers = {
            "pyproject.toml",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
            "Pipfile",
            "pyrightconfig.json",
            ".git",
        },
        settings = {
            python = {
                analysis = {
                    autoSearchPaths = true,
                    useLibraryCodeForTypes = true,
                    diagnosticMode = "workspace",
                    typeCheckingMode = "off",
                },
            },
        },
    })
end

return M
