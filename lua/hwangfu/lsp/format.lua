-- ============================================================================
-- Format on save.
--
-- Two flavors of formatter live here:
--
--   (a) LSP-driven formatters    - handled by a single BufWritePre autocmd
--       below, which calls vim.lsp.buf.format() synchronously. Languages in
--       its `pattern` list rely on whatever rust-analyzer / gopls / pyright
--       (etc.) returns. Synchronous on save is intentional: you want the
--       formatted version to land on disk, not a stale buffer.
--
--   (b) External CLI formatters  - for tools the LSP does not expose
--       (fprettify, dune format-dune-file, ruff format, stylua, raco fmt,
--       verible-verilog-format, prettier-plugin-nginx, shfmt). The
--       format_with_cmd() helper below pipes the buffer through stdin / stdout
--       and replaces the contents while preserving the cursor. Each external
--       formatter gets its own autocmd so the pattern stays specific.
--
-- check_formatter_binaries() also lives in this module. The format_with_cmd
-- helper is silent on failure by design (a non-zero exit is treated as "leave
-- the buffer alone"), which means a *missing* external binary is equally
-- silent: every save in that language becomes a no-op with no warning. The
-- check runs once at VimEnter and reports any external CLI that is not on
-- $PATH on this machine. LSP-driven formatters are NOT checked here -- LSP
-- failures surface through the LSP layer already.
--
-- Public API:
--   require("hwangfu.lsp.format").setup()
--     Registers both the autocmds and the deferred binary-presence warning.
--     Called once from lua/hwangfu/lsp/init.lua.
-- ============================================================================

local M = {}

-- ============================================================================
-- 1. Format-on-save autocmds
-- ============================================================================

local function setup_format_on_save()
    -- All format-on-save autocmds below belong to a single named group. The
    -- `clear = true` flag wipes any previously-registered members before the
    -- new ones are added, so re-running this function (e.g. via `:luafile`
    -- on this module, or any plugin-manager reload) replaces the existing
    -- handlers rather than stacking duplicates on top of them.
    local format_group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true })

    -- ------------------------------------------------------------------------
    -- (a) LSP-driven formatters
    -- ------------------------------------------------------------------------
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = {
            "*.go",
            -- "*.rs", -- format-on-save disabled; uncomment to re-enable rustfmt
            "*.clj",
            "*.cljs",
            "*.cljc",
            "*.edn",
            "*.toml",
            "*.json",
            "*.jsonc",
            "*.yml",
            "*.yaml",
            "*.proto",
            "*.js",
            "*.jsx",
            "*.ts",
            "*.tsx",
            -- OCaml formats through the LSP ONLY in projects with a
            -- .ocamlformat file (ocamlformat refuses to run otherwise,
            -- and ocamllsp inherits the refusal). Projects WITHOUT one
            -- are covered by the Jane-Street-profile CLI fallback in
            -- section (b) below - exactly one path is effective per save.
            "*.ml",
            "*.mli",
            "*.pl",
            "*.pm",
            -- "*.ex" / "*.exs" / "*.heex" moved to their own autocmd
            -- below (2026-08-16): ElixirLS only attaches inside a Mix
            -- project, so the Elixir handler warns instead of silently
            -- no-oping when there is no mix.exs up-tree.
            -- "*.erl" / "*.hrl" were here until 2026-08-14. ELP does not
            -- implement textDocument/formatting (verified; see
            -- lsp/servers/elp.lua), so LSP format-on-save was a silent
            -- no-op for Erlang the whole time. Erlang now formats via
            -- the external erlfmt CLI in section (b) below.
            "*.hs",
            "*.lhs",
        },
        callback = function()
            vim.lsp.buf.format({
                async = false,
            })
        end,
    })

    -- ------------------------------------------------------------------------
    -- (a2) Elixir: LSP formatting, gated on being inside a Mix project.
    --
    -- ElixirLS (started by elixir-tools) only attaches when a mix.exs
    -- exists somewhere up-tree; on a stray .ex/.exs script NO server
    -- attaches, so the generic handler above would run vim.lsp.buf.format
    -- as a silent no-op - the file saves unformatted with no hint why
    -- (verified 2026-08-16; the same silent-no-op trap Erlang fell into
    -- with ELP). This handler makes the situation explicit: inside a Mix
    -- project it formats exactly like the generic handler; outside, it
    -- skips the call and warns ONCE PER BUFFER (a buffer-local flag -
    -- warning on every save of a scratch script would be nagging).
    -- ------------------------------------------------------------------------
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = { "*.ex", "*.exs", "*.heex" },
        callback = function(args)
            if vim.fs.root(args.buf, "mix.exs") then
                vim.lsp.buf.format({
                    async = false,
                })
                return
            end
            if not vim.b[args.buf].hwangfu_no_mix_warned then
                vim.b[args.buf].hwangfu_no_mix_warned = true
                vim.notify(
                    "Elixir: no Mix project up-tree; format-on-save skipped (ElixirLS needs mix.exs)",
                    vim.log.levels.WARN
                )
            end
        end,
    })

    -- ------------------------------------------------------------------------
    -- (b) External CLI formatters
    -- ------------------------------------------------------------------------

    -- Pipe the current buffer through an external formatter and replace the
    -- contents in-place. Used by every per-language autocmd below.
    --
    -- Behavior contract:
    --   * On success (exit 0): replace buffer contents with the formatter's
    --     stdout, then restore the cursor position (best-effort - the
    --     pcall guards against the cursor landing past the new EOF).
    --   * On failure (non-zero exit): leave the buffer untouched. We do NOT
    --     surface the error to the user; that's intentional, otherwise every
    --     transient parse error from the formatter would interrupt save.
    --   * The trailing-empty-line trim is for formatters that append a final
    --     newline (most do): split() would produce an extra "" entry, which
    --     nvim_buf_set_lines would render as a blank line at EOF.
    local function format_with_cmd(cmd)
        local cursor = vim.api.nvim_win_get_cursor(0)
        local bufnr = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local content = table.concat(lines, "\n")

        local formatted = vim.fn.system(cmd, content)

        if vim.v.shell_error == 0 then
            local new_lines = vim.split(formatted, "\n", {
                trimempty = false,
            })
            if new_lines[#new_lines] == "" then
                table.remove(new_lines)
            end
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
        end

        pcall(vim.api.nvim_win_set_cursor, 0, cursor)
    end

    -- Fortran: fprettify
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = {
            "*.f90",
            "*.f95",
            "*.f03",
            "*.f08",
            "*.F90",
            "*.F95",
            "*.F03",
            "*.F08",
        },
        callback = function()
            format_with_cmd({
                "fprettify",
                "--indent=2",
                "--whitespace=3",
                "--strict-indent",
                "--line-length=132",
            })
        end,
    })

    -- dune
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = { "dune", "dune-project" },
        callback = function()
            format_with_cmd({ "dune", "format-dune-file" })
        end,
    })

    -- nginx
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        callback = function()
            if vim.bo.filetype == "nginx" then
                format_with_cmd({
                    "prettier",
                    "--plugin=prettier-plugin-nginx",
                    "--parser=nginx",
                    "--stdin-filepath",
                    vim.api.nvim_buf_get_name(0),
                })
            end
        end,
    })

    -- Python: ruff
    --
    -- Dispatch by filetype rather than `*.py` glob so we also catch:
    --   * shebang-only scripts in ~/bin/ (e.g. `#!/usr/bin/env python3` with
    --     no extension) -- Neovim inspects the shebang during filetype
    --     detection and labels them `python`.
    --   * `.pyi` type stub files, which are syntactically Python and which
    --     ruff knows how to format, but which `*.py` would miss.
    --   * `.pyw` Windows Python launchers, on the off chance you ever cross
    --     paths with one.
    --
    -- Cost: this callback runs on every BufWritePre and the filetype check
    -- bails immediately for non-Python files. That's microseconds per save,
    -- which we're happily trading for never having to extend the pattern
    -- list again.
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        callback = function()
            if vim.bo.filetype ~= "python" then
                return
            end
            format_with_cmd({
                "ruff",
                "format",
                "-",
            })
        end,
    })

    -- Lua: stylua
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = {
            "*.lua",
        },
        callback = function()
            format_with_cmd({
                "stylua",
                "-",
            })
        end,
    })

    -- Racket: raco fmt (bare invocation reads stdin; do NOT add "-",
    -- raco fmt would treat it as a literal filename).
    --
    -- Requires the `fmt` PACKAGE (`raco pkg install fmt`), which the
    -- binary checker below cannot see - it only probes for `raco`
    -- itself, and a missing (or version-orphaned; see the note in
    -- lsp/servers/racket_langserver.lua) package makes every .rkt save
    -- a silent no-op. That exact failure went unnoticed from the
    -- checker's introduction until 2026-08-14.
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = {
            "*.rkt",
        },
        callback = function()
            format_with_cmd({
                "raco",
                "fmt",
            })
        end,
    })

    -- Verilog / SystemVerilog: verible-verilog-format
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = {
            "*.v",
            "*.sv",
            "*.svh",
            "*.vh",
        },
        callback = function()
            format_with_cmd({
                "verible-verilog-format",
                "-",
            })
        end,
    })

    -- Shell (bash / POSIX sh): shfmt
    --
    -- Dispatch:
    --   We intentionally do NOT use a `pattern` glob here, because shell-script
    --   files come in too many naming conventions for a glob list to be
    --   reliable: `*.sh` and `*.bash` cover the obvious cases, but dotfiles
    --   like `.bashrc` / `.bash_profile` / `.profile` don't have a suffix,
    --   shebang-only scripts (`~/bin/deploy` with `#!/usr/bin/env bash` and
    --   no extension) have no suffix at all, and there are quirky names like
    --   `PKGBUILD`. Maintaining that list is a losing game.
    --
    --   Instead we mirror the nginx entry above: pattern = "*" (all files),
    --   then gate inside the callback on `vim.bo.filetype`. Neovim's built-in
    --   filetype detection already understands shell dotfiles + shebang
    --   inspection, so we get correct coverage for free.
    --
    --   Why only `sh` and `bash` (not `zsh` / `fish` / `csh`):
    --     shfmt's parser supports POSIX sh, bash, and mksh -- it does NOT
    --     handle zsh-specific syntax like `=foo` glob qualifiers or `**`
    --     recursive globs in zsh's style. Running shfmt on a zsh script
    --     might silently mangle it, so we exclude that filetype.
    --
    --   Note: Neovim labels `.bashrc` as filetype `sh` (NOT `bash`) unless
    --   `vim.g.is_bash` is set. shfmt detects the actual dialect from the
    --   shebang line, so passing it a `bash`-flavored file with `ft=sh` is
    --   still correct -- the filetype check is just a coarse "is this shell"
    --   gate, not a dialect declaration.
    --
    -- Flag choices:
    --   -i 2  : indent with 2 spaces. Shell nests deeply (if/then/fi inside
    --           for/do/done inside case/esac), so 2-space keeps multi-level
    --           constructs readable inside 80-column terminals. Matches the
    --           2-space lean we already apply to lisp / yaml / json /
    --           typescript via the LispIndent augroup in hwangfu/init.lua.
    --   -ci   : indent the bodies of `case` arms. Without this, case bodies
    --           sit at the same column as the `case` keyword, which looks
    --           visually flat and is the single most common complaint about
    --           shfmt's defaults.
    --   -bn   : put binary operators (&&, ||) at the START of the next line
    --           rather than the end of the previous. Makes long conditionals
    --           easier to scan and easier to comment-out a single clause.
    --   -sr   : space after redirect operators -- `> file` instead of `>file`.
    --           Matches modern shell style guides (Google, ShellCheck-friendly).
    --
    -- Deliberately NOT enabled:
    --   -s    : semantic simplifications (e.g. ${var} -> $var when safe).
    --           Too invasive for a save-time formatter -- it edits code you
    --           didn't ask it to. Run `shfmt -s -d <file>` manually to preview
    --           those rewrites if you want them on a specific file.
    --   -ln <dialect> : force a shell dialect. Omitting it lets shfmt infer
    --           from the shebang -- correct behavior for a mixed sh/bash
    --           callback that fires on both POSIX and bash files.
    --
    -- Note: shfmt reads from stdin by default when no file argument is given,
    -- so unlike most of the formatters above we don't need to pass `-`.
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        callback = function()
            local ft = vim.bo.filetype
            if ft ~= "sh" and ft ~= "bash" then
                return
            end
            format_with_cmd({
                "shfmt",
                "-i",
                "2",
                "-ci",
                "-bn",
                "-sr",
            })
        end,
    })

    -- Erlang: erlfmt (WhatsApp's formatter; "-" reads stdin).
    --
    -- Lives here rather than in the LSP list because ELP advertises no
    -- formatting capability (verified 2026-08-14; see the note in
    -- lsp/servers/elp.lua) - the old "*.erl" LSP entries silently did
    -- nothing. erlfmt is installed at ~/.local/bin/erlfmt, built from
    -- the WhatsApp repo with `rebar3 escriptize`.
    --
    -- Besides source and headers, erlfmt officially formats the two
    -- Erlang-term config shapes, so both are included: "*.app.src"
    -- (application resource files) and "rebar.config".
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = {
            "*.erl",
            "*.hrl",
            "*.app.src",
            "rebar.config",
        },
        callback = function()
            format_with_cmd({
                "erlfmt",
                "-",
            })
        end,
    })

    -- OCaml: ocamlformat CLI fallback for projects WITHOUT a .ocamlformat.
    --
    -- In projects that HAVE .ocamlformat this autocmd deliberately does
    -- nothing and formatting rides ocamllsp (section (a) above): the
    -- project's own style always wins, which is what keeps collaborating
    -- on repos with a different profile safe. Only when no .ocamlformat
    -- exists anywhere up the tree does this fallback fire, giving
    -- personal / scratch OCaml the Jane Street style with no per-project
    -- file (requested 2026-08-14).
    --
    -- Flags:
    --   --enable-outside-detected-project
    --       lifts ocamlformat's refusal to run without a project config
    --       (a reproducibility default, sensible for repos, hostile to
    --       scratch files).
    --   --profile=janestreet
    --       the style. Kept HERE rather than in the XDG global config
    --       file (~/.config/ocamlformat, which the flag above would
    --       also consult) so the whole arrangement is visible inside
    --       the nvim config.
    --   --impl / --intf
    --       what the input is; stdin has no filename to infer from, so
    --       it is chosen from the buffer's extension.
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = { "*.ml", "*.mli" },
        callback = function()
            if vim.fs.root(0, ".ocamlformat") then
                return -- project defines its style; the LSP path owns this save
            end
            local kind = vim.fn.expand("%:e") == "mli" and "--intf" or "--impl"
            format_with_cmd({
                "ocamlformat",
                "--enable-outside-detected-project",
                "--profile=janestreet",
                kind,
                "-",
            })
        end,
    })
