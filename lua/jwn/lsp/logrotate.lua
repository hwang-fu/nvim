-- ============================================================================
-- LSP log size cap (2026-08-15, user request).
--
-- Neovim's LSP client appends to one shared log file forever
-- (state/nvim/lsp.log); nothing in core ever rotates or truncates it. On
-- this machine it had grown to 26 MB in three months, and entries older
-- than a few sessions are never worth reading. This module checks the
-- size once per Neovim start and, when the file exceeds MAX_BYTES,
-- rewrites it keeping only the newest KEEP_BYTES.
--
-- Thresholds:
--   * MAX_BYTES (20 MB)  - trim trigger. Deliberately below the 100 MB the
--     user first floated: the log is write-mostly junk (every -32xxx error
--     the notify filter hides from the UI still lands here), and 20 MB is
--     already far more history than a debugging session ever looks at.
--   * KEEP_BYTES (10 MB) - what survives a trim, newest entries first.
--     Keeping half the cap means trims happen rarely (every ~10 MB of
--     growth), not on every start once the cap is first crossed.
-- Both are plain constants; adjust here if the taste changes.
--
-- Why trim IN PLACE (open "wb" on the same path) instead of the classic
-- write-temp-then-rename rotation: several Neovim instances may be
-- running, all appending to this same file through O_APPEND handles. A
-- rename would leave those instances writing to the unlinked old inode -
-- their log output silently lost until restart. Rewriting in place keeps
-- the inode, so concurrent appenders continue working; O_APPEND always
-- seeks to the current end atomically. The only loss window is an entry
-- appended between our read and our rewrite - an acceptable cost for a
-- diagnostic log.
--
-- The trim aligns to a line boundary (drops the partial first line of the
-- kept tail) and prepends a one-line marker recording when the trim
-- happened and how much was cut, so a truncated log is self-explaining.
--
-- Timing: deferred a few seconds past setup() so startup cost is zero and
-- the check runs after the UI is up. Trimming while THIS instance's LSP
-- clients are already logging is safe for the same O_APPEND reason as
-- above. A one-line notify reports a trim when one actually happens;
-- silent otherwise.
--
-- Manual escape hatch: :lua require("jwn.lsp.logrotate").trim()
-- trims immediately (same thresholds).
-- ============================================================================

local M = {}

local MAX_BYTES = 20 * 1024 * 1024
local KEEP_BYTES = 10 * 1024 * 1024

-- Resolve the LSP log path. vim.lsp.log.get_filename() is the current
-- accessor; vim.lsp.get_log_path() is deprecated on 0.12. The stdpath
-- fallback covers older releases where neither pcall target exists.
local function lsp_log_path()
    local ok, path = pcall(function()
        return vim.lsp.log.get_filename()
    end)
    if ok and type(path) == "string" and path ~= "" then
        return path
    end
    return vim.fn.stdpath("state") .. "/lsp.log"
end

-- Trim one file down to KEEP_BYTES if it exceeds MAX_BYTES. Returns the
-- number of bytes cut, or nil when nothing was done (missing file, under
-- the cap, or an io failure - all deliberately silent: a log cap must
-- never break startup).
---@param path string? defaults to the LSP log
---@return integer? bytes_cut
function M.trim(path)
    path = path or lsp_log_path()

    local stat = vim.uv.fs_stat(path)
    if not stat or stat.size <= MAX_BYTES then
        return nil
    end

    local f = io.open(path, "rb")
    if not f then
        return nil
    end
    f:seek("set", stat.size - KEEP_BYTES)
    local tail = f:read("*a")
    f:close()
    if not tail or tail == "" then
        return nil
    end

    -- The seek almost certainly landed mid-entry; drop up to and
    -- including the first newline so the kept tail starts on a whole
    -- log line.
    local nl = tail:find("\n", 1, true)
    if nl then
        tail = tail:sub(nl + 1)
    end

    local marker = string.format(
        "[jwn.lsp.logrotate] %s: trimmed this log from %d to %d bytes\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        stat.size,
        #tail
    )

    local out = io.open(path, "wb")
    if not out then
        return nil
    end
    out:write(marker)
    out:write(tail)
    out:close()

    return stat.size - #tail
end

function M.setup()
    -- Deferred, not immediate: keeps the startup path free of file IO,
    -- and a couple of seconds changes nothing for a size cap.
    vim.defer_fn(function()
        local cut = M.trim()
        if cut then
            vim.notify(
                string.format("lsp.log exceeded %dMB; trimmed %dMB of old entries", MAX_BYTES / 1024 / 1024, math.floor(cut / 1024 / 1024)),
                vim.log.levels.INFO
            )
        end
    end, 3000)
end

return M
