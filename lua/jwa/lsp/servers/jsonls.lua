-- ============================================================================
-- jsonls: vscode-json-language-server. Handles JSON and JSONC (with comments).
-- Uses basic_on_attach (no inlay hints). Format-on-save is LSP-driven (see
-- the *.json / *.jsonc entries in lsp/format.lua).
--
-- Schema validation (2026-08-21): the settings block below hands jsonls
-- the schemastore.org catalog via the SchemaStore.nvim data plugin
-- (plugins/spec/schemastore.lua). With it, files the catalog knows by
-- name (package.json, tsconfig.json, .eslintrc, ...) get type / unknown-
-- key / missing-required diagnostics, key + enum-value completion, and
-- per-key hover docs. Without it jsonls only checks syntax: verified
-- live before the change that `"name": 123` in a package.json produced
-- zero diagnostics.
--
-- jsonls has no catalog support of its own (yamlls does - see
-- yamlls.lua), so the filename -> schema-url table must come from the
-- client side. Individual schema bodies are still downloaded by the
-- server from their URLs on first use; a file whose top-level "$schema"
-- key names a schema works independently of the catalog.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    -- pcall so a missing / half-installed plugin degrades to the old
    -- syntax-only jsonls instead of aborting the whole SERVERS loop in
    -- lsp/init.lua (same defensive pattern as make_capabilities' pcall
    -- of blink.cmp). The require itself triggers lazy.nvim's on-demand
    -- load of the lazy = true plugin.
    local ok, schemastore = pcall(require, "schemastore")

    helpers.define_server("jsonls", {
        cmd = {
            "vscode-json-language-server",
            "--stdio",
        },
        filetypes = {
            "json",
            "jsonc",
        },
        root_markers = {
            ".git",
        },
        init_options = {
            provideFormatter = true,
        },
        settings = {
            json = {
                schemas = ok and schemastore.json.schemas() or nil,
                validate = {
                    enable = true,
                },
            },
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
