-- ============================================================================
-- Format on save.
--
-- ONE BufWritePre autocmd does the work, over a FORMATTERS table keyed by
-- filetype (in setup_format_on_save, where the choice of key is explained).
-- An entry says how to format, in one of three ways:
--
--   (a) lsp = true   - vim.lsp.buf.format() synchronously, leaving the answer
--       to whatever gopls / jdtls / tsgo returns. Synchronous is intentional:
--       you want the formatted version to land on disk, not a stale buffer.
--
--   (b) cmd = {...}  - an external CLI, for tools the LSP does not expose
--       (fprettify, dune format-dune-file, ruff format, stylua, raco fmt,
--       verible-verilog-format, shfmt). The run_formatter() helper below
--       pipes the buffer through stdin / stdout and replaces the contents
--       while preserving the cursor.
--
--   (c) fn = f       - a handler with a condition of its own (Elixir needs a
--       Mix project; nginx needs the buffer's real path).
--
-- Not every language formats on save. Rust, OCaml, Haskell, Clojure and C#
-- are deliberately off, with a manual command each (:RustFmt, :OCamlFmt,
-- :HaskellFmt, :ClojureFmt, :CSharpFmt, all in after/ftplugin/) so a save
-- never rewrites the buffer under you.
--
-- check_formatter_binaries() also lives in this module. run_formatter() is
-- silent on failure by design (a non-zero exit is treated as "leave the
-- buffer alone"), which means a *missing* external binary is equally silent:
-- every save in that language becomes a no-op with no warning. The check runs
-- once at VimEnter and reports any external CLI that is not on $PATH on this
-- machine. LSP-driven formatters are NOT checked here -- LSP failures surface
-- through the LSP layer already.
--
-- Public API:
--   require("jwa.lsp.format").setup()
--     Registers both the autocmds and the deferred binary-presence warning.
--     Called once from lua/jwa/lsp/init.lua.
--   require("jwa.lsp.format").format_ocaml_buffer()
--     Formats the current OCaml buffer, picking the LSP or the CLI path the
--     same way the old save-time handlers did. Called by :OCamlFmt.
--   require("jwa.lsp.format").format_haskell_buffer()
--     Formats the current Haskell buffer through HLS. Called by :HaskellFmt.
--   require("jwa.lsp.format").format_clojure_buffer()
--     Formats the current Clojure buffer through clojure-lsp (cljfmt).
--     Called by :ClojureFmt.
--   require("jwa.lsp.format").format_csharp_buffer()
--     Formats the current C# or Razor buffer through Roslyn, sorting using
--     directives at the same time. Called by :CSharpFmt.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- Global format-on-save switch (2026-08-28, user request). Default ON:
-- formatting on save is the standing behavior for every covered
-- filetype; the :FormatOnSave / :FormatNotOnSave commands (defined at
-- the end of setup_format_on_save) flip this for the session - useful
-- in foreign codebases whose files should stay byte-identical. The save
-- handler checks it once, before it looks anything up, so it covers every
-- entry in the table at once.
-- ----------------------------------------------------------------------------
local format_on_save_enabled = true

-- ----------------------------------------------------------------------------
-- Pipe the current buffer through an external formatter and replace the
-- contents in-place. Used by every `cmd` row of the FORMATTERS table below,
-- and directly by on-demand entry points that must run whatever the
-- format-on-save switch currently says.
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
-- ----------------------------------------------------------------------------
local function run_formatter(cmd)
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

-- ----------------------------------------------------------------------------
-- OCaml formatting, on demand only (2026-08-29, user request).
--
-- OCaml used to format on save through both sections below, one path per
-- buffer. It now runs only when asked, through the buffer-local :OCamlFmt in
-- after/ftplugin/ocaml.lua - but the two-path choice is unchanged, because
-- which formatter is correct depends on the project, not on when it runs:
--
--   * WITH a .ocamlformat up-tree, ocamllsp is asked to format, so the
--     project's own style always wins. That is what keeps collaborating on
--     repos with a different profile safe.
--   * WITHOUT one, ocamlformat is run directly with the Jane Street profile,
--     giving personal / scratch OCaml a style with no per-project file
--     (requested 2026-08-14). This arm cannot go through the LSP: ocamlformat
--     refuses to run outside a detected project, and ocamllsp inherits the
--     refusal.
--
-- Flags on the CLI arm:
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
--
-- Deliberately NOT gated on format_on_save_enabled: :FormatNotOnSave silences
-- saves, and an explicit :OCamlFmt is not a save.
-- ----------------------------------------------------------------------------
function M.format_ocaml_buffer()
    if vim.fs.root(0, ".ocamlformat") then
        vim.lsp.buf.format({
            async = false,
            name = "ocamllsp",
        })
        return
    end

    local kind = vim.fn.expand("%:e") == "mli" and "--intf" or "--impl"
    run_formatter({
        "ocamlformat",
        "--enable-outside-detected-project",
        "--profile=janestreet",
        kind,
        "-",
    })
end

-- ----------------------------------------------------------------------------
-- Haskell formatting, on demand only (2026-08-29, user request).
--
-- Same move as OCaml above, and simpler: Haskell only ever had the one path,
-- HLS running whichever formatter `formattingProvider` names (ormolu, set in
-- lsp/servers/hls.lua). There is no CLI arm to fall back to.
--
-- The client filter reads oddly and is correct: haskell-tools.nvim starts HLS
-- under its OWN name rather than "hls", so that string is what identifies the
-- client (haskell-tools/lsp/helpers.lua). Naming it keeps the format request
-- off any other server that happens to attach to the buffer.
--
-- The no-client branch exists because vim.lsp.buf.format() on a buffer with no
-- matching server is a SILENT no-op: you press the key, nothing happens, and
-- nothing says why. That trap already cost this config twice (Erlang under
-- ELP, Elixir outside a Mix project); an explicit command is exactly where it
-- would be most confusing.
--
-- Not gated on format_on_save_enabled, for the reason given on the OCaml
-- function above.
-- ----------------------------------------------------------------------------
local HASKELL_CLIENT = "haskell-tools.nvim"

function M.format_haskell_buffer()
    if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = 0, name = HASKELL_CLIENT })) then
        vim.notify(
            "HaskellFmt: no HLS client attached to this buffer, nothing to format",
            vim.log.levels.WARN
        )
        return
    end

    vim.lsp.buf.format({
        async = false,
        name = HASKELL_CLIENT,
    })
