-- ============================================================================
-- perlnavigator: Perl language server.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("perlnavigator", {
        cmd = {
            "perlnavigator",
            "--stdio",
        },
        filetypes = {
            "perl",
        },
        root_markers = {
            "Makefile.PL",
            "Build.PL",
            "cpanfile",
            ".perl-version",
            ".git",
        },
        settings = {
            perlnavigator = {
                perlPath = "perl",
                enableWarnings = true,
                perltidyProfile = "",
                perlcriticProfile = "",
                perlcriticEnabled = true,
            },
        },
    })
end

return M
