-- ============================================================================
-- lua_ls (sumneko-lua): Lua language server.
--
-- Heavily configured because it's the LSP for editing THIS config. Pieces
-- that matter most:
--   * runtime.version = "LuaJIT"             - Neovim embeds LuaJIT, not 5.x.
--   * The Neovim API + plugin typings come from lazydev.nvim
--     (plugins/spec/lazydev.lua), which feeds lua_ls per-workspace
--     library entries for the runtime and for whatever plugins the open
--     buffers require(). This replaced the static workspace.library
--     entries (VIMRUNTIME + luv) that used to live here (2026-08-21):
--     the static list never covered plugins - require("telescope") etc.
--     resolved half-typed - and misfired when the workspace root fell
--     outside the config dir.
--   * diagnostics.globals = { "vim" }        - fallback so `vim` is never
--     flagged as an undefined global even where lazydev is inactive.
--   * hint.* - inlay hints, full set (Lua round, 2026-08-21):
--     paramName = "All" names every argument (was "Literals": literal
--     args only), arrayIndex = "Enable" labels table-literal indexes
--     (was "Disable").
--   * type.inferParamType = true - unannotated function parameters get
--     their type inferred from call sites instead of `any`; better
--     hover and more mismatch catches, occasionally a wrong guess.
--   * telemetry.enable = false               - opt out of usage tracking.
--
-- Formatting is via stylua (see lsp/format.lua), driven by the project's
-- .stylua.toml.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    helpers.define_server("lua_ls", {
        cmd = {
            "lua-language-server",
        },
        filetypes = {
            "lua",
        },
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
                    -- No static `library` here: lazydev.nvim supplies it
                    -- dynamically (see the header comment).
                },
                completion = {
                    callSnippet = "Replace",
                },
                type = {
                    inferParamType = true,
                },
                hint = {
                    enable = true,
                    arrayIndex = "Enable",
                    paramName = "All",
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
