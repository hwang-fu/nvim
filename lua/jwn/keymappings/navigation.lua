-- ============================================================================
-- Navigation keymappings: oil sidebar toggle + buffer cycling.
-- Split out of the old single keymap.lua (2026-08-15). Master index:
-- ./init.lua.
-- ============================================================================

local M = {}

-- require("jwn.keymappings.navigation").setup()
function M.setup()
    local function map(modes, lhs, rhs, opts)
        vim.keymap.set(modes, lhs, rhs, opts or {})
    end

    -- --- Oil (file explorer sidebar) ------------------------------------
    -- <C-t> toggles a fixed-width left SIDEBAR listing the *current
    -- buffer's* directory. The behavior lives in lua/jwn/explorer.lua
    -- (width, auto-close-on-open, and the no-inline-expansion limitation
    -- are all documented in that module's header); this map is just the
    -- global entry point. Case summary:
    --   * Sidebar open (focus anywhere) -> close it.
    --   * Current buffer is a FULL-WINDOW oil listing (`nvim some/dir`)
    --     -> close the listing, back to the previous buffer (the
    --     pre-sidebar behavior, kept for that case).
    --   * Otherwise -> open the sidebar at the buffer's directory
    --     (re-roots on every press: after gd / telescope into a file
    --     elsewhere on disk, the sidebar shows THAT file's directory).
    --
    -- History: from 2026-08 to 2026-08-14 this map opened oil in the
    -- current window (full screen); replaced by the sidebar for NERDTree
    -- parity.
    --
    -- Side-effect free: does NOT change Neovim's :cwd, so plugins keyed
    -- off cwd (lazy, telescope's default scope, etc.) keep behaving the
    -- same. If you also want :cwd to follow, see `:h 'autochdir'`.
    --
    -- Buffer-local keys inside oil listings (`..` up-dir alias, the
    -- sidebar-aware <CR> and <C-t> overrides, <C-s> passthrough to save)
    -- are configured in oil's spec (plugins/spec/oil.lua), next to
    -- the plugin they belong to -- the same split used for the gitsigns
    -- hunk maps.
    map("n", "<C-t>", function()
        require("jwn.explorer").toggle()
    end, {
        silent = true,
        desc = "Toggle oil sidebar at current buffer's directory",
    })

    -- --- Buffers --------------------------------------------------------
    -- A buffer is a file Neovim has loaded into memory; these keys move
    -- between buffers and close them. Opening a file, or picking a buffer
    -- from a list, is handled by telescope (<leader>ff / <leader>fb).
    --
    -- Returning after a jump: commands like gd (go-to-definition) can send
    -- you off into another file. Neovim records each such jump in the
    -- jumplist; press <C-o> to jump back to where you were and <C-i> to go
    -- forward again. <C-^> toggles between the current and previous buffer.
    -- (<C-o> / <C-i> / <C-^> are built-in Neovim keys, listed here for
    -- reference; this file does not map them.)
    -- With a single listed buffer, :bnext/:bprevious silently stay put;
    -- explain the no-op with a WARN notice instead (WARN, not ERROR: a
    -- short one-line notify interrupts nothing).
    local function cycle_buffer(cmd)
        if #vim.fn.getbufinfo({ buflisted = 1 }) <= 1 then
            vim.notify("Only one buffer is open", vim.log.levels.WARN)
            return
        end
        vim.cmd(cmd)
    end

    map("n", "]b", function()
        cycle_buffer("bnext")
    end, {
        silent = true,
        desc = "Next buffer (warns when only one is open)",
    })
    map("n", "[b", function()
        cycle_buffer("bprevious")
    end, {
        silent = true,
        desc = "Previous buffer (warns when only one is open)",
    })
    map("n", "<leader>bd", ":bdelete<CR>", {
        silent = true,
        desc = "Close (delete) current buffer",
    })
end

return M
