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

-- Project markers, in priority order. Passed to vim.fs.root by root_dir()
-- below rather than declared as `root_markers`, because the two are mutually
-- exclusive: "root_markers ... Unused if root_dir is defined" (:h
-- lsp-root_markers).
local ROOT_MARKERS = {
    "mvnw",
    "gradlew",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    ".git",
}

-- Directories whose .java files are reference material, not code to work on.
--
-- clojure-lsp extracts the JDK's src.zip here so it can answer questions
-- about Java classes from Clojure buffers. Jumping to a Java definition from
-- Clojure lands you in one of those files - at which point jdtls used to
-- attach and report the Java module system contradicting itself:
--
--   The package java.net.http conflicts with a package accessible from
--   another module: java.net.http
--
-- Which is true and unavoidable. The file declares `package java.net.http`,
-- and the JDK jdtls itself runs on already provides that package from its own
-- module. Any Java server analysing JDK source outside a module context says
-- the same thing, on one installed JDK or five. The answer is not to make the
-- error go away but to stop asking the question.
local READ_ONLY_SOURCE_DIRS = {
    vim.fn.expand("~/.cache/clojure-lsp/"),
}

-- Decide per buffer whether jdtls runs at all.
--
-- The function form of root_dir is the documented way to skip a server: "The
-- function form must call the on_dir callback to provide the root dir, or LSP
-- will not be activated for the buffer" (:h lsp-root_dir). Returning without
-- calling it is therefore not a bug, it is the mechanism.
--
-- Real Java projects are unaffected: on_dir gets exactly what root_markers
-- would have produced, and on_dir(nil) - a .java file outside any project -
-- keeps the previous single-file behaviour rather than silently dropping it.
local function root_dir(bufnr, on_dir)
    local name = vim.api.nvim_buf_get_name(bufnr)

    for _, dir in ipairs(READ_ONLY_SOURCE_DIRS) do
        if name:sub(1, #dir) == dir then
            return
        end
    end

    on_dir(vim.fs.root(bufnr, ROOT_MARKERS))
end

function M.setup()
    helpers.define_server("jdtls", {
        cmd = {
            vim.fn.expand("~/.local/share/jdtls/bin/jdtls"),
        },
        filetypes = {
            "java",
        },
        root_dir = root_dir,
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
