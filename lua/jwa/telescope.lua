-- ============================================================================
-- Telescope: fuzzy finder / popup picker.
--
-- A floating popup you summon: a search prompt, a results list, and a live
-- preview pane. Type to fuzzy-narrow the list, <CR> to open, <Esc> to dismiss.
-- This is search-first file navigation, as opposed to oil.nvim's
-- browse-the-directory style; the two can happily coexist.
--
-- The plugin specs (telescope.nvim + plenary.nvim + telescope-fzf-native) live
-- in lua/jwa/plugins/spec/telescope.lua. This module configures telescope and maps the
-- keybindings; it is wired up from the root init.lua.
--
-- ----------------------------------------------------------------------------
-- Keybindings (<leader> is Space) - each opens the telescope popup:
--   <leader>t    find files by name (short form of <leader>ff)
--   <leader>T    find files, including ignored and hidden (= <leader>fF)
--   <leader>ff   find files by name
--   <leader>fF   find files, including ignored and hidden ones
--   <leader>fg   live grep: search file *contents* across the whole project
--   <leader>fG   live grep, including ignored and hidden files
--   <leader>fs   grep the word currently under the cursor
--   <leader>f/   fuzzy search the current buffer's lines
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
--   <C-q>           close the popup (also Esc; <C-c> is neutralized)
--   <C-/>           show telescope's own full list of mappings
-- ============================================================================

local M = {}

-- require("jwa.telescope").setup()
function M.setup()
    local telescope = require("telescope")

    local actions = require("telescope.actions")
    telescope.setup({
        defaults = {
            -- Plain ASCII prompt and selection caret. Telescope defaults to
            -- glyph markers; these match this config's no-nerd-font,
            -- icons-off look. Change them here if you want the fancier
            -- defaults back.
            prompt_prefix = "> ",
            selection_caret = "> ",
            -- Ctrl-Q closes the picker (2026-08-15), matching the global
            -- Ctrl-Q = quit convention. This shadows telescope's default
            -- insert-mode <C-q> (send results to the quickfix list); Esc
            -- still closes from insert mode too. <C-c> is neutralized.
            mappings = {
                i = {
                    ["<C-q>"] = actions.close,
                    ["<C-c>"] = actions.nop,
                },
                n = {
                    ["<C-q>"] = actions.close,
                    ["<C-c>"] = actions.nop,
                },
            },
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

    -- Search root for the DIRECTORY-SCOPED pickers.
    --
    -- 'autochdir' is on (see section 4 of lua/jwa/init.lua), so the cwd
    -- follows whatever buffer is focused. Telescope's default scope is the
    -- cwd, which would quietly turn "search the project" into "search the
    -- folder this one file happens to sit in" - no error, just fewer
    -- results. So the pickers that claim to be project-wide say where the
    -- project is instead of inheriting it.
    --
    -- Resolution order: the nearest .git above the current buffer; failing
    -- that the nearest .git above the directory nvim was started in; failing
    -- that that directory itself. The launch directory is read from
    -- jwa.init, which snapshots it before autochdir can move it - reading
    -- the live cwd here would defeat the whole point.
    local function project_root()
        local name = vim.api.nvim_buf_get_name(0)
        local from_buf = name ~= "" and vim.fs.root(name, ".git") or nil
        local launch = require("jwa").launch_dir or vim.fn.getcwd()
        return from_buf or vim.fs.root(launch, ".git") or launch
    end
    local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, {
            silent = true,
            desc = desc,
        })
    end

    -- Short forms (2026-08-15): <leader>t / <leader>T are instant
    -- aliases of ff / fF; the gitsigns toggles vacated <leader>t*.
    map("<leader>t", function()
        builtin.find_files({ cwd = project_root() })
    end, "Telescope: find files")
    map("<leader>T", function()
        builtin.find_files({ cwd = project_root(), no_ignore = true, hidden = true })
    end, "Telescope: find ALL files (ignored + hidden)")
    map("<leader>ff", function()
        builtin.find_files({ cwd = project_root() })
    end, "Telescope: find files")
    -- Capital sibling: same picker, but looking past ignore files and
    -- including dotfiles (2026-08-15).
    map("<leader>fF", function()
        builtin.find_files({ cwd = project_root(), no_ignore = true, hidden = true })
    end, "Telescope: find ALL files (ignored + hidden)")
    map("<leader>fg", function()
        builtin.live_grep({ cwd = project_root() })
    end, "Telescope: live grep (project contents)")
    map("<leader>fG", function()
        builtin.live_grep({
            cwd = project_root(),
            additional_args = { "--no-ignore", "--hidden" },
        })
    end, "Telescope: live grep ALL files (ignored + hidden)")
    map("<leader>fs", function()
        builtin.grep_string({ cwd = project_root() })
    end, "Telescope: grep word under cursor")
    -- Fuzzy search the CURRENT buffer's lines - the no-regex answer to
    -- "/" (2026-08-15). Slash mnemonic: f/ = find by searching.
    map("<leader>f/", builtin.current_buffer_fuzzy_find, "Telescope: fuzzy search this buffer")
    map("<leader>fb", builtin.buffers, "Telescope: open buffers")
    map("<leader>fr", builtin.oldfiles, "Telescope: recent files")
    map("<leader>fd", builtin.diagnostics, "Telescope: diagnostics")
    map("<leader>fh", builtin.help_tags, "Telescope: help tags")
    map("<leader>fk", builtin.keymaps, "Telescope: search keymaps")
end

return M
