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
-- top-level module list in init.lua. Same pattern as rust_analyzer.lua:
-- the module is wired from its plugin spec so it stays lazy
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
-- NO KEYMAPS, by explicit choice (2026-08-15). A <leader>c* set (13 maps)
-- lived here until then; removed on user request to keep the <leader>c
-- namespace free for future mappings. Everything is reached three ways:
--
--   * :Crates <subcommand> - the plugin's OWN global command with tab
--     completion (registered by crates.nvim itself; nothing to define
--     here). The subcommands, grouped:
--       popups    show_versions_popup / show_features_popup /
--                 show_dependencies_popup / show_crate_popup /
--                 show_popup / popup_available / focus_popup / hide_popup
--       change    update_crate / update_crates (visual range) /
--                 update_all_crates, and the upgrade_* trio likewise;
--                 use_git_source
--       view      toggle / show / hide (inline version info),
--                 reload (drop cache, re-fetch), update (re-fetch)
--       reshape   expand_plain_crate_to_inline_table /
--                 extract_crate_into_table
--       browser   open_documentation / open_cratesio / open_homepage /
--                 open_repository
--
--   * K            hover with version / feature detail - the standard
--                  LSP hover that taplo's basic_on_attach binds on this
--                  buffer queries EVERY attached client, crates included.
--
--   * <leader>ca   code actions: per-crate update / upgrade / open docs
--                  and friends, through the same every-client LSP route.
--                  (crates.nvim's README suggests putting
--                  update_all_crates on <leader>ca; deliberately not
--                  done - that IS the code-action key here.)
-- ----------------------------------------------------------------------------

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
        },
    })
end

return M
