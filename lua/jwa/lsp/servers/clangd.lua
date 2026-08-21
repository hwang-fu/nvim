-- ============================================================================
-- clangd: C / C++ / ObjC / CUDA / proto.
--
-- Quirks:
--   * Custom capabilities - we ask for snippet support so completion items
--     come back with placeholders we can step through.
--   * Custom on_attach    - we silence the LSP-published diagnostics (clangd
--     can be very noisy on legacy code; if you want them, drop the
--     disable_diagnostics call) and set omnifunc so <C-x><C-o> works.
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
            helpers.set_common_keymaps(bufnr)
            helpers.disable_diagnostics(client)
            vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
            helpers.enable_inlay_hints(bufnr)
        end,
    })
end

return M
