-- ============================================================================
-- Telescope: fuzzy finder / popup picker.
--
-- A floating popup you summon: a search prompt, a results list, and a live
-- preview pane. Type to fuzzy-narrow the list, <CR> to open, <Esc> to dismiss.
-- This is search-first file navigation, as opposed to oil.nvim's
-- browse-the-directory style; the two can happily coexist.
--
-- The plugin specs (telescope.nvim + plenary.nvim + telescope-fzf-native) live
-- in lua/hwangfu/plugins/spec/telescope.lua. This module configures telescope and maps the
-- keybindings; it is wired up from the root init.lua.
--
-- ----------------------------------------------------------------------------
-- Keybindings (<leader> is Space) - each opens the telescope popup:
--   <leader>ff   find files by name
--   <leader>fg   live grep: search file *contents* across the whole project
--   <leader>fs   grep the word currently under the cursor
--   <leader>fb   switch between open buffers
--   <leader>fr   recently opened files
--   <leader>fd   project diagnostics (LSP errors / warnings)
--   <leader>fh   search Neovim's built-in help
--   <leader>fk   search every keymap - handy for discovering bindings
--
-- Ex-command equivalents:
--   Every picker is also reachable from the colon prompt via the
--   `:Telescope` dispatcher, with tab-completion on both picker names
--   and their options. Useful for scripting a picker, routing to one
--   from another mapping, or passing per-call options without having
--   to write a wrapper function.
--
--     :Telescope find_files           same as <leader>ff
--     :Telescope live_grep            same as <leader>fg
--     :Telescope grep_string          same as <leader>fs
--     :Telescope buffers              same as <leader>fb
--     :Telescope oldfiles             same as <leader>fr
--     :Telescope diagnostics          same as <leader>fd
--     :Telescope help_tags            same as <leader>fh
--     :Telescope keymaps              same as <leader>fk
--
--   Options are passed as `key=value` tokens after the picker name:
--     :Telescope find_files cwd=~/work hidden=true no_ignore=true
--     :Telescope live_grep  cwd=%:p:h          (grep from current file's dir)
--
--   `:Telescope` with no argument opens a picker that lists every
--   available picker -- the fastest way to discover ones not mapped
--   here (e.g. git_files, git_status, lsp_references, treesitter, ...).
--
-- Inside the popup (while the prompt is focused):
--   type            fuzzy-filter the results
--   <C-n> / <C-p>   next / previous result (arrow keys work too)
--   <CR>            open the selected result
--   <C-x>           open it in a horizontal split
--   <C-v>           open it in a vertical split
--   <C-t>           open it in a new tab
--   <C-u> / <C-d>   scroll the preview pane up / down
--   <C-c>           close the popup
--   <C-/>           show telescope's own full list of mappings
-- ============================================================================

local M = {}

-- require("hwangfu.telescope").setup()
function M.setup()
    local telescope = require("telescope")

    telescope.setup({
        defaults = {
            -- Plain ASCII prompt and selection caret. Telescope defaults to
            -- glyph markers; these match this config's no-nerd-font,
            -- icons-off look. Change them here if you want the fancier
            -- defaults back.
            prompt_prefix = "> ",
            selection_caret = "> ",
        },
    })

    -- telescope-fzf-native is a compiled C sorter, built via `make` on
    -- install. Loading it as an extension makes matching faster and enables
    -- proper fzf-style fuzzy syntax. The pcall guards the case where the
    -- build did not happen (e.g. no C compiler on a fresh machine).
    pcall(telescope.load_extension, "fzf")

    -- haskell-tools.nvim ships a Telescope extension ("ht") with
    -- package-scoped pickers that the vanilla telescope.builtin set
    -- doesn't reach: `:Telescope ht package_files`, `package_hsfiles`,
    -- `package_grep`, `package_hsgrep`, `hoogle_signature`. The pcall
    -- keeps this a silent no-op when haskell-tools isn't installed
    -- (e.g. a fresh clone before lazy.nvim has finished installing).
    pcall(telescope.load_extension, "ht")

    -- Keybindings. Each opens the telescope popup for a different source.
    -- The `desc` text is what shows up in `:nmap <leader>f` and which-key.
    local builtin = require("telescope.builtin")
    local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, {
            silent = true,
            desc = desc,
        })
    end

    map("<leader>ff", builtin.find_files, "Telescope: find files")
    map("<leader>fg", builtin.live_grep, "Telescope: live grep (project contents)")
    map("<leader>fs", builtin.grep_string, "Telescope: grep word under cursor")
    map("<leader>fb", builtin.buffers, "Telescope: open buffers")
    map("<leader>fr", builtin.oldfiles, "Telescope: recent files")
    map("<leader>fd", builtin.diagnostics, "Telescope: diagnostics")
    map("<leader>fh", builtin.help_tags, "Telescope: help tags")
    map("<leader>fk", builtin.keymaps, "Telescope: search keymaps")
end

return M