end

-- ----------------------------------------------------------------------------
-- Clojure formatting, on demand only (2026-09-06, user request).
--
-- Fourth language off the save path, after Rust, OCaml and Haskell, and the
-- same single-path shape as Haskell: clojure-lsp runs cljfmt, and there is no
-- CLI arm behind it.
--
-- Covers .clj, .cljs, .cljc AND .edn, because Neovim gives all four the
-- `clojure` filetype (.edn through a detect function that answers "clojure"
-- unless the file is an EDIF netlist). Leaving .edn on save while .clj came
-- off would be the odd split, not the tidy one - same filetype, same
-- formatter, same key.
--
-- Worth knowing about what changed here: unlike ormolu or ocamlformat, cljfmt
-- only ever touched whitespace, so formatting on save was never going to
-- rewrite the shape of your code. It comes off the save path for consistency
-- with its three siblings, not because it was doing damage.
--
-- The no-client warning and the absence of a format_on_save_enabled gate are
-- both there for the reasons given on the two functions above.
-- ----------------------------------------------------------------------------
local CLOJURE_CLIENT = "clojure_lsp"

function M.format_clojure_buffer()
    if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = 0, name = CLOJURE_CLIENT })) then
        vim.notify(
            "ClojureFmt: no clojure-lsp client attached to this buffer, nothing to format",
            vim.log.levels.WARN
        )
        return
    end

    vim.lsp.buf.format({
        async = false,
        name = CLOJURE_CLIENT,
    })
end

-- ----------------------------------------------------------------------------
-- C# / Razor formatting, on demand (2026-09-08, user request).
--
-- Joins Rust, OCaml, Haskell and Clojure on the manual path - though unlike
-- those four it never had a save-time handler to remove: C# arrived after the
-- on-demand pattern was already the house style.
--
-- The Roslyn server does the formatting, and its settings in
-- lsp/servers/roslyn.lua also turn on dotnet_organize_imports_on_format, so
-- this sorts using directives at the same time.
--
-- Same no-client warning as the two above, and it earns its keep here more
-- than anywhere else: Roslyn will not attach until it has resolved a solution
-- or project, so a stray .cs file outside any project genuinely has no server
-- and would otherwise fail in silence.
-- ----------------------------------------------------------------------------
local CSHARP_CLIENT = "roslyn"

