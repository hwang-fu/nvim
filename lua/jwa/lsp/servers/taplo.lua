-- ============================================================================
-- taplo: TOML language server.
--
-- SETTINGS SECTION NAME (2026-08-21, recanting an old mistake): taplo
-- reads its configuration from the `evenBetterToml` section - the name
-- it inherits from its VS Code extension - NOT from a `taplo` key.
-- This file previously nested everything under `settings.taplo`, which
-- taplo silently ignored: the whole formatting block below was inert
-- from the day it was written (verified via the LSP log - config pushed
-- under `evenBetterToml` triggers taplo's update_configuration
-- handling; the old `taplo` key never did).
--
-- Consequence: reorderKeys had NEVER actually alphabetized anything,
-- despite the old comment here warning about it. It is now explicitly
-- false to keep saves behaving the way they observably always have.
-- Flip it to true if you decide you want alphabetized keys per section
-- (heads-up: surprising diffs in Cargo.toml / pyproject.toml where key
-- order is conventional).
--
-- Schema validation (2026-08-21): known-by-name TOML files get type /
-- unknown-key diagnostics, key and enum-value completion, and per-key
-- hover docs. On Cargo.toml this complements crates.nvim, which
-- handles dependency-version intelligence.
--
-- WHY explicit associations INSTEAD OF a schema catalog: taplo 0.10.0
-- (the latest release, 2025-05) can no longer parse schemastore.org's
-- catalog.json - the catalog format drifted after taplo's last
-- release, and every fetch dies in the LSP log with "data did not
-- match any variant of untagged enum SchemaCatalog". It has always
-- died: taplo tries a catalog at initialize even unconfigured, so TOML
-- schema support was broken here at the decode step all along. The
-- associations below map document-URI regexes straight to schema URLs,
-- skipping catalog parsing entirely; taplo fetches each schema JSON
-- itself on first use. `catalogs = {}` silences the doomed default-
-- catalog fetch - except once at startup: LSP settings arrive after
-- the initialize request, so taplo still tries its baked-in default
-- catalog one time per start and leaves one harmless WARN line in
-- lsp.log. If a future taplo release fixes the decode, the
-- associations can be replaced by
--     catalogs = { "https://www.schemastore.org/api/json/catalog.json" }
-- for full by-name coverage (the same catalog yamlls fetches and
-- SchemaStore.nvim vendors for jsonls).
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("taplo", {
        cmd = {
            "taplo",
            "lsp",
            "stdio",
        },
        filetypes = {
            "toml",
        },
        root_markers = {
            ".taplo.toml",
            "taplo.toml",
            ".git",
        },
        on_attach = helpers.basic_on_attach,
        settings = {
            evenBetterToml = {
                schema = {
                    enabled = true,
                    -- Empty on purpose; see the header comment.
                    catalogs = {},
                    -- Keys are Rust regexes matched against the full
                    -- document URI (file:///...), values are schema
                    -- URLs (the same ones the schemastore.org catalog
                    -- points at).
                    associations = {
                        [".*/Cargo\\.toml$"] = "https://www.schemastore.org/cargo.json",
                        [".*/pyproject\\.toml$"] = "https://raw.githubusercontent.com/SchemaStore/schemastore/master/src/schemas/json/pyproject.json",
                        [".*/\\.?taplo\\.toml$"] = "https://www.schemastore.org/taplo.json",
                    },
                },
                formatting = {
                    alignEntries = false,
                    alignComments = true,
                    arrayTrailingComma = true,
                    arrayAutoExpand = true,
                    arrayAutoCollapse = true,
                    compactArrays = true,
                    compactInlineTables = false,
                    indentTables = false,
                    indentEntries = false,
                    reorderKeys = false,
                },
            },
        },
    })
end

return M
