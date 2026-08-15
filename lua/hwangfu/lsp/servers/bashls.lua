-- ============================================================================
-- bashls: Bash / POSIX sh language server.
--
-- Uses basic_on_attach (no inlay hints) - bash does not have rich enough
-- type info to make inlay hints meaningful. Linting comes from shellcheck
-- (see lsp/linters.lua); formatting comes from shfmt (see lsp/format.lua).
-- ============================================================================

local helpers = require("hwangfu.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("bashls", {
        cmd = {
            "bash-language-server",
            "start",
        },
        filetypes = {
            "sh",
            "bash",
        },
        root_markers = {
            ".git",
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
