-- ============================================================================
-- fennel_ls: Fennel language server.
--
-- Wired up 2026-08-14: the binary (installed via luarocks, at
-- ~/.luarocks/bin/fennel-ls) had been present but unused. Uses
-- basic_on_attach like the other lisp servers (clojure_lsp,
-- racket_langserver) - fennel-ls 0.2.x has no inlay hints to enable.
--
-- Project configuration lives in an flsproject.fnl at the project root
-- (also the primary root marker); without one, fennel-ls runs in
-- single-file mode with its defaults, which is fine for standalone
-- scripts. No `settings` table here on purpose: every fennel-ls option
-- has a sensible default and this config has been bitten by
-- dead-settings tables before (see ocamllsp.lua's history note).
--
-- No formatter wired: fnlfmt exists but is not installed; add it to
-- lsp/format.lua section (b) if Fennel work ever becomes regular.
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("fennel_ls", {
        cmd = {
            "fennel-ls",
        },
        filetypes = {
            "fennel",
        },
        root_markers = {
            "flsproject.fnl",
            ".git",
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
