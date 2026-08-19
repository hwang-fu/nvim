-- ============================================================================
-- clojure_lsp: Clojure / ClojureScript / EDN language server.
-- Uses basic_on_attach (no inlay hints). Format-on-save is LSP-driven (see
-- the *.clj / *.cljs / *.cljc / *.edn entries in lsp/format.lua; verified
-- 2026-08-14 that the server advertises documentFormattingProvider).
--
-- TOOLCHAIN REQUIREMENT (bitten 2026-08-14): clojure-lsp resolves the
-- project classpath by shelling out to `clojure ... -Spath`, which needs
-- the OFFICIAL Clojure CLI. Fedora's `clojure` package ships the ancient
-- pre-CLI wrapper that treats every flag as a script file - with it on
-- PATH, classpath lookup fails and clojure-lsp blocks on an interactive
-- Retry/Ignore prompt at attach. Fixed by installing the official CLI
-- user-locally (linux-install.sh --prefix ~/.local), which shadows
-- /usr/bin/clojure via PATH order. If that prompt ever returns, check
-- `clojure --version` prints "Clojure CLI version ..." and `which
-- clojure` resolves to ~/.local/bin.
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("clojure_lsp", {
        cmd = {
            "clojure-lsp",
        },
        filetypes = {
            "clojure",
            "edn",
        },
        root_markers = {
            "project.clj",
            "deps.edn",
            "build.boot",
            "shadow-cljs.edn",
            ".git",
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
