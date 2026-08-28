-- ============================================================================
-- jdtls: Eclipse JDT language server for Java (2026-08-28, user request).
--
-- Binary: the launcher at ~/.local/share/jdtls/bin/jdtls - a pinned,
-- expanded path rather than a $PATH lookup, the same convention as the
-- ElixirLS install (both users on this machine keep it at that
-- location; the jwa bootstrap bundle carries the directory). The
-- launcher is jdtls' own python wrapper: it locates the jars next to
-- itself and MANAGES THE PER-PROJECT WORKSPACE automatically (-data
-- under the XDG cache dir, keyed by project path), which is why no
-- -data plumbing appears here. The Java runtime comes from dnf
-- (system-wide, openjdk 25) - nothing per-user.
--
-- Format-on-save is LSP-driven: "*.java" in lsp/format.lua's section
-- (a) runs the Eclipse formatter through this server. Style knobs, if
-- ever wanted, live under settings.java.format.settings (an Eclipse
-- formatter-profile XML URL).
--
-- Inlay hints: parameter-name hints on every argument, matching the
-- preference established in the Rust and Lua rounds.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("jdtls", {
        cmd = {
            vim.fn.expand("~/.local/share/jdtls/bin/jdtls"),
        },
        filetypes = {
            "java",
        },
        root_markers = {
            "mvnw",
            "gradlew",
            "pom.xml",
            "build.gradle",
            "build.gradle.kts",
            ".git",
        },
        settings = {
            java = {
                inlayHints = {
                    parameterNames = {
                        enabled = "all",
                    },
                },
            },
        },
        on_attach = helpers.standard_on_attach,
    })
end

return M
