-- ============================================================================
-- vue_ls: Vue's official "hybrid mode" LSP.
--
-- vue_ls needs to be told where the TypeScript SDK lives - it does not bundle
-- one. The setup function below probes a couple of common npm install
-- locations and passes the first one that exists via init_options. If none
-- are found, ts_path keeps its default and vue_ls falls back to whatever it
-- can find on PATH (often broken).
--
-- hybridMode = true means the TypeScript LSP and Vue LSP cooperate
-- rather than duplicate work: the TS server handles the <script>
-- blocks, vue_ls handles template + style + the Vue-specific bits.
--
-- KNOWN GAP (2026-08-21, flagged during the ts_ls -> tsgo migration):
-- the tsdk probe below looks for the JS TypeScript lib
-- (tsserverlibrary), which the globally installed typescript@7
-- (native compiler) no longer ships - and the native tsgo server has
-- no plugin mechanism for Vue's TS-side plugin either. Vue projects
-- with their OWN typescript 5.x/6.x in node_modules are unaffected.
-- Worth revisiting in a dedicated Vue round if Vue work starts.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    local ts_path = "/usr/lib/node_modules/typescript/lib"
    local possible_paths = {
        "/usr/lib/node_modules/typescript/lib",
        "/usr/local/lib/node_modules/typescript/lib",
        vim.fn.expand("$HOME/.npm/lib/node_modules/typescript/lib"),
    }
    for _, path in ipairs(possible_paths) do
        if vim.fn.isdirectory(path) == 1 then
            ts_path = path
            break
        end
    end

    helpers.define_server("vue_ls", {
        cmd = {
            "vue-language-server",
            "--stdio",
        },
        filetypes = {
            "vue",
        },
        root_markers = {
            "package.json",
            ".git",
        },
        init_options = {
            typescript = {
                tsdk = ts_path,
            },
            vue = {
                hybridMode = true,
            },
        },
    })
end

return M
