-- ============================================================================
-- yamlls: yaml-language-server.
--
-- schemaStore.enable pulls in the public JSON schema catalog so common YAML
-- files (.github/workflows, docker-compose, k8s manifests, etc.) get
-- schema-aware validation and completion without per-file configuration.
--
-- Uses basic_on_attach (no inlay hints).
-- ============================================================================

local helpers = require("hwangfu.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("yamlls", {
        cmd = {
            "yaml-language-server",
            "--stdio",
        },
        filetypes = {
            "yaml",
            "yaml.docker-compose",
        },
        root_markers = {
            ".git",
        },
        settings = {
            yaml = {
                schemaStore = {
                    enable = true,
                    url = "https://www.schemastore.org/api/json/catalog.json",
                },
                validate = true,
                format = {
                    enable = true,
                },
            },
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
