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
    -- :update, not :write - a write with nothing to write still bumps mtime
    -- and wakes anything watching the file. Runs even when formatting did
    -- nothing: this command means "format and save", and a formatter that
    -- refused leaves the buffer as you typed it, which is what a plain :w
    -- would have written anyway.
    vim.cmd("update")
end, {
    desc = "Format this buffer (ocamllsp, or ocamlformat's janestreet profile), then save",
})

-- ============================================================================
-- Draw `fun` as a lambda (2026-09-14, user request).
--
-- Display only: 'conceallevel' is a window option, so the bytes on disk, the
-- buffer, grep, the git diff and what the compiler reads all still say `fun`.
--
-- WHY THIS IS HERE AND NOT IN after/syntax/ocaml.vim, which is where the
-- equivalent Rocq rule lives. OCaml is highlighted by treesitter here
-- (lua/jwa/plugins/spec/treesitter.lua lists ocaml and ocaml_interface), and
-- the consequence is that 'syntax' is EMPTY in these buffers - so the whole
-- syntax-file chain never runs and an after/syntax file is never sourced.
-- Checked with :scriptnames on a real .ml buffer, which lists the runtime
-- ftplugin, compiler and indent files and no syntax file at all. An ftplugin
-- runs on FileType regardless, so the rule is defined from here.
--
-- Concealment still works despite 'syntax' being empty, which is the part that
-- looks wrong and is not: concealing is not painting. It belongs to the syntax
-- engine's own machinery, which is live as soon as any :syn item exists for
-- the buffer, so treesitter supplies every colour and this supplies the one
-- substitution. Verified on a real buffer rather than assumed.
--
-- A KEYWORD rather than a match, for two reasons. Keywords outrank matches
-- whatever the definition order, so this cannot be shadowed later; and a
-- keyword matches whole words by 'iskeyword' on its own, which is what keeps
-- `function` and identifiers like `funny` or `fun_of` untouched with no
-- pattern to get wrong. containedin=ALL because a region only ever matches
-- the items its own contains= names.
--
-- nr2char() rather than a literal glyph, so this file stays pure ASCII the
-- same way after/syntax/coq.vim does: a codepoint survives an encoding
-- mishap, a pasted glyph does not, and grep for U+03BB finds this line.
--
-- concealcursor = "n" mirrors the Rocq setting: the cursor line joins the
-- concealing only in normal mode, so entering insert or visual snaps that one
-- line back to `fun`. That matters because a concealed word occupies one cell
-- instead of three and the cursor's real column stops matching where it is
-- drawn.
--
-- A cchar is always painted with the `Conceal` highlight group - the syntax
-- item's own group is ignored, so `hi link` cannot reach it. 'winhighlight'
-- is the way out: it remaps a group for THIS WINDOW only, so Conceal renders
-- as @keyword.function here, which is the treesitter capture that paints
-- `fun` itself (confirmed with vim.inspect_pos), and is untouched elsewhere.
--
-- DEFERRED WITH vim.schedule, and it does not work without that. Defining the
-- item inline leaves the buffer with no syntax items at all by the time the
-- file finishes loading: both this ftplugin and the treesitter starter run on
-- FileType, treesitter's runs second, and setting 'syntax' clears every item
-- the buffer had. Scheduling puts the definition after the whole FileType
-- round, past the clear. nvim_buf_call pins it to THIS buffer, because by the
-- time the callback runs the current buffer can be a different one - opening
-- several files at once is enough.
-- ============================================================================

local buf = vim.api.nvim_get_current_buf()
vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    vim.api.nvim_buf_call(buf, function()
        vim.cmd(
            "syntax keyword ocamlConcealedFun fun conceal containedin=ALL cchar="
                .. vim.fn.nr2char(0x03bb)
        )
    end)
end)

vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = "n"
vim.opt_local.winhighlight:append("Conceal:@keyword.function")

-- Keep the runtime's cleanup contract intact: change the filetype and the
-- command goes with it. Appended rather than assigned, or the runtime
-- ftplugin's own 'setlocal efm< foldmethod< foldexpr<' would be dropped.
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "")
    .. "delcommand OCamlFmt"
    .. " | syntax clear ocamlConcealedFun"
    .. " | setlocal conceallevel< concealcursor< winhighlight<"
