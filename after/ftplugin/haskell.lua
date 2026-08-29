-- ============================================================================
-- :HaskellFmt - format the current Haskell buffer on demand (2026-08-29).
--
-- Haskell's format-on-save was removed the same day (lua/jwa/lsp/format.lua),
-- following Rust and OCaml. The body is one call into
-- M.format_haskell_buffer(), which owns the client filter and the
-- no-server-attached warning; keeping the logic there leaves this file free of
-- anything that could drift out of step with it.
--
-- In after/ftplugin so it lands on top of the runtime's ftplugin/haskell.vim,
-- and buffer-local so the name exists only where it means something.
--
-- Literate Haskell gets it too: after/ftplugin/lhaskell.lua pulls this file in.
-- haskell-tools attaches HLS to `lhaskell` buffers as well, so the command has
-- a server to talk to there; whether ormolu accepts literate source is HLS's
-- business rather than this command's.
-- ============================================================================

vim.api.nvim_buf_create_user_command(0, "HaskellFmt", function()
    require("jwa.lsp.format").format_haskell_buffer()
end, {
    desc = "Format this buffer through HLS (ormolu)",
})

-- Keep the runtime's cleanup contract intact: change the filetype and the
-- command goes with it. Appended rather than assigned, so whatever the runtime
-- ftplugin registered for undo survives.
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "") .. "delcommand HaskellFmt"
