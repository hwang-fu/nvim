-- ============================================================================
-- Git UI: lazygit in a floating terminal.
--
-- No plugin behind this - the float helper is native API, and since 2026-08
-- it lives in lua/hwangfu/term.lua (shared with the utop REPL float in
-- lua/hwangfu/repl.lua; it originated here for lazygit alone). lazygit
-- itself is installed system-wide (a `go install` binary on PATH).
--
-- Division of labor across the git tooling:
--   * gitsigns (plugins.lua)  - in-buffer hunks: signs, stage / reset,
--                               blame, buffer-vs-index diffs (<leader>h*).
--   * THIS MODULE             - repo-level porcelain: stage, commit,
--                               branch, push / pull, conflicts -
--                               everything lazygit does, floating over
--                               the editor.
--   * diffview (plugins.lua)  - read-only inspection: whole-changeset
--                               side-by-side diffs and history
--                               (<leader>gd / gh / gH).
--
-- Keymap (global, normal mode):
--   <leader>gg   open lazygit in a centered float (90% x 90%, rounded
--                border), rooted at the current buffer's repository.
--                Quit lazygit (q) and the float collapses.
--
-- lazygit quick reference. These are lazygit's OWN keys, not nvim maps:
-- the float sits in terminal-insert mode, so keystrokes go straight to
-- lazygit. Press ? inside for the full, always-current list. Stock
-- defaults apply (~/.config/lazygit/config.yml exists but is empty;
-- rebinding happens there if ever wanted).
--
-- Global:
--   q          quit lazygit (ends the job -> the float collapses; use
--              this rather than :q-ing the window, which would leave
--              lazygit running in a hidden buffer)
--   esc        back / cancel
--   ?          keybinding help for the focused panel
--   h / l      move between panels (or 1-5 to jump directly)
--   [ / ]      previous / next tab inside a panel
--   P / p      push / pull
--   R          refresh
-- Files panel:
--   space      stage / unstage file     a   stage / unstage everything
--   enter      line-by-line staging (space stages a line/hunk, v ranges)
--   c          commit                   A   amend last commit
--   d          discard changes (menu)   s   stash all changes
-- Branches panel:
--   space      checkout selected        n   new branch
--   M          merge selected into current
--   r          rebase current onto selected
--   f          fast-forward selected
-- Commits panel:
--   enter      inspect commit files     r   reword message
--   s          squash into the one below
--   e          edit (interactive rebase from here)
--   d          drop commit              g   reset menu (soft/mixed/hard)
--   c / v      copy / paste commits (cherry-pick)
--
-- nvim-side escape hatch: <C-\><C-n> leaves terminal-insert mode (to
-- scroll the float or yank from it); i re-enters and resumes lazygit.
--
-- Guard: refuses to launch outside a git repository (vim.notify error
-- instead). lazygit's out-of-repo behavior is an interactive "create a
-- new repo here?" prompt, which a stray keypress should never reach.
--
-- gitsigns needs no refresh plumbing after lazygit actions: it watches
-- the git dir and updates signs / statusline counts on its own.
-- ============================================================================

local term = require("hwangfu.term")

local M = {}

-- require("hwangfu.git").setup()
function M.setup()
    vim.keymap.set("n", "<leader>gg", function()
        -- Git-root guard: resolve from the current buffer's path first,
        -- then from cwd (covers unnamed / scratch buffers). vim.fs.root
        -- returns nil when no .git marker exists on the way up.
        local root = vim.fs.root(0, ".git")
            or vim.fs.root(vim.fn.getcwd(), ".git")
        if not root then
            vim.notify(
                "lazygit: not inside a git repository",
                vim.log.levels.ERROR
            )
            return
        end
        term.run_in_float({ "lazygit" }, { cwd = root })
    end, {
        silent = true,
        desc = "Git: open lazygit in a float",
    })
end

return M