function M.format_csharp_buffer()
    if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = 0, name = CSHARP_CLIENT })) then
        vim.notify(
            "CSharpFmt: no Roslyn client attached to this buffer, nothing to format",
            vim.log.levels.WARN
        )
        return
    end

    vim.lsp.buf.format({
        async = false,
        name = CSHARP_CLIENT,
    })
end

-- ============================================================================
-- 1. Format on save
-- ============================================================================

local function setup_format_on_save()
    -- The save handler belongs to a named group. The `clear = true` flag
    -- wipes any previously-registered member before the new one is added, so
    -- re-running this function (e.g. via `:luafile` on this module, or any
    -- plugin-manager reload) replaces the existing handler rather than
    -- stacking a duplicate on top of it.
    local format_group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true })

    -- ------------------------------------------------------------------------
    -- The formatter table: filetype -> how to format it.
    --
    -- ONE BufWritePre autocmd reads this; there is no per-language autocmd.
    -- That is a deliberate change from ten near-identical handlers, made for
    -- two reasons.
    --
    -- Matching on FILETYPE rather than on a filename glob. Neovim has already
    -- decided what the file is - by extension where that settles it, by
    -- content or shebang where it does not - and asking it is strictly better
    -- than a second guess from the name. Globs were wrong about ".v" (Verilog,
    -- Rocq and V all claim it, and a Rocq proof went through a Verilog
    -- formatter for two days), and were only ever right about ".py" and
    -- ".bashrc" by accident of what happens to have an extension. The three
    -- handlers that already gated on filetype - shell, nginx, python - did so
    -- with a paragraph each explaining why; this makes that the rule instead
    -- of the exception.
    --
    -- A table rather than code. Coverage for :FormatNotOnSave is now "is this
    -- filetype a key", not an introspection pass over the autocmd group
    -- matching globs against the buffer's tail AND its full path. Adding a
    -- formatter is a row.
    --
    -- Each entry says how, exactly one way:
    --   lsp = true   ask the attached language server
    --   cmd = {...}  pipe the buffer through this command (stdin -> stdout)
    --   fn  = f      anything with a condition of its own
    --
    -- Languages absent from this table on purpose format on demand instead,
    -- through the :RustFmt / :OCamlFmt / :HaskellFmt / :ClojureFmt /
    -- :CSharpFmt commands in after/ftplugin/. The functions behind them are
    -- near the top of this file.
    -- ------------------------------------------------------------------------

    -- Elixir formats through the LSP like the entries above it, but only
    -- inside a Mix project: ElixirLS attaches nowhere else, so on a stray
    -- .ex script the plain LSP call was a silent no-op - the file saved
    -- unformatted with no hint why (the same trap Erlang fell into with ELP,
    -- verified 2026-08-16). This makes the situation explicit, warning ONCE
    -- PER BUFFER; warning on every save of a scratch script would nag.
    local function format_elixir(args)
        if vim.fs.root(args.buf, "mix.exs") then
            vim.lsp.buf.format({ async = false })
            return
        end
        if not vim.b[args.buf].jwa_no_mix_warned then
            vim.b[args.buf].jwa_no_mix_warned = true
            vim.notify(
                "Elixir: no Mix project up-tree; format-on-save skipped (ElixirLS needs mix.exs)",
                vim.log.levels.WARN
            )
        end
    end

    -- prettier wants the real path to pick up .prettierrc and to report
    -- errors against something recognisable, so this one is built per call.
    local function format_nginx()
        run_formatter({
            "prettier",
            "--plugin=prettier-plugin-nginx",
            "--parser=nginx",
            "--stdin-filepath",
            vim.api.nvim_buf_get_name(0),
        })
    end

    -- shfmt flags, chosen once and shared by sh and bash:
    --   -i 2  indent two spaces. Shell nests deeply (if/then/fi inside
    --         for/do/done inside case/esac); two keeps multi-level
    --         constructs inside an 80-column terminal, and matches the
    --         2-space lean applied to lisp / yaml / json / typescript by the
    --         LispIndent augroup in jwa/init.lua.
    --   -ci   indent the bodies of case arms. Without it they sit at the same
    --         column as `case`, which is the single most common complaint
    --         about shfmt's defaults.
    --   -bn   binary operators (&&, ||) start the next line rather than end
    --         the previous one. Long conditionals scan better and a single
    --         clause can be commented out.
    --   -sr   space after redirect operators: `> file`, not `>file`.
    --
    -- Deliberately NOT passed:
    --   -s    semantic rewrites (${var} -> $var and friends). Too invasive
    --         for a save-time formatter - it edits code you did not ask it
    --         to. `shfmt -s -d <file>` previews them on demand.
    --   -ln   forcing a dialect. Omitting it lets shfmt read the shebang,
    --         which is right for a gate that covers both sh and bash.
    --
    -- No "-": shfmt reads stdin when given no file argument, unlike most of
    -- the commands here.
    local SHFMT = { "shfmt", "-i", "2", "-ci", "-bn", "-sr" }

    local FORMATTERS = {
        -- --- Through the language server ---------------------------------
        go = { lsp = true },
        toml = { lsp = true },
        json = { lsp = true },
        jsonc = { lsp = true },
        yaml = { lsp = true },
        proto = { lsp = true },
        javascript = { lsp = true },
        javascriptreact = { lsp = true },
        typescript = { lsp = true },
        typescriptreact = { lsp = true },
        perl = { lsp = true },
        -- Java: the Eclipse formatter inside jdtls (2026-08-28).
        java = { lsp = true },

        elixir = { fn = format_elixir },
        heex = { fn = format_elixir },

        -- --- Through an external CLI --------------------------------------
        fortran = {
            cmd = {
                "fprettify",
                "--indent=2",
                "--whitespace=3",
                "--strict-indent",
                "--line-length=132",
            },
        },

        dune = { cmd = { "dune", "format-dune-file" } },

        nginx = { fn = format_nginx },

        -- Filetype, not "*.py", catches three things a glob would miss:
        -- shebang-only scripts in ~/bin with no extension, .pyi type stubs,
        -- and .pyw launchers.
        python = { cmd = { "ruff", "format", "-" } },

        lua = { cmd = { "stylua", "-" } },

        -- gersemi (2026-08-28), reading stdin with "-", in its own
        -- opinionated style. Deliberately a CLI formatter rather than
        -- cmake-language-server's - see lsp/servers/cmake_ls.lua.
        cmake = { cmd = { "gersemi", "-" } },

        -- `raco fmt` reads stdin when given NO argument; adding "-" would
        -- make it look for a file called "-".
        --
        -- Needs the `fmt` PACKAGE (`raco pkg install fmt`), which the binary
        -- check below cannot see - it probes for `raco` itself. A missing or
        -- version-orphaned package makes every .rkt save a silent no-op, and
        -- that exact failure went unnoticed from the check's introduction
        -- until 2026-08-14.
        racket = { cmd = { "raco", "fmt" } },

        -- ".v" is why this whole table is keyed on filetype. verible echoes
        -- its input, appends its diagnostic to STDOUT and exits 0, so feeding
        -- it a Rocq proof passed the exit-code guard and wrote error text
        -- into the buffer - one more line on every save, with nothing
        -- reported anywhere.
        verilog = { cmd = { "verible-verilog-format", "-" } },
        systemverilog = { cmd = { "verible-verilog-format", "-" } },

        -- Only sh and bash. shfmt parses POSIX sh, bash and mksh; it does
        -- NOT handle zsh-specific syntax like `=foo` glob qualifiers, and
        -- would silently mangle a zsh script. Note Neovim labels .bashrc as
        -- `sh`, not `bash`, unless vim.g.is_bash is set - harmless, because
        -- shfmt reads the dialect from the shebang and this key is only a
        -- coarse "is this shell" gate.
        sh = { cmd = SHFMT },
        bash = { cmd = SHFMT },

        -- erlfmt (WhatsApp's; "-" reads stdin), installed at
        -- ~/.local/bin/erlfmt via `rebar3 escriptize`. Here rather than on
        -- the LSP path because ELP advertises no formatting capability
        -- (verified 2026-08-14, see lsp/servers/elp.lua) and the old "*.erl"
        -- LSP entries silently did nothing. The filetype covers source,
        -- headers, and the two Erlang-term config shapes erlfmt officially
        -- formats - .app.src and rebar.config both resolve to `erlang`.
        erlang = { cmd = { "erlfmt", "-" } },
    }

    -- True when saving this buffer would reformat it. One lookup: the table
    -- IS the coverage list, so :FormatNotOnSave cannot drift out of step with
    -- what actually runs, and a formatter added later is accounted for by
    -- existing.
    local function buffer_has_format_on_save(buf)
        return FORMATTERS[vim.bo[buf].filetype] ~= nil
    end

    -- The one handler. The enable flag is checked before the lookup: when
    -- format-on-save is off there is nothing to decide.
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        pattern = "*",
        callback = function(args)
            if not format_on_save_enabled then
                return
            end

            local entry = FORMATTERS[vim.bo[args.buf].filetype]
            if not entry then
                return
            end

            if entry.lsp then
                vim.lsp.buf.format({ async = false })
            elseif entry.cmd then
                run_formatter(entry.cmd)
            else
                entry.fn(args)
            end
        end,
    })

    -- ------------------------------------------------------------------------
    -- :FormatOnSave / :FormatNotOnSave (2026-08-28, user request).
    --
    -- One GLOBAL switch (the module-local format_on_save_enabled flag at
    -- the top of this file), default ON. The messaging rule is the
    -- user's spec verbatim: flipping it from a buffer whose filetype has
    -- no format-on-save wiring stays SILENT (the flag still changes -
    -- it is global); flipping it from a covered buffer echoes a yellow
    -- WarningMsg line, kept in :messages.
    -- ------------------------------------------------------------------------
    local function set_format_on_save(on)
        format_on_save_enabled = on
        if buffer_has_format_on_save(0) then
            vim.api.nvim_echo({ {
                on and "Format-on-save enabled - this buffer formats again on :w"
                    or "Format-on-save disabled - this buffer now saves byte-identical",
                "WarningMsg",
            } }, true, {})
        end
    end

    vim.api.nvim_create_user_command("FormatOnSave", function()
        set_format_on_save(true)
    end, { desc = "Enable format-on-save (the default; global)" })
    vim.api.nvim_create_user_command("FormatNotOnSave", function()
        set_format_on_save(false)
    end, { desc = "Disable format-on-save globally for this session" })
