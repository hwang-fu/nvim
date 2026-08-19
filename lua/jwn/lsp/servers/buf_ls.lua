-- ============================================================================
-- buf_ls: Protocol Buffers (`buf beta lsp`).
--
-- Note: clangd's filetype list also includes `proto`, so on a `.proto` file
-- both servers can attach. clangd handles formatting / generic completion,
-- buf_ls handles proto-specific lint / breaking-change checks.
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("buf_ls", {
        cmd = {
            "buf",
            "beta",
            "lsp",
        },
        filetypes = {
            "proto",
        },
        root_markers = {
            "buf.yaml",
            "buf.work.yaml",
            ".git",
        },
    })
end

return M
