-- ============================================================================
-- cmake_ls: cmake-language-server (2026-08-28, user request).
--
-- Completion and hover for CMake commands and variables, plus
-- goto-definition for functions/macros defined in the project.
--
-- INSTALL PIN (2026-08-28, two broken installs deep): the binary is a
-- python tool whose latest release still targets the pygls 1.x API -
-- an unconstrained install resolves pygls 2.0 and dies at import
-- ("cannot import name 'LanguageServer' from 'pygls.server'"). The
-- working spell, used for both users, is:
--     uv tool install --force cmake-language-server --with "pygls<2"
-- (The machine's even older pip-user install was broken against a
-- DIFFERENT pygls era - it had never worked; it simply was never
-- wired in until today.)
--
-- Formatting is deliberately NOT wired through this server: format-on-
-- save for CMakeLists.txt / *.cmake runs the gersemi CLI in
-- lsp/format.lua section (b), so the formatter works even when this
-- server is absent and stays independent of its formatting quirks.
--
-- buildDirectory is the server's convention for finding a configured
-- build tree (compile data improves completion); "build" matches the
-- common `cmake -B build` layout and is harmless when absent.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("cmake_ls", {
        cmd = {
            "cmake-language-server",
        },
        filetypes = {
            "cmake",
        },
        root_markers = {
            "CMakeLists.txt",
            ".git",
        },
        init_options = {
            buildDirectory = "build",
        },
        on_attach = helpers.basic_on_attach,
    })
end

return M
