-- ============================================================================
-- clojure_lsp: Clojure / ClojureScript / EDN language server.
-- Uses basic_on_attach (no inlay hints). Format-on-save is LSP-driven
-- (see the *.clj / *.cljs / *.cljc / *.edn entries in lsp/format.lua;
-- verified 2026-08-14 that the server advertises
-- documentFormattingProvider).
--
-- CONFIG CHANNEL: clojure-lsp reads its settings from initializationOptions
-- (init_options below - carried in this repo, the reproducible channel),
-- with config.edn files (global or per-project .lsp/config.edn) as the
-- out-of-repo alternatives. Keys keep their EDN spellings, question marks
-- included, hence the bracketed-string syntax.
--
-- Enabled 2026-08-21 (user took the whole recommended round):
--   * hover compaction - arities on one line, no file-location footer.
--   * lens-segregate-test-references - kept although lens DISPLAY is
--     parked, see below; it costs nothing and is ready if lenses return.
--
-- PARKED: reference-count codelens display. Attempted 2026-08-21 and
-- withdrawn the same day; the evidence chain, so nobody retries blind:
--   * clojure-lsp sends UNRESOLVED lenses (no title until a
--     codeLens/resolve round-trip; hand-made resolves answer instantly
--     with e.g. "1 reference").
--   * Neovim 0.12's framework resolves lazily during render, but that
--     never converged here: provider enabled, zero resolve errors in
--     the LSP log, yet 20s of forced redraws left every stored lens
--     unresolved, and a live tmux session rendered no lens rows at all.
--   * A pre-resolve wrapper (hold each codeLens response, resolve all,
--     deliver a fully-resolved list) verified end-to-end headless -
--     titles landed in the stored set - but in a live session the
--     added round-trip latency made every response lose the race
--     against clojure-lsp's startup refresh storm: zero lenses stored.
-- Doing this properly means a private request+resolve+render loop
-- (~50 lines of parallel codelens engine) - not worth it for a
-- reference count. Revisit after a Neovim upgrade; ocamllsp lenses are
-- unaffected (its titles arrive pre-resolved inline).
--
-- Known knob for later, when the linter first annoys: the embedded
-- clj-kondo flags every public var nothing references
-- (:clojure-lsp/unused-public-var) - tune per project in
-- .clj-kondo/config.edn rather than globally here.
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

local helpers = require("jwa.lsp.helpers")

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
        init_options = {
            ["lens-segregate-test-references"] = true,
            hover = {
                ["arity-on-same-line?"] = true,
                ["hide-file-location?"] = true,
            },
            -- NO cache redirection, after a full investigation
            -- (2026-08-27, prompted by scratch dirs seemingly sprouting
            -- .clj-kondo/). What the probes and the settings docs
            -- established:
            --   * A genuinely stray .clj (no deps.edn / project.clj
            --     up-tree) creates NOTHING - single-file mode keeps its
            --     analysis in memory. The observed folder must have come
            --     from a directory that had become a project.
            --   * In real projects, .lsp/.cache (analysis db) and
            --     .clj-kondo/.cache (lint cache) are project-local BY
            --     DESIGN: the real setting is :cache-path (NOT
            --     "cache-dir", which the server echoes back in
            --     final-settings without using - do not trust that echo
            --     as proof a setting exists), it moves only the .lsp
            --     half, and pointing it at one shared absolute dir
            --     would make every project fight over the same
            --     db.transit.json. clj-kondo's cache has no relocation
            --     setting at all.
            -- Conclusion: project-local caches stay (gitignore them
            -- globally); scratch dirs were never dirtied in the first
            -- place.
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
