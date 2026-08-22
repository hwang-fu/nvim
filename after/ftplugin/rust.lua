-- ============================================================================
-- Repurpose the legacy :RustFmt name to LSP formatting (2026-08-22).
--
-- Neovim's bundled runtime defines a buffer-local :RustFmt in
-- ftplugin/rust.vim (inherited from the pre-LSP rust.vim plugin). That
-- implementation shells out to the rustfmt binary directly and, when no
-- rustfmt.toml declares an edition, HARDCODES --edition 2018 - so on
-- 2021/2024-edition projects it can choke on or misformat syntax the
-- old edition lacks (let-else and friends).
--
-- This config used to dodge the name with a global :RustFormat command
-- (lsp/servers/rust_analyzer.lua). The user preferred owning the
-- familiar name instead, so :RustFormat is gone and :RustFmt now runs
-- the real pipeline: vim.lsp.buf.format -> rust-analyzer -> rustfmt
-- with the project's true edition from Cargo.toml, applied as minimal
-- text edits. (Format-on-save stays off for Rust by choice; this is
-- the manual entry point.)
--
-- Why THIS file: after/ftplugin/rust.lua is sourced AFTER the runtime
-- ftplugin for every Rust buffer, so the override below always lands
-- on top of the legacy definition, whatever the autocmd registration
-- order. nvim_buf_create_user_command REPLACES the existing command
-- (no delcommand needed), which also keeps the runtime's
-- b:undo_ftplugin cleanup (delcommand RustFmt / RustFmtRange) valid.
--
-- :RustFmtRange is overridden too rather than deleted: the legacy one
-- carries the same edition footgun, rust-analyzer advertises no range
-- formatting (rustfmt is whole-file-minded), and deleting it would
-- break that b:undo_ftplugin cleanup. It now just says so.
-- ============================================================================

vim.api.nvim_buf_create_user_command(0, "RustFmt", function()
    vim.lsp.buf.format({
        async = false,
        name = "rust-analyzer",
    })
end, {
    desc = "Format via rust-analyzer (rustfmt, project edition)",
})

vim.api.nvim_buf_create_user_command(0, "RustFmtRange", function()
    vim.notify(
        "RustFmtRange: rust-analyzer offers no range formatting (rustfmt is whole-file); use :RustFmt",
        vim.log.levels.WARN
    )
end, {
    range = true,
    desc = "Unsupported: rustfmt formats whole files; use :RustFmt",
})
