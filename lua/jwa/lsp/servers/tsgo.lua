-- ============================================================================
-- tsgo: TypeScript / JavaScript via the NATIVE TypeScript 7 compiler.
--
-- REPLACES typescript-language-server (2026-08-21). TypeScript 7 is the
-- Go rewrite of the compiler; the npm `typescript` package now ships a
-- native binary whose `tsc --lsp --stdio` mode is a full language
-- server - the same engine VS Code uses for TS 7. The old
-- typescript-language-server could no longer start here at all: it
-- needs the JS-based tsserver.js, which the typescript@7 package no
-- longer contains (verified live - ts_ls failed to spawn in any
-- project without its own old-style typescript in node_modules).
--
-- Capability parity, verified against the binary by handshaking an
-- initialize request (2026-08-21, typescript 7.0.2): completion with
-- resolve, hover, signature help, definition / typeDefinition /
-- implementation / references, rename with prepare, code actions
-- (including source.organizeImports and source.removeUnusedImports),
-- document + range + on-type formatting, inlay hints, code lens,
-- semantic tokens, folding, call hierarchy, workspace symbols, and
-- PULL-model diagnostics (textDocument/diagnostic - Neovim 0.12
-- drives that natively).
--
-- Behavioral note: the server always analyzes with its own bundled
-- TS 7 semantics. A project pinning an older typescript in
-- package.json still builds with its pinned version, but editor
-- diagnostics come from 7 - watch for rare version-skew diagnostics
-- in old projects.
--
-- Settings: the server pulls VS Code-style workspace/configuration
-- sections (observed on the wire: "typescript", "javascript",
-- "js/ts", "editor"), so the inlayHints block uses VS Code's MODERN
-- key names (parameterNames.enabled = "all", ...), NOT the old ts_ls
-- protocol shape (includeInlayParameterNameHints = ...) - the old
-- shape was silently ignored (verified: 0 hints returned with it,
-- hints flow with this one). Same duplication as ts_ls had:
-- typescript and javascript are separate scopes, each needs its own
-- copy.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

local inlay_hints = {
    parameterNames = {
        enabled = "all",
        suppressWhenArgumentMatchesName = true,
    },
    parameterTypes = {
        enabled = true,
    },
    variableTypes = {
        enabled = true,
    },
    propertyDeclarationTypes = {
        enabled = true,
    },
    functionLikeReturnTypes = {
        enabled = true,
    },
    enumMemberValues = {
        enabled = true,
    },
}

function M.setup()
    helpers.define_server("tsgo", {
        -- `tsc` here is the npm wrapper of the global typescript@7
        -- install; it execs the platform-native binary and forwards
        -- the flags.
        cmd = { "tsc", "--lsp", "--stdio" },
        filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
        },
        root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
        settings = {
            typescript = {
                inlayHints = inlay_hints,
            },
            javascript = {
                inlayHints = inlay_hints,
            },
        },
    })
end

return M
