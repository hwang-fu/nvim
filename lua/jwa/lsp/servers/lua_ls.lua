-- ============================================================================
-- lua_ls (sumneko-lua): Lua language server.
--
-- Heavily configured because it's the LSP for editing THIS config. Pieces
-- that matter most:
--   * runtime.version = "LuaJIT"             - Neovim embeds LuaJIT, not 5.x.
--   * workspace.library = { vim.env.VIMRUNTIME, ... } - exposes Neovim's own
--     Lua APIs and luv types so `vim.api.*` etc. resolve. (The "Undefined
--     global `vim`" warnings you might see in this file are because the LSP
--     workspace root happens to be ~ rather than your nvim config dir, so
--     library detection misfires; opening the file from inside ~/.config/nvim
--     usually fixes it.)
--   * diagnostics.globals = { "vim" }        - secondary fallback for the
--     same problem.
--   * telemetry.enable = false               - opt out of usage tracking.
--
-- Formatting is via stylua (see lsp/format.lua), driven by the project's
-- .stylua.toml.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("lua_ls", {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = {
            ".luarc.json",
            ".luarc.jsonc",
            ".luacheckrc",
            ".stylua.toml",
            "stylua.toml",
            "selene.toml",
            "selene.yml",
            ".git",
        },
        settings = {
            Lua = {
                semantic = {
                    enable = true,
                },

                runtime = {
                    version = "LuaJIT",
                },
                workspace = {
                    checkThirdParty = false,
                    library = {
                        vim.env.VIMRUNTIME,
                        "${3rd}/luv/library",
                    },
                },
                completion = {
                    callSnippet = "Replace",
                },
                hint = {
                    enable = true,
                    arrayIndex = "Disable",
                    paramName = "Literals",
                    paramType = true,
                    semicolon = "Disable",
                    setType = true,
                },
                diagnostics = {
                    globals = {
                        "vim",
                    },
                },
                telemetry = {
                    enable = false,
                },
            },
        },
    })
end

return M
