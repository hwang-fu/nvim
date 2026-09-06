-- ============================================================================
-- :ClojureFmt - format the current Clojure buffer on demand (2026-09-06).
--
-- Clojure's format-on-save was removed the same day (lua/jwa/lsp/format.lua),
-- joining Rust, OCaml and Haskell. The body is one call into
-- M.format_clojure_buffer(), which owns the client filter and the
-- no-server-attached warning.
--
-- In after/ftplugin so it lands on top of whatever the runtime ftplugin
-- defined, and buffer-local so the name exists only where it means something.
--
-- One file covers the whole family: Neovim maps .clj, .cljs, .cljc and .edn
-- all to the `clojure` filetype, and cljfmt is the formatter for every one of
-- them.
--
-- Note that conjure also lives in these buffers and owns the <localleader>
-- keys. Nothing here touches those - this is a command, not a mapping, so the
-- two do not compete.
-- ============================================================================

vim.api.nvim_buf_create_user_command(0, "ClojureFmt", function()
    require("jwa.lsp.format").format_clojure_buffer()
    -- :update, not :write - a write with nothing to write still bumps mtime
    -- and wakes anything watching the file. Runs even when formatting did
    -- nothing, including the no-client case that only warns: this command
    -- means "format and save", and a formatter that refused leaves the buffer
    -- as you typed it, which is what a plain :w would have written anyway.
    vim.cmd("update")
end, {
    desc = "Format this buffer through clojure-lsp (cljfmt), then save",
})

-- Keep the runtime's cleanup contract intact: change the filetype and the
-- command goes with it. Appended rather than assigned, so whatever the runtime
-- ftplugin registered for undo survives.
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "") .. "delcommand ClojureFmt"
