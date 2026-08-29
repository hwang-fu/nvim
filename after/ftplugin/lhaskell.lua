-- Literate Haskell gets the same :HaskellFmt as ordinary Haskell.
--
-- Chaining to the sibling ftplugin rather than repeating its body is the
-- runtime's own idiom for related filetypes (ftplugin/cpp.vim is a bare
-- `runtime! ftplugin/c.vim`), and it keeps the command, its explanation, and
-- the b:undo_ftplugin bookkeeping in exactly one file.
vim.cmd("runtime after/ftplugin/haskell.lua")
