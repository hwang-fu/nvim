-- ============================================================================
-- Language REPLs in floating terminals. Currently: utop (OCaml).
--
-- Built on the shared float helper in lua/jwa/term.lua (the same one
-- lazygit uses), with one extra behavior the git float does not have:
-- SESSION PERSISTENCE. Toggling the float away only hides the window - the
-- terminal buffer and the utop process underneath keep running, so bindings
-- and loaded modules survive a peek back at the code. The session ends when
-- utop itself exits (#quit or Ctrl-D), which tears down float + buffer via
-- term.run_in_float's on_exit.
--
-- Keymap (buffer-local, OCaml buffers only, installed by the FileType
-- autocmd in setup()):
--   <localleader>r   toggle the utop float for the current project
--                    (<localleader> = backslash, so: \r). Lives beside
--                    ocaml.nvim's other backslash maps (\c construct,
--                    \s switch intf/impl, ...); r is unused by that plugin.
--
-- Project awareness: sessions are keyed by dune project root, so two open
-- projects get two independent utops. Inside a dune project the REPL runs
-- `dune utop .` from the root - dune builds the project's libraries and
-- loads them into utop, which is what makes the REPL useful against your
-- own code. Outside any dune project it falls back to a plain `utop` in
-- the buffer's directory (stdlib-only scratchpad).
--
-- nvim-side escape hatch (same as the lazygit float): <C-\><C-n> leaves
-- terminal-insert mode to scroll or yank from the REPL; i resumes typing.
-- ============================================================================

local term = require("jwa.term")

local M = {}

-- One live session per project root: key -> { buf, win, job } as returned
-- by term.run_in_float (win goes stale after a hide; always re-validated).
local sessions = {}

-- Resolve the session key + command for the current buffer.
-- Returns: key (project root or buffer dir), argv table.
local function project_repl()
    local root = vim.fs.root(0, { "dune-project", "dune-workspace" })
    if root then
        -- `.` = build and load every library in the workspace scoped to
        -- this directory; running from the root keeps dune's paths sane.
        return root, { "dune", "utop", "." }
    end
    -- No project: plain utop in the file's own directory (or cwd for
    -- unnamed buffers).
    local dir = vim.fn.expand("%:p:h")
    if dir == "" then
        dir = vim.fn.getcwd()
    end
    return dir, { "utop" }
end

local function toggle_utop()
    local key, cmd = project_repl()
    local s = sessions[key]

    -- Case 1: float visible -> hide it, keep the session running. The
    -- window close does not kill the job because the terminal buffer has
    -- bufhidden=hide (see term.lua).
    if s and s.win and vim.api.nvim_win_is_valid(s.win) then
        vim.api.nvim_win_close(s.win, true)
        s.win = nil
        return
    end

    -- Case 2: hidden session alive -> re-show its buffer in a new float.
    -- Covers both the toggle-hide above and a window the user :q-ed.
    if s and vim.api.nvim_buf_is_valid(s.buf) then
        s.win = term.open_centered_win(s.buf)
        vim.cmd.startinsert()
        return
    end

    -- Case 3: no session for this project -> start one. on_exit clears
    -- the table entry when utop ends so the next toggle starts fresh.
    sessions[key] = term.run_in_float(cmd, {
        cwd = key,
        on_exit = function()
            sessions[key] = nil
        end,
    })
end

-- require("jwa.repl").setup()
function M.setup()
    -- Buffer-local map, OCaml buffers only - same scoping rationale as the
    -- gitsigns hunk maps: the key should not exist where it cannot work.
    -- The augroup keeps a config reload from stacking duplicate autocmds.
    local group = vim.api.nvim_create_augroup("JwaRepl", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "ocaml",
        callback = function(ev)
            vim.keymap.set("n", "<localleader>r", toggle_utop, {
                buffer = ev.buf,
                silent = true,
                desc = "REPL: toggle utop float (project-scoped)",
            })
        end,
    })
end

return M
