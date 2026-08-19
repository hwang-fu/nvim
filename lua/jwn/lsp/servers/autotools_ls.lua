-- ============================================================================
-- autotools_ls: language server for Make / Automake / Autoconf.
--
-- Linting comes from checkmake (see lsp/linters.lua); this LSP provides
-- hover / completion / goto-definition only. Uses basic_on_attach (no
-- inlay hints).
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("autotools_ls", {
        cmd = { "autotools-language-server" },
        filetypes = { "make", "automake", "config" },
        root_markers = {
            "Makefile",
            "Makefile.am",
            "configure.ac",
            ".git",
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