end

-- ============================================================================
-- 2. Formatter binary presence check
--
-- The format_with_cmd() helper above is silent on failure by design: a
-- non-zero exit from the formatter is interpreted as "leave the buffer
-- untouched," which correctly handles cases like shfmt rejecting a
-- half-typed script in the middle of an edit.
--
-- The unwanted side effect of that contract is that a *missing* binary is
-- equally silent. If ruff / shfmt / stylua / etc. is not on PATH on the
-- current machine, every save in that language is a silent no-op, and the
-- absence is only discoverable by noticing that formatting has stopped
-- happening - possibly long after the binary disappeared.
--
-- This helper enumerates the external CLI formatters wired up by
-- setup_format_on_save() and reports any that are not on PATH. It is
-- deferred to VimEnter so the warning lands after the startup phase
-- (LSP initialization, plugin loads) rather than being buried in that
-- output, and registered with `once = true` so it cannot fire twice even
-- if the module is reloaded mid-session.
--
-- The check intentionally covers ONLY the external CLI formatters. LSP-
-- driven formatters (gopls, jsonls, ts_ls, etc.) surface their own errors
-- through the LSP layer when the server fails to start, so duplicating
-- that visibility here would be noise.
-- ============================================================================

-- Each entry pairs the binary the autocmd shells out to with a short
-- human-readable label. Order matches the order of the formatter blocks
-- inside setup_format_on_save() so this list is easy to keep in sync if
-- a new formatter is added. MODULE-LEVEL (2026-08-19) because the
-- :checkhealth hwangfu report (lua/hwangfu/health.lua) reads the same
-- list - one list, two consumers, no drift.
M.FORMATTER_BINARIES = {
    { cmd = "fprettify", label = "Fortran" },
    { cmd = "dune", label = "dune build files" },
    { cmd = "prettier", label = "nginx (via prettier-plugin-nginx)" },
    { cmd = "ruff", label = "Python" },
    { cmd = "stylua", label = "Lua" },
    -- Binary-level probe only: cannot see whether the `fmt` package
    -- is installed for the CURRENT Racket version (see the comment
    -- on the Racket autocmd above).
    { cmd = "raco", label = "Racket" },
    { cmd = "verible-verilog-format", label = "Verilog / SystemVerilog" },
    { cmd = "shfmt", label = "shell (sh, bash)" },
    { cmd = "erlfmt", label = "Erlang (erl, hrl, app.src, rebar.config)" },
    { cmd = "ocamlformat", label = "OCaml (fallback when no .ocamlformat)" },
}

