-- ============================================================================
-- :CSharpFmt - format the current C# or Razor buffer on demand (2026-09-08).
--
-- Fifth language on the manual path, after Rust, OCaml, Haskell and Clojure,
-- and the only one that was never on the save path to begin with: C# support
-- arrived after on-demand had become the house style.
--
-- The body is one call into M.format_csharp_buffer(), which owns the client
-- filter and the no-server warning. Formatting runs through the Roslyn server,
-- which is also configured to sort using directives while it is there
-- (lua/jwa/lsp/servers/roslyn.lua).
--
-- Razor gets the same command through after/ftplugin/razor.lua, which pulls
-- this file in - a .razor component is C# and markup in one buffer, and there
-- is no sense in it having a different key for the same server.
-- ============================================================================

vim.api.nvim_buf_create_user_command(0, "CSharpFmt", function()
    require("jwa.lsp.format").format_csharp_buffer()
    -- :update, not :write - a write with nothing to write still bumps mtime
    -- and wakes anything watching the file. Runs even when formatting did
    -- nothing, including the no-client case that only warns: this command
    -- means "format and save", and a formatter that refused leaves the buffer
    -- as you typed it, which is what a plain :w would have written anyway.
    vim.cmd("update")
end, {
    desc = "Format this buffer through Roslyn, sort usings, then save",
})

-- Keep the runtime's cleanup contract intact: change the filetype and the
-- command goes with it. Appended rather than assigned, so whatever the runtime
-- ftplugin registered for undo survives.
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "") .. "delcommand CSharpFmt"
