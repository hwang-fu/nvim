-- ============================================================================
-- clangd: C / C++ / ObjC / CUDA / proto.
--
-- Quirks:
--   * Custom capabilities - we ask for snippet support so completion items
--     come back with placeholders we can step through.
--   * Custom on_attach    - standard_on_attach plus omnifunc so <C-x><C-o>
--     works. Diagnostics HISTORY: they were silenced at the protocol layer
--     (helpers.disable_diagnostics) from this file's beginning until
--     2026-08-23, when the user asked for them - verified live that a
--     broken .c file showed zero diagnostics before and reports them now.
--     The --clang-tidy flag below means the lints ride along with plain
--     compiler errors; if legacy-codebase noise ever gets bad again,
--     dropping that flag is the quieter first step (full re-silence:
--     re-add helpers.disable_diagnostics(client) in on_attach).
--   * Wider filetype list - clangd handles C, C++, ObjC variants, CUDA, and
--     also doubles as a proto formatter when buf_ls isn't around.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("clangd", {
        cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=never",
        },
        filetypes = {
            "c",
            "cpp",
            "objc",
            "objcpp",
            "cuda",
            "proto",
        },
        root_markers = {
            ".clangd",
            ".clang-tidy",
            ".clang-format",
            "compile_commands.json",
            "compile_flags.txt",
            "configure.ac",
            ".git",
        },
        capabilities = (function()
            local caps = helpers.make_capabilities()
            caps.textDocument.completion.completionItem.snippetSupport = true
            return caps
        end)(),
        on_attach = function(client, bufnr)
            -- standard_on_attach also installs the diagnostic keymaps
            -- ([d / ]d / gl), which the old diagnostics-silenced attach
            -- rightly skipped.
            helpers.standard_on_attach(client, bufnr)
            vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
        end,
    })
end

return M
