-- ============================================================================
-- Mouse keymappings: Ctrl+LeftClick smart jump (VSCode-style).
-- Split out of the old single keymap.lua (2026-08-15). Master index:
-- ./init.lua.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- Smart mouse jump (VSCode-style), bound to <C-LeftMouse> in setup().
--
-- Replaces Vim's built-in Ctrl+click tag jump (2026-08-15), which had an
-- ugly failure mode: when the LSP had no target for the clicked position
-- (typically: clicking a symbol AT its own definition), tagfunc fell
-- back to classic ctags and errored with E433 "No tags file" + E426
-- "Tag not found" + a press-ENTER prompt.
--
-- Behavior by case:
--   * click a usage                  -> jump to its definition (LSP)
--   * click a symbol at its own
--     definition                     -> list its REFERENCES instead
--                                       (what VSCode does for this)
--   * no target at all               -> references (which then reports
--                                       politely if there are none)
--   * buffer with no LSP definition
--     support                        -> the old tag jump, pcall-wrapped:
--                                       ctags projects still work, and
--                                       failures give one quiet notify
--                                       instead of the E433/E426 pair
--
-- Jump back with <C-o> (jumplist) - NOT <C-t>, which is the oil sidebar
-- toggle here (and tag-stack based anyway; this jump bypasses the tag
-- stack).
--
-- Implementation note: the decision runs in a RAW buf_request handler,
-- not vim.lsp.buf.definition's on_list - discovered 2026-08-15 that
-- on_list is never invoked for EMPTY results (the handler prints "No
-- locations found" and stops), which made the empty/at-definition
-- branch unreachable. On a real target the stock
-- vim.lsp.buf.definition() is re-run for the actual jump; that second
-- request is deliberate: definition lookups are millisecond-cheap, and
-- re-using the stock path keeps all of its behavior (single-target
-- jump, multi-target list) without re-implementing it here.
-- ----------------------------------------------------------------------------
function M.smart_definition()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
        method = "textDocument/definition",
    })

    if #clients == 0 then
        local ok = pcall(vim.cmd, "normal! \x1d") -- <C-]>: classic tag jump
        if not ok then
            vim.notify("No definition found (no LSP, no tags)", vim.log.levels.INFO)
        end
        return
    end

    local cur = vim.api.nvim_win_get_cursor(0)
    local curfile = vim.api.nvim_buf_get_name(bufnr)

    -- Params as a function: position encodings differ per client, so
    -- the position is computed with each client's own offset_encoding.
    local handled = false
    vim.lsp.buf_request(bufnr, "textDocument/definition", function(client, _)
        return vim.lsp.util.make_position_params(0, client.offset_encoding)
    end, function(_, result, _)
        -- With several capable clients the handler runs once per
        -- response; the first one wins.
        if handled then
            return
        end
        handled = true

        -- result: nil | Location | Location[] | LocationLink[]
        local locs = result or {}
        if not vim.islist(locs) then
            locs = { locs }
        end

        -- "Already at the definition" = every returned target is the
        -- very line the cursor sits on (column ignored: the name spans
        -- several columns).
        local at_self = #locs > 0
        for _, loc in ipairs(locs) do
            local uri = loc.uri or loc.targetUri
            local range = loc.range or loc.targetSelectionRange
            if vim.uri_to_fname(uri) ~= curfile or (range.start.line + 1) ~= cur[1] then
                at_self = false
                break
            end
        end

        if #locs == 0 or at_self then
            vim.lsp.buf.references()
        else
            vim.lsp.buf.definition()
        end
    end)
end

-- require("hwangfu.keymappings.mouse").setup()
function M.setup()
    local function map(modes, lhs, rhs, opts)
        vim.keymap.set(modes, lhs, rhs, opts or {})
    end

    -- --- Mouse: Ctrl+LeftMouse smart jump --------------------------------
    -- The <LeftMouse> prefix first moves the cursor to the clicked
    -- position (a pending mouse click in a mapping RHS is consumed as
    -- "position the cursor there"); the <Cmd> half then runs the smart
    -- jump from that spot. Full behavior table in M.smart_definition's
    -- comment above. Normal mode only, matching the LSP keymaps.
    map(
        "n",
        "<C-LeftMouse>",
        "<LeftMouse><Cmd>lua require('hwangfu.keymappings.mouse').smart_definition()<CR>",
        { silent = true, desc = "LSP: smart definition / references (mouse)" }
    )

    -- Ctrl+RightClick: live grep across the OPEN BUFFERS (2026-08-15;
    -- second revision that day - the first swap made this a project
    -- grep prefilled with the clicked word, which missed the intent).
    -- The user's model: "<leader>fb's scope with <leader>fg's
    -- mechanics" - an empty ripgrep prompt whose search space is just
    -- the files currently open as buffers (telescope's grep_open_files
    -- flag). Nothing is read from the click position, on purpose.
    --
    -- Caveat inherent to ripgrep: it reads files from DISK, so unsaved
    -- buffer modifications are invisible to this search and unnamed
    -- scratch buffers are not searched at all.
    --
    -- Buffers by NAME stay on <leader>fb; project-wide grep on
    -- <leader>fg. Shadows the built-in tag-stack pop, which the smart
    -- jump above bypasses anyway (it uses the jumplist; back: <C-o>).
    map(
        "n",
        "<C-RightMouse>",
        "<Cmd>lua require('telescope.builtin').live_grep({ grep_open_files = true })<CR>",
        { silent = true, desc = "Telescope: live grep the open buffers (mouse)" }
    )

    -- --- Plain right-click popup menu: config additions ------------------
    -- The right-click menu is an ordinary Neovim menu named PopUp;
    -- entries added here appear below the stock ones (Inspect, Go to
    -- definition, Paste, Select All, How-to disable mouse). Menus are
    -- global, so this runs once at startup, not per buffer.
    --
    -- "Find file" and "Search inside project" (2026-08-15, user
    -- request): the same plain file finder as <leader>t and the same
    -- project-wide live grep as <leader>fg. The separator first (-3- :
    -- the stock menu already uses -1- and -2-; separator names must be
    -- unique).
    vim.cmd([[anoremenu PopUp.-3- <Nop>]])
    vim.cmd([[anoremenu PopUp.Find\ file <Cmd>Telescope find_files<CR>]])
    vim.cmd([[anoremenu PopUp.Search\ inside\ project <Cmd>Telescope live_grep<CR>]])
end

return M
