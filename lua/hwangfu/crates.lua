-- ============================================================================
-- crates.nvim: dependency intelligence for Cargo.toml.
--
-- Augments Cargo.toml editing with crates.io data: inline virtual text showing
-- the latest version next to each pinned dependency, completion of crate names
-- / versions / features, hover with version + feature detail, and code actions
-- to update / upgrade a crate. It touches Cargo.toml ONLY - it has nothing to
-- say about .rs files.
--
-- This module is invoked from the crates.nvim plugin spec's `config` hook in
-- lua/hwangfu/plugins/spec/crates.lua (lazy-loaded on `BufRead Cargo.toml`), NOT from the
-- top-level module list in init.lua. Same pattern as dap.lua and
-- rust_analyzer.lua: the module is wired from its plugin spec so it stays lazy
-- and only loads when a Cargo.toml is actually opened.
--
-- Integration approach: IN-PROCESS LANGUAGE SERVER, not the nvim-cmp source.
--   crates.nvim historically shipped a dedicated nvim-cmp source
--   (completion.cmp). That source is DEPRECATED upstream and slated for
--   removal; the maintainer points users at the in-process language server
--   instead. So this config leaves completion.cmp OFF and turns on
--   `lsp = { enabled = true, completion/hover/actions = true }`. crates.nvim
--   then registers an in-process LSP client that attaches to Cargo.toml
--   buffers, which has three nice consequences:
--     * completion  - crate / version / feature completions are served as a
--                     normal LSP completionProvider, so they flow through
--                     blink.cmp's built-in `lsp` source (configured in
--                     lua/hwangfu/completion.lua). No change needed there.
--     * hover (K)   - K on a dependency line shows version / feature info.
--                     Reachable through the K = vim.lsp.buf.hover binding that
--                     taplo's basic_on_attach already installs on Cargo.toml
--                     (K queries every attached client, so taplo and crates
--                     both contribute to the popup).
--     * actions     - <leader>ca offers "Update crate" / "Upgrade crate" /
--                     "Open documentation" and friends, again through taplo's
--                     existing <leader>ca = vim.lsp.buf.code_action binding.
--
-- Relationship to taplo (lua/hwangfu/lsp/servers/taplo.lua): complementary,
-- not competing. taplo is the general TOML language server (schema validation,
-- formatting); crates.nvim adds crates.io-specific version intelligence. Both
-- attach to the same Cargo.toml buffer at once.
--
-- Heads-up on format-on-save: taplo formats *.toml on save with
-- reorderKeys = true (see taplo.lua), so saving after a crates update /
-- upgrade alphabetizes keys within each table. That is pre-existing taplo
-- behavior, unchanged here - noted only because crates makes you edit
-- Cargo.toml more often.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- Buffer-local keymaps, installed from the crates LSP on_attach below so they
-- exist only on Cargo.toml buffers the crates client attaches to.
--
-- Only the crates-SPECIFIC verbs are bound here. The standard LSP verbs that
-- crates also provides - hover (K) and code actions (<leader>ca) - are
-- intentionally NOT rebound: taplo's basic_on_attach already binds them on
-- this buffer, and they query every attached client, so crates' hover /
-- actions already ride those.
--
-- <leader>ca is DELIBERATELY left alone. crates.nvim's own recommended keymaps
-- put update_all_crates on <leader>ca, but that is exactly the code-action key
-- on every LSP buffer in this config. Rebinding it would shadow code actions
-- on Cargo.toml. update_all_crates / upgrade_all_crates are instead reachable
-- via the `:Crates update_all_crates` / `:Crates upgrade_all_crates` commands,
-- and per-crate update / upgrade is offered as a code action under <leader>ca.
--
-- Keymap groups (all under <leader>c, buffer-local to Cargo.toml):
--   popups   cv versions   cf features   cd dependencies
--   change   cu update     cU upgrade    (also work on a visual selection)
--   view     ct toggle inline info       cr reload from crates.io
--   shape    cx expand to inline table   cX extract into [dependencies.x]
--   browser  cD docs.rs    cC crates.io  cH homepage   cR repository
-- ----------------------------------------------------------------------------
local function install_keymaps(bufnr)
    local crates = require("crates")

    local function nmap(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end
    local function vmap(lhs, rhs, desc)
        vim.keymap.set("v", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    -- Popups (contextual to the crate on the current line).
    nmap("<leader>cv", crates.show_versions_popup, "Crates: versions popup")
    nmap("<leader>cf", crates.show_features_popup, "Crates: features popup")
    nmap("<leader>cd", crates.show_dependencies_popup, "Crates: dependencies popup")

    -- Update (move to newest version allowed by the current requirement) and
    -- upgrade (rewrite the requirement to the newest version). Visual-mode
    -- variants act on every crate in the selection.
    nmap("<leader>cu", crates.update_crate, "Crates: update crate")
    vmap("<leader>cu", crates.update_crates, "Crates: update selected crates")
    nmap("<leader>cU", crates.upgrade_crate, "Crates: upgrade crate")
    vmap("<leader>cU", crates.upgrade_crates, "Crates: upgrade selected crates")

    -- Visibility / data.
    nmap("<leader>ct", crates.toggle, "Crates: toggle inline info")
    nmap("<leader>cr", crates.reload, "Crates: reload from crates.io")

    -- Reshape a dependency entry between `foo = \"1\"` and the expanded
    -- [dependencies.foo] table form.
    nmap("<leader>cx", crates.expand_plain_crate_to_inline_table, "Crates: expand to inline table")
    nmap("<leader>cX", crates.extract_crate_into_table, "Crates: extract into table")

    -- Open the crate's pages in a browser.
    nmap("<leader>cD", crates.open_documentation, "Crates: open docs.rs")
    nmap("<leader>cC", crates.open_crates_io, "Crates: open crates.io")
    nmap("<leader>cH", crates.open_homepage, "Crates: open homepage")
    nmap("<leader>cR", crates.open_repository, "Crates: open repository")
end

-- ----------------------------------------------------------------------------
-- Entry point.
--
-- completion.cmp is left at its default (off) on purpose - it is the bridge
-- to nvim-cmp, which is deprecated upstream AND no longer installed here
-- (blink.cmp consumes the in-process LSP server instead; see the header
-- note). completion.crates (crates.nvim's own built-in source) and
-- smart_insert / autoload stay at their defaults (on).
-- ----------------------------------------------------------------------------
function M.setup()
    require("crates").setup({
        lsp = {
            enabled = true,
            name = "crates.nvim",
            completion = true,
            hover = true,
            actions = true,
            on_attach = function(_, bufnr)
                install_keymaps(bufnr)
            end,
        },
    })
end

return M
