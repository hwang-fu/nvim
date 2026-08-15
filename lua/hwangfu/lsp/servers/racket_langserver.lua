-- ============================================================================
-- racket_langserver: Racket language server.
-- Uses basic_on_attach (no inlay hints). Formatting is via `raco fmt`
-- (see lsp/format.lua).
--
-- The `racket-langserver` cmd is a hand-written wrapper at
-- ~/.local/bin/racket-langserver that just runs
-- `racket -l racket-langserver`. GOTCHA (bitten 2026-08-14): Racket
-- user-scope packages live in per-version directories
-- (~/.local/share/racket/<version>/), so a Racket upgrade silently
-- orphans them - the wrapper then exits 1 with "collection not found"
-- on every attach until `raco pkg install --auto racket-langserver` is
-- re-run for the new version. The same applies to the `fmt` package
-- behind format-on-save. If racket buffers ever lose LSP + formatting
-- at the same time, check `racket --version` against the package dirs
-- first.
-- ============================================================================

local helpers = require("hwangfu.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("racket_langserver", {
        cmd = {
            "racket-langserver",
        },
        filetypes = {
            "racket",
        },
        root_markers = {
            "info.rkt",
            ".git",
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
