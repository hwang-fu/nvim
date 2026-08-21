-- ============================================================================
-- ocamllsp: OCaml language server (also handles Reason, Dune, Menhir).
--
-- Formatting goes through ocamlformat, which only kicks in when the project
-- root has a `.ocamlformat` file - THROUGH THIS SERVER. Since 2026-08-14,
-- projects without one no longer go unformatted: lsp/format.lua carries a
-- CLI fallback (`ocamlformat --enable-outside-detected-project
-- --profile=janestreet`) that fires exactly when no .ocamlformat exists up
-- the tree, so scratch projects get Jane Street style and project files
-- always win.
--
-- RELATIONSHIP TO ocaml.nvim (plugins/spec/ocaml.lua): the tarides/ocaml.nvim plugin
-- adds :OCaml* commands (construct, hole navigation, switch intf/impl,
-- type search, ...) ON TOP of the client defined here - it does NOT start
-- or own the LSP client. This file must therefore stay in the SERVERS
-- table, unlike rust_analyzer / hls / elixirls whose plugins own their
-- clients end-to-end.
--
-- SETTINGS SCHEMA (checked against ocaml-lsp 1.26, 2026-08). ocaml-lsp reads
-- its options from the TOP LEVEL of the `settings` table sent via
-- workspace/didChangeConfiguration -- there is no "ocaml" wrapper key. The
-- full interface lives at:
--   ocaml-lsp-server/docs/ocamllsp/config.md   (in the ocaml/ocaml-lsp repo)
--
-- History note (2026-08): this file previously sent
-- `inlayHints = { enable = true }`, which is NOT in the schema -- the server
-- silently ignored it and no inlay hints were ever produced. The real knobs
-- are the three independent hint kinds below, all of which default to false.
-- Same cleanup wired up codelens DISPLAY: the server computed lenses all
-- along, but Neovim renders none until the buffer opts in - see
-- enable_codelens below.
--
-- Settings currently left at their (off) defaults, available when wanted:
--   * syntaxDocumentation.enable    - explain syntax constructs in hover
--   * merlinJumpCodeActions.enable  - merlin-style jump targets as code
--                                     actions (redundant here: \j covers it)
--   * shortenMerlinDiagnostics.enable - compress long type-error messages
-- (extendedHover and codelens.forNestedBindings graduated from this list
-- to enabled, 2026-08-21 at the user's request - see the settings table.)
--
-- FILETYPE REALITY CHECK (verified against this config, 2026-08): Neovim
-- detects .ml/.mli/.mll/.mly all as plain "ocaml" and dune/dune-project as
-- "dune", so in practice only those two entries of the `filetypes` list ever
-- match. The compound names (ocaml.menhir / ocaml.interface / ocaml.ocamllex)
-- and "reason" are kept anyway: they are harmless, they mirror upstream
-- nvim-lspconfig, and a future syntax plugin (e.g. vim-ocaml) could start
-- assigning them.
-- ============================================================================

local helpers = require("jwn.lsp.helpers")

local M = {}

-- ----------------------------------------------------------------------------
-- Codelens display. For OCaml the lenses are inferred type signatures
-- above top-level definitions (e.g. `val add : int -> int -> int`) --
-- informational only, nothing to "run", so no keymap: just the per-buffer
-- opt-in via helpers.enable_codelens in on_attach below. The capability-
-- framework mechanics and timing live with that helper in lsp/helpers.lua
-- (it moved there 2026-08-14 when elp.lua became its second caller).
--
-- History (2026-08, same-day correction): the first version of this
-- wiring hand-rolled BufEnter / InsertLeave / BufWritePost autocmds
-- around vim.lsp.codelens.refresh({ bufnr }) - the pre-0.12 pattern,
-- deprecated on 0.12 and superseded by the framework's own
-- change-driven re-requests.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Binary resolution: prefer the project-local opam switch (2026-08-16,
-- user request).
--
-- `opam switch create .` gives a project its own switch in _opam/, with
-- its own compiler AND its own ocamllsp. Using that ocamllsp is not
-- just a nicety: the server must read cmt/cmi artifacts produced by the
-- switch's compiler, and a version mismatch against the global switch's
-- ocamllsp degrades or breaks analysis. So: walk UPWARD from the LSP
-- root and spawn the nearest _opam's bin/ocamllsp if it is executable
-- (the root itself is checked first); otherwise fall back to `ocamllsp`
-- from $PATH (the global default switch). The upward walk mirrors
-- opam's own directory-based resolution rule (`opam env` semantics):
-- the switch may sit ABOVE the dune project root, as in a multi-project
-- repo whose subfolders each carry a dune-project while one shared
-- _opam lives at the repo top (e.g. ~/proj/ocamlpractice).
--
-- History note (2026-08-16, same-day correction): the first version
-- probed exactly <root>/_opam/bin/ocamllsp. In multi-project repos the
-- root marker resolves to the subfolder, the shared _opam one level up
-- was never seen, and the config always fell through to the PATH
-- fallback - silently, the binary just wasn't the switch's.
--
-- Accepted limitation: the OPAMSWITCH environment variable (which real
-- opam lets override directory-based selection) is not consulted.
--
-- The local branch also prepends the found _opam/bin to the server's
-- PATH, so subprocesses ocamllsp spawns (dune, ocamlformat) resolve
-- from the same switch instead of half-local half-global.
--
-- Mechanics: `cmd` as a FUNCTION is invoked per client start with
-- (dispatchers, resolved_config) - runtime lsp/client.lua calls
-- config.cmd(dispatchers, config) - so config.root_dir (resolved from
-- root_markers below) picks the binary per project. vim.lsp.rpc.start
-- is the same spawn path a list-valued cmd takes internally.
-- ----------------------------------------------------------------------------
local function start_ocamllsp(dispatchers, config)
    local bin = "ocamllsp"
    local env
    local root = config.root_dir
    if root then
        -- Walk upward like opam itself does: the switch may sit above the
        -- dune project root (multi-project repo sharing one _opam at its
        -- top, e.g. ~/proj/ocamlpractice), or in the root itself (single
        -- project). Nearest _opam wins, matching `opam env` semantics.
        local hit = vim.fs.find("_opam", { upward = true, path = root, type = "directory" })[1]
        if hit then
            local local_bin = hit .. "/bin/ocamllsp"
            if vim.fn.executable(local_bin) == 1 then
                bin = local_bin
                env = { PATH = hit .. "/bin:" .. (vim.env.PATH or "") }
            end
        end
    end
    return vim.lsp.rpc.start({ bin }, dispatchers, {
        cwd = root,
        env = env,
    })
end

function M.setup()
    helpers.define_server("ocamllsp", {
        cmd = start_ocamllsp,
        filetypes = {
            "ocaml",
            "ocaml.menhir",
            "ocaml.interface",
            "ocaml.ocamllex",
            "reason",
            "dune",
        },
        -- Tiered (2026-08-16, user request): the inner list is tier 1,
        -- searched over the ENTIRE ancestry first; ".git" is tier 2, a
        -- true fallback consulted only when no dune/opam marker exists
        -- anywhere up-tree. With the old flat list all four markers
        -- ranked equally and only distance decided, so a vendored git
        -- checkout INSIDE a dune project (its .git nearer than the
        -- parent's dune-project) would win the root. Within a tier,
        -- nearest still wins, so multi-project repos keep rooting at
        -- each subfolder's own dune-project.
        root_markers = {
            { "dune-project", "dune-workspace", "*.opam" },
            ".git",
        },
        settings = {
            -- Type-signature lenses above definitions. `enable` makes the
            -- SERVER compute them; enable_codelens (chained in on_attach
            -- below) makes Neovim SHOW them. forNestedBindings (on since
            -- 2026-08-21, user request) extends the lenses from top-level
            -- lets to INNER lets too, so local helper functions carry
            -- their val-style signature as well. Known trade-off: in
            -- deeply nested code this stacks a lens above every little
            -- binding - if it ever reads as noise, this is the flag.
            codelens = {
                enable = true,
                forNestedBindings = true,
            },
            -- Richer K hover (2026-08-21, user request): documentation
            -- and type together in one popup, instead of the type-only
            -- standard hover.
            extendedHover = {
                enable = true,
            },
            -- All three hint kinds on -- the OCaml equivalent of the
            -- full-inlay-hints preference used for Rust. Each is an
            -- independent boolean; there is no umbrella `enable` key.
            inlayHints = {
                -- `let x = ...` -> show the inferred type of x.
                hintLetBindings = true,
                -- Variables bound in patterns (match arms, tuple
                -- destructuring) -> show their inferred types.
                hintPatternVariables = true,
                -- Function parameters in definitions -> show their
                -- inferred types.
                hintFunctionParams = true,
            },
        },
        on_attach = function(client, bufnr)
            -- Everything every server gets (keymaps, diagnostics keymap,
            -- client-side inlay hint enable, semantic tokens) ...
            helpers.standard_on_attach(client, bufnr)
            -- ... plus the codelens rendering opt-in (see comment above).
            helpers.enable_codelens(client, bufnr)
        end,
    })
end

return M
