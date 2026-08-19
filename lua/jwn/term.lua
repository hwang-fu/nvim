-- ============================================================================
-- Shared floating-terminal helpers.
--
-- Extracted from lua/jwn/git.lua (2026-08), where the float was born for
-- lazygit with a comment promising "a second tool is a one-keymap addition,
-- not a rewrite". The utop REPL (lua/jwn/repl.lua) is that second tool,
-- so the helper now lives here and both modules require it.
--
-- Two entry points with different lifetimes:
--   * run_in_float(cmd, opts)  - scratch buffer + float + terminal job in
--                                one call. The WINDOW collapses and the
--                                BUFFER is deleted when the program exits.
--                                Callers that want the buffer to survive a
--                                window close (hide / re-show cycles, e.g.
--                                a REPL session) manage that themselves via
--                                the returned handles and open_centered_win.
--   * open_centered_win(buf)   - just the window: show an EXISTING buffer
--                                in the centered float. Used to re-show a
--                                hidden terminal buffer without restarting
--                                its job.
--
-- No plugin behind this - ~40 lines of native API (scratch buffer +
-- nvim_open_win + jobstart with term = true), which fits how this config
-- leans elsewhere: native vim.lsp.config for LSP, built-in gc for
-- commenting, vim.snippet for snippets.
-- ============================================================================

local M = {}

-- Open a centered float (90% x 90%, rounded border) showing `buf`; returns
-- the window handle. vim.o.lines includes the cmdline and statusline rows;
-- the -2 keeps the border on screen.
function M.open_centered_win(buf)
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor((vim.o.lines - 2) * 0.9)
    return vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - 2 - height) / 2),
        style = "minimal",
        border = "rounded",
    })
end

-- Run `cmd` (an argv table) as a terminal job in a centered float.
--
-- opts:
--   cwd      directory to run in. Without it the program would open in
--            whatever Neovim's :cwd happens to be.
--   on_exit  optional callback, invoked (scheduled) after the program ends
--            and the default cleanup ran. Lets callers clear their own
--            bookkeeping (e.g. repl.lua's session table).
--
-- Returns { buf = ..., win = ..., job = ... }.
--
-- term = true turns the buffer into a terminal running cmd (the Neovim 0.11
-- replacement for the deprecated termopen()). The scratch buffer is created
-- with bufhidden=hide (nvim_create_buf scratch default), so a caller closing
-- just the WINDOW keeps the buffer and its job alive - that is what makes
-- the REPL's hide / re-show toggle possible. The on_exit below is the other
-- half: when the PROGRAM ends, both window and buffer are torn down; the
-- validity checks cover a window the user already closed manually with :q.
function M.run_in_float(cmd, opts)
    opts = opts or {}

    -- Scratch buffer: no file, unlisted, wiped only on the job's exit.
    local buf = vim.api.nvim_create_buf(false, true)
    local win = M.open_centered_win(buf)

    local job = vim.fn.jobstart(cmd, {
        term = true,
        cwd = opts.cwd,
        on_exit = function()
            vim.schedule(function()
                -- The buffer may be shown in a different window by now
                -- (hidden and re-shown); close whichever window shows it.
                local shown = vim.fn.win_findbuf(buf)
                for _, w in ipairs(shown) do
                    if vim.api.nvim_win_is_valid(w) then
                        vim.api.nvim_win_close(w, true)
                    end
                end
                if vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_delete(buf, { force = true })
                end
                if opts.on_exit then
                    opts.on_exit()
                end
            end)
        end,
    })

    -- Land in terminal-insert mode so the program sees keystrokes right away.
    vim.cmd.startinsert()

    return { buf = buf, win = win, job = job }
end

return M
