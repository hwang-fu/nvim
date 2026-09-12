-- ============================================================================
-- Rocq symbol concealing: window options and the on/off commands
-- (2026-09-12, user request). The symbols themselves are in
-- after/syntax/coq.vim.
--
-- On by default. `conceallevel = 2` hides a concealed match entirely unless it
-- has a replacement character, which every match in the syntax file does.
--
-- `concealcursor = "n"` is the requested behaviour, and reads backwards until
-- you know what the option means: it lists the modes in which the CURSOR LINE
-- is *also* concealed. Every other line is concealed regardless. So listing
-- only `n` gives concealed text while you move around in normal mode, and the
-- raw `forall` back on the line you are working on the moment you enter insert
-- or visual mode - which is when you need the real columns, because a
-- concealed word occupies one cell instead of six and the cursor's true column
-- stops matching where it is drawn.
--
-- Vim's own help files use "nc", adding command-line mode so incsearch does
-- not un-conceal. Left out here: the request was normal concealed, insert and
-- visual not, and `c` is neither.
--
-- The commands are buffer-local, which is honest about their reach - they are
-- meaningless outside a Rocq buffer - even though the option they set is
-- window-local. Names checked against Coqtail's seventeen Rocq* commands and
-- against every command in a loaded .v buffer: nothing else claims either.
-- ============================================================================

vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = "n"

-- Give the concealed glyphs their original colour (2026-09-13, user request).
--
-- A cchar is ALWAYS painted with the `Conceal` highlight group; the syntax
-- item's own group is ignored. Verified rather than assumed: linking
-- rocqConcealed1 to Todo left the drawn cell reporting hi_name = "Conceal",
-- and recolouring Conceal changed the glyph immediately. So `hi link` on our
-- own groups can never work here - the only lever is Conceal itself.
--
-- Conceal is one global group, which would mean recolouring every concealed
-- character in every filetype. 'winhighlight' is the way out: it remaps a
-- highlight group for THIS WINDOW only, so Conceal renders as coqKwd here and
-- is untouched everywhere else. coqKwd is the right target because it is what
-- Coqtail highlights all five substitutions with - forall, exists, \/, /\ and
-- ~ all resolve to it - so the glyph keeps exactly the colour the ASCII had.
--
-- Appended rather than assigned, in case something else has already put an
-- entry in this window's list.
vim.opt_local.winhighlight:append("Conceal:coqKwd")

vim.api.nvim_buf_create_user_command(0, "RocqConceal", function()
    vim.wo.conceallevel = 2
end, {
    desc = "Show forall and exists as symbols in this window",
})

vim.api.nvim_buf_create_user_command(0, "RocqUnconceal", function()
    vim.wo.conceallevel = 0
end, {
    desc = "Show the file as written, with no symbol substitution",
})

-- Keep the runtime's cleanup contract intact: change the filetype and the
-- commands go with it. Appended rather than assigned, so whatever the runtime
-- ftplugin and Coqtail's own registered for undo survives.
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "")
    .. "delcommand RocqConceal | delcommand RocqUnconceal"
    .. " | setlocal conceallevel< concealcursor< winhighlight<"