local function check_formatter_binaries()
    -- vim.fn.executable() returns 1 when the named command is on $PATH,
    -- 0 otherwise. This is the same probe Vim uses internally for things
    -- like `:!cmd` resolution; no subshell is spawned.
    local missing = {}
    for _, f in ipairs(M.FORMATTER_BINARIES) do
        if vim.fn.executable(f.cmd) == 0 then
            table.insert(missing, string.format("  - %s (%s)", f.cmd, f.label))
        end
    end

    -- ripgrep (2026-08-19, the one editor-runtime binary loud enough for
    -- startup; the rest live in :checkhealth hwangfu): every content
    -- search - <leader>fg / fG / fs, Ctrl-RightClick, telescope grep -
    -- shells out to rg, and its absence looks like "search finds
    -- nothing", not like an error. ERROR level, single line.
    local rg_missing = vim.fn.executable("rg") == 0

    if #missing == 0 and not rg_missing then
        return
    end

    vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
            if rg_missing then
                vim.notify(
                    "ripgrep (rg) not found: <leader>fg, Ctrl-RightClick, and every grep picker will fail",
                    vim.log.levels.ERROR
                )
            end
            if #missing > 0 then
                local message = "Format-on-save binaries not found on $PATH:\n"
                    .. table.concat(missing, "\n")
                    .. "\nFiles in these languages will not be auto-formatted on save."
                vim.notify(message, vim.log.levels.WARN)
            end
        end,
    })
end

-- ============================================================================
-- 3. Public API
-- ============================================================================

function M.setup()
    setup_format_on_save()
    check_formatter_binaries()
end

return M