end

-- ============================================================================
-- 2. Formatter binary presence check
--
-- The run_formatter() helper above is silent on failure by design: a
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
-- driven formatters (gopls, jsonls, tsgo, etc.) surface their own errors
-- through the LSP layer when the server fails to start, so duplicating
-- that visibility here would be noise.
-- ============================================================================

-- Each entry pairs the binary the autocmd shells out to with a short
-- human-readable label. Order matches the `cmd` rows of the FORMATTERS
-- table inside setup_format_on_save() so this list is easy to keep in sync
-- if a new formatter is added. MODULE-LEVEL (2026-08-19) because the
-- :checkhealth jwa report (lua/jwa/health.lua) reads the same
-- list - one list, two consumers, no drift.
M.FORMATTER_BINARIES = {
    { cmd = "fprettify", label = "Fortran" },
    { cmd = "dune", label = "dune build files" },
    { cmd = "prettier", label = "nginx (via prettier-plugin-nginx)" },
    { cmd = "ruff", label = "Python" },
    { cmd = "stylua", label = "Lua" },
    -- Binary-level probe only: cannot see whether the `fmt` package
    -- is installed for the CURRENT Racket version (see the comment
    -- on the `racket` row above).
    { cmd = "raco", label = "Racket" },
    { cmd = "verible-verilog-format", label = "Verilog / SystemVerilog" },
    { cmd = "shfmt", label = "shell (sh, bash)" },
    { cmd = "erlfmt", label = "Erlang (erl, hrl, app.src, rebar.config)" },
    -- Not a save-time formatter any more: :OCamlFmt reaches for this binary
    -- only in a project with no .ocamlformat of its own.
    { cmd = "ocamlformat", label = "OCaml (:OCamlFmt, when no .ocamlformat)" },
    { cmd = "gersemi", label = "CMake" },
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
    -- startup; the rest live in :checkhealth jwa): every content
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
