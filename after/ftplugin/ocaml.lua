-- ============================================================================
-- :OCamlFmt - format the current OCaml buffer on demand (2026-08-29).
--
-- OCaml's format-on-save was removed the same day (lua/jwa/lsp/format.lua), so
-- this is now the only thing that reformats an .ml / .mli buffer. It is NOT a
-- second implementation: it calls straight into the module that used to own
-- the save-time handlers, which still decides between ocamllsp and the Jane
-- Street CLI by looking for a .ocamlformat up-tree. The reasoning for that
-- split lives on M.format_ocaml_buffer(); duplicating it here would give the
-- two entry points room to drift apart.
--
-- Shaped after after/ftplugin/rust.lua's :RustFmt - buffer-local, so the name
-- exists only where it means something, and in after/ftplugin so it lands on
-- top of whatever the runtime ftplugin defined. Unlike :RustFmt there is no
-- legacy command of this name to displace (the runtime's ocaml.vim only sets
-- 'errorformat' and folding), so b:undo_ftplugin is extended below rather
-- than inherited.
--
-- The filetype covers both halves of a module: Neovim maps .ml and .mli alike
-- to `ocaml`, and format_ocaml_buffer() reads the extension to tell ocamlformat
-- which of --impl / --intf it is being handed.
-- ============================================================================

vim.api.nvim_buf_create_user_command(0, "OCamlFmt", function()
    require("jwa.lsp.format").format_ocaml_buffer()
end, {
    desc = "Format this buffer (ocamllsp, or ocamlformat's janestreet profile)",
})

-- Keep the runtime's cleanup contract intact: change the filetype and the
-- command goes with it. Appended rather than assigned, or the runtime
-- ftplugin's own 'setlocal efm< foldmethod< foldexpr<' would be dropped.
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "") .. "delcommand OCamlFmt"
