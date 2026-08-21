-- ============================================================================
-- html: vscode-html-language-server.
--
-- Uses basic_on_attach (no inlay hints). embeddedLanguages keeps CSS and JS
-- inside <style> / <script> blocks working as part of the HTML buffer (so
-- you get completion / hover for them without needing ts_ls / cssls to
-- attach to the same file).
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("html", {
        cmd = {
            "vscode-html-language-server",
            "--stdio",
        },
        filetypes = {
            "html",
            "templ",
        },
        root_markers = {
            "package.json",
            ".git",
        },
        init_options = {
            provideFormatter = true,
            embeddedLanguages = {
                css = true,
                javascript = true,
            },
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
