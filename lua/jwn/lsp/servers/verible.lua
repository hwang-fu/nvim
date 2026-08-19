-- ============================================================================
-- verible: Verilog / SystemVerilog language server (Google's verible suite).
-- Formatting is via verible-verilog-format (see lsp/format.lua); filetype
-- detection for *.v / *.vh / *.sv / *.svh is added in lsp/init.lua.
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("verible", {
        cmd = { "verible-verilog-ls" },
        filetypes = {
            "verilog",
            "systemverilog",
        },
        root_markers = {
            "verible.filelist",
            ".rules.verible_lint",
            ".git",
        },
    })
end

return M
