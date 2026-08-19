-- ============================================================================
-- taplo: TOML language server.
--
-- Heavily customized formatting settings - taplo's defaults reorder keys
-- and align in ways that may not match your style. Tune the `formatting`
-- block to taste.
--
-- Format-on-save for *.toml IS enabled in lsp/format.lua. Heads-up: the
-- `reorderKeys = true` setting below alphabetizes keys within each
-- [section] on every save, which can produce surprising diffs in
-- pyproject.toml / Cargo.toml / similar files where humans rely on
-- specific key ordering. If that bites, either flip `reorderKeys` to
-- false (only taplo feels the change) or comment "*.toml" back out in
-- lsp/format.lua (disables save-side formatting wholesale; you can
-- still format manually via :lua vim.lsp.buf.format()).
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

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
            taplo = {
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
                    reorderKeys = true,
                },
            },
        },
    })
end

return M
