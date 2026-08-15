-- ============================================================================
-- File explorer sidebar: oil.nvim in a fixed-width left split.
--
-- History: from 2026-08 to 2026-08-14 the global <C-t> opened oil in the
-- CURRENT window (full screen). This module replaced that for NERDTree
-- parity: <C-t> now toggles a left sidebar, and files chosen inside it
-- open in the main window. Decisions made when it was built (2026-08-14),
-- all confirmed explicitly:
--
--   * WIDTH = 35 columns  - NERDTree's default was 31; 35 fits oil's
--                           icon + name columns without truncating
--                           typical file names.
--   * Auto-close on open  - selecting a FILE closes the sidebar after
--                           opening it (NERDTree's default keeps the
--                           tree; the close-after-open variant was
--                           chosen here).
--   * No inline expansion - <CR> on a folder REPLACES the sidebar
--                           listing rather than expanding the folder
--                           in place. This is oil's architecture, not a
--                           choice: one directory per buffer, edits
--                           parsed as filesystem ops against that one
--                           directory. A multi-directory tree view has
--                           no representation in that model (oil's own
--                           README calls file trees "a different
--                           category entirely"). Walk back with the ../
--                           first row or the <C-o> jumplist. If inline
--                           expansion ever becomes a must-have, the
--                           answer is a tree plugin (nvim-tree), not
--                           more code here.
--
-- Who calls what (no setup() - the module is required on demand):
--   * keymap.lua  <C-t> (global)      -> M.toggle()
--   * plugins.lua oil spec  <CR>      -> M.select()      (oil buffers)
--   * plugins.lua oil spec  <C-t>     -> M.smart_close() (oil buffers;
--     shadows the global map there - see that function's comment)
-- ============================================================================

local M = {}

-- Sidebar width in columns (see the decision note in the header).
local WIDTH = 35

-- Window handle of the open sidebar (nil when closed). At most one
-- sidebar per session, deliberately - matching the single NERDTree pane.
local sidebar_win = nil

-- The window <C-t> was pressed in: where files selected in the sidebar
-- should open. Re-recorded on every toggle; if it vanished in the
-- meantime, open_in_main falls back to any non-sidebar window.
local return_win = nil

local function is_sidebar(win)
    return sidebar_win ~= nil
        and vim.api.nvim_win_is_valid(sidebar_win)
        and win == sidebar_win
end

local function close_sidebar()
    if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
        vim.api.nvim_win_close(sidebar_win, true)
    end
    sidebar_win = nil
end

-- Open `path` in the main window, then close the sidebar (the auto-close
-- decision from the header).
local function open_in_main(path)
    local target = nil
    if
        return_win
        and vim.api.nvim_win_is_valid(return_win)
        and return_win ~= sidebar_win
    then
        target = return_win
    else
        -- The original window is gone: fall back to the first window in
        -- layout order that is not the sidebar.
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if w ~= sidebar_win then
                target = w
                break
            end
        end
    end

    if target == nil then
        -- The sidebar is the only window left: take it over as a normal
        -- window instead of splitting a 35-column editor.
        sidebar_win = nil
        vim.cmd.edit(vim.fn.fnameescape(path))
        return
    end

    vim.api.nvim_set_current_win(target)
    vim.cmd.edit(vim.fn.fnameescape(path))
    close_sidebar()
end

-- The global <C-t> behavior. Three cases, in order:
--   1. Sidebar open (focus anywhere)  -> close it.
--   2. Current buffer is a FULL-WINDOW oil listing (e.g. `nvim some/dir`,
--      where oil hijacks the directory buffer) -> close the listing,
--      returning to the previous buffer - the pre-sidebar behavior.
--   3. Otherwise -> open the sidebar at the current buffer's directory.
--
-- Case 3 re-roots on every press: the fresh vsplit still shows the
-- buffer <C-t> was pressed in, and oil.open() with no argument resolves
-- THAT buffer's directory (cwd for unnamed buffers). After jumping (gd,
-- telescope, ...) into a file elsewhere on disk, the sidebar shows that
-- file's directory, not where nvim was launched - the same behavior the
-- full-window toggle had, and the old NERDTree wrapper before it.
function M.toggle()
    if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
        close_sidebar()
        return
    end
    sidebar_win = nil -- clear a stale handle (sidebar window :q-ed away)

    if vim.bo.filetype == "oil" then
        require("oil").close()
        return
    end

    return_win = vim.api.nvim_get_current_win()
    vim.cmd("topleft " .. WIDTH .. "vsplit")
    sidebar_win = vim.api.nvim_get_current_win()
    -- Hold the width when other windows open, close, or equalize (<C-w>=).
    vim.wo[sidebar_win].winfixwidth = true
    require("oil").open()
end

-- <CR> in any oil buffer (wired in the oil spec's keymaps table):
--   * outside the sidebar -> oil's stock select, unchanged
--   * sidebar + directory -> oil's stock select: the listing is replaced
--     IN the sidebar (../ row included; no inline expansion - header)
--   * sidebar + file      -> open in the main window, close the sidebar
function M.select()
    local oil = require("oil")
    if not is_sidebar(vim.api.nvim_get_current_win()) then
        oil.select()
        return
    end

    local entry = oil.get_cursor_entry()
    local dir = oil.get_current_dir()
    if entry == nil or dir == nil then
        return
    end

    -- fs_stat follows symlinks, so a link-to-directory navigates like a
    -- directory instead of being opened as a file in the main window.
    local path = dir .. entry.name
    local stat = vim.uv.fs_stat(path)
    if entry.type == "directory" or (stat and stat.type == "directory") then
        oil.select()
    else
        open_in_main(path)
    end
end

-- <C-t> inside oil buffers, where the spec's buffer-local map shadows the
-- global toggle. In the sidebar it must close the WINDOW: plain
-- oil.close() would swap the previous buffer into the 35-column split
-- and leave that sliver orphaned. Outside the sidebar (full-window
-- listing) it keeps the old close-the-listing behavior.
function M.smart_close()
    if is_sidebar(vim.api.nvim_get_current_win()) then
        close_sidebar()
    else
        require("oil").close()
    end
end

return M
