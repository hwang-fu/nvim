-- ============================================================================
-- nvim-dap: debugging via the Debug Adapter Protocol.
--
-- DAP is to debuggers what LSP is to language servers: a JSON protocol that
-- lets one client (nvim-dap) drive many different debug adapters through a
-- common interface. Unlike LSP, DAP does NOT attach on file open - nvim-dap
-- stays completely idle until a debug session is explicitly started. That is
-- why the whole stack is lazy-loaded (see the nvim-dap spec in plugins/spec/dap.lua)
-- and costs nothing at startup or when opening a buffer.
--
-- This module is invoked from the nvim-dap plugin spec's `config` hook in
-- plugins/spec/dap.lua, NOT from the top-level module list in init.lua.
-- That is deliberate and mirrors how rust_analyzer.lua is wired from
-- rustaceanvim's `init` hook: configuring DAP from init.lua would force the
-- stack to load at startup and defeat the lazy-loading. `config` runs the
-- first time nvim-dap actually loads (first debug action), at which point
-- every dependency below is already on the runtimepath.
--
-- Adapter ownership (important):
--   * The Rust debug adapter is owned by rustaceanvim, NOT by this module.
--     rustaceanvim auto-detects the codelldb binary that mason installs and
--     builds the adapter + launch configurations itself from cargo metadata.
--     You start a Rust session with `:RustLsp debuggables` / `:RustLsp debug`
--     (mapped to <F8> / <F5> below), not with a hand-written dap.configurations
--     table.
--   * mason-nvim-dap is used here ONLY to install the codelldb binary
--     (ensure_installed). Its automatic adapter handlers are left OFF
--     (handlers = {}) so it does not register a second, competing codelldb
--     adapter behind rustaceanvim's back.
--   * The OCaml adapter (ocamlearlybird) IS owned by this module - see
--     install_ocaml() below. Its binary comes from opam (`opam install
--     earlybird`), NOT from mason, matching how this config sources every
--     language tool from its own toolchain (see the mason spec's note in
--     plugins/spec/mason.lua).
--
-- What this module owns:
--   * Breakpoint / stopped-line signs   - ASCII glyphs (see ASCII-only note).
--   * dap-ui                            - the scopes / stack / watches /
--                                         breakpoints / REPL panel, auto-opened
--                                         and closed via dap event listeners.
--   * nvim-dap-virtual-text             - inline variable values during a run.
--   * mason-nvim-dap                    - ensure_installed = { "codelldb" }.
--   * F-key keymaps                     - VS Code-style: F5 / F9 / F10 / F11.
--
-- ASCII-only note: every glyph below (signs, dap-ui icons) is plain ASCII.
-- dap-ui and dap default to nerd-font / Unicode glyphs; those are overridden
-- here because this config is ASCII-only by rule. The icons read a little
-- terse as a result (e.g. "o>" for step-over) - that is the intended trade.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- Breakpoint and stopped-line signs.
--
-- nvim-dap places signs in the sign column for each breakpoint and for the
-- line the debugger is currently stopped on. The default `text` values are
-- Unicode dots / arrows, replaced here with ASCII.
--
-- `texthl` reuses the existing Diagnostic* highlight groups so the signs pick
-- up the colorscheme's red / yellow / blue without this module having to
-- define and maintain its own highlight groups. DapStopped also sets `linehl`
-- to highlight the whole current line and `numhl` to tint the line number.
-- ----------------------------------------------------------------------------
local function install_signs()
    vim.fn.sign_define("DapBreakpoint", {
        text = "B",
        texthl = "DiagnosticError",
    })
    vim.fn.sign_define("DapBreakpointCondition", {
        text = "C",
        texthl = "DiagnosticError",
    })
    vim.fn.sign_define("DapLogPoint", {
        text = "L",
        texthl = "DiagnosticInfo",
    })
    vim.fn.sign_define("DapBreakpointRejected", {
        text = "R",
        texthl = "DiagnosticHint",
    })
    vim.fn.sign_define("DapStopped", {
        text = ">",
        texthl = "DiagnosticWarn",
        linehl = "Visual",
        numhl = "DiagnosticWarn",
    })
end

-- ----------------------------------------------------------------------------
-- dap-ui: the debugging panel.
--
-- Provides the Scopes (locals/args), Watches, Call Stack, Breakpoints, and
-- REPL views. Auto-opens on session start and closes on exit via the dap
-- listeners installed in install_listeners() below.
--
-- icons / controls.icons are ASCII overrides of dap-ui's nerd-font defaults
-- (ASCII-only rule). `expanded` / `collapsed` toggle tree rows; `controls` is
-- the clickable transport bar (play / pause / step / stop) drawn in the
-- panel header.
-- ----------------------------------------------------------------------------
local function install_dapui()
    require("dapui").setup({
        icons = {
            expanded = "v",
            collapsed = ">",
            current_frame = "*",
        },
        controls = {
            icons = {
                pause = "||",
                play = ">",
                step_into = "i>",
                step_over = "o>",
                step_out = "<o",
                step_back = "<<",
                run_last = "..",
                terminate = "[]",
                disconnect = "x",
            },
        },
    })
end

-- ----------------------------------------------------------------------------
-- nvim-dap-virtual-text: inline variable values.
--
-- Renders the current value of each in-scope variable as virtual text at the
-- end of its line while a session is paused (e.g. `x = 42`). Defaults are
-- sensible; setup() with an empty table just enables it.
-- ----------------------------------------------------------------------------
local function install_virtual_text()
    require("nvim-dap-virtual-text").setup({})
end

-- ----------------------------------------------------------------------------
-- mason-nvim-dap: install the codelldb adapter binary.
--
-- ensure_installed downloads codelldb into mason's package directory on first
-- load if it is not already present, so a fresh clone of this config
-- self-provisions the adapter. To pre-warm it instead of waiting for the
-- first debug session, run `:MasonInstall codelldb` once.
--
--   * automatic_installation = false - do NOT auto-install adapters just
--     because a dap configuration references them; ensure_installed is the
--     only install trigger.
--   * handlers = {} - no automatic adapter setup. rustaceanvim owns the Rust
--     adapter (it auto-detects this codelldb binary), so registering a second
--     codelldb adapter here would be redundant and confusing. When a future
--     language is added (e.g. Go / delve), give it a handler here.
--
-- require("mason").setup() is NOT called here: mason loads as a dependency
-- before this runs and its own spec (opts = {}) already ran setup.
-- ----------------------------------------------------------------------------
local function install_mason_dap()
    require("mason-nvim-dap").setup({
        ensure_installed = { "codelldb" },
        automatic_installation = false,
        handlers = {},
    })
end

-- ----------------------------------------------------------------------------
-- OCaml: ocamlearlybird adapter + launch configuration.
--
-- earlybird (the opam package; the binary is `ocamlearlybird`) speaks DAP
-- for OCaml's BYTECODE runtime only - it drives the same machinery as
-- ocamldebug, which native (.exe) builds do not carry. Practical workflow:
--
--   1. Make dune produce bytecode: add `(modes byte exe)` to the
--      executable stanza (or build the target as `./prog.bc` explicitly).
--      dune passes -g by default, so no extra flags are needed.
--   2. `dune build`
--   3. <F9> a breakpoint, then <F5> -> the config below asks which .bc to
--      run (auto-picked when the project has exactly one).
--
-- The `program` function resolves at session START, not at setup: it globs
-- _build/ under the dune root for .bc files - one match runs directly,
-- several offer a numbered choice, none falls back to a path prompt.
-- inputlist / input are used (not vim.ui.select) because dap consumes the
-- function's RETURN VALUE synchronously; dap.ABORT cancels the session
-- cleanly when the choice is dismissed.
--
-- F5 needs no OCaml-specific routing (unlike Rust): once
-- dap.configurations.ocaml exists, plain dap.continue() finds it - the
-- generic case 3 in the F5 comment below.
-- ----------------------------------------------------------------------------
local function install_ocaml()
    local dap = require("dap")

    dap.adapters.ocamlearlybird = {
        type = "executable",
        command = "ocamlearlybird",
        args = { "debug" },
    }

    local function pick_bytecode()
        local root = vim.fs.root(0, { "dune-project", "dune-workspace" })
            or vim.fn.getcwd()
        local bcs = vim.fn.glob(root .. "/_build/**/*.bc", false, true)

        if #bcs == 1 then
            return bcs[1]
        end

        if #bcs > 1 then
            local choices = { "Select bytecode program:" }
            for i, path in ipairs(bcs) do
                table.insert(
                    choices,
                    string.format("%d: %s", i, vim.fn.fnamemodify(path, ":."))
                )
            end
            local n = vim.fn.inputlist(choices)
            if n >= 1 and n <= #bcs then
                return bcs[n]
            end
            return dap.ABORT
        end

        -- No .bc anywhere under _build: most likely the executable stanza
        -- lacks `(modes byte exe)`. Leave a manual path escape hatch.
        local path = vim.fn.input(
            "No .bc found under _build (missing `(modes byte exe)`?). Path: ",
            root .. "/_build/default/",
            "file"
        )
        if path == "" then
            return dap.ABORT
        end
        return path
    end

    dap.configurations.ocaml = {
        {
            name = "OCaml: launch bytecode (earlybird)",
            type = "ocamlearlybird",
            request = "launch",
            program = pick_bytecode,
        },
    }
end

-- ----------------------------------------------------------------------------
-- Auto-open / auto-close the dap-ui panel.
--
-- Hook dap's event stream so the panel appears when a session initializes and
-- disappears when it terminates or exits. The string key ("dapui_config") is
-- just a listener id; reusing the same id keeps re-running setup() from
-- stacking duplicate listeners.
-- ----------------------------------------------------------------------------
local function install_listeners()
    local dap = require("dap")
    local dapui = require("dapui")

    dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
    end
end

-- ----------------------------------------------------------------------------
-- Keymaps (F-keys, VS Code muscle memory).
--
-- These are the real mappings. The matching bare key strings in the nvim-dap
-- spec's `keys` field in plugins/spec/dap.lua exist only to LAZY-LOAD the stack: the
-- first press loads nvim-dap (running config -> this setup, which installs the
-- mappings below), then lazy.nvim re-feeds the keystroke so the now-live
-- mapping fires. Keeping the trigger list in plugins/spec/dap.lua and the
-- behavior here preserves the "spec = what/how-loaded, modules = behavior"
-- split.
--
-- F-key map:
--   F5        continue / start (Rust-aware - see below)
--   S-F5      terminate the session
--   F6        pause a running program
--   F7        toggle the dap-ui panel
--   F8        :RustLsp debuggables - pick and start a Rust cargo target
--   F9        toggle breakpoint
--   S-F9      set a conditional breakpoint (prompts for the condition)
--   F10       step over
--   F11       step into
--   S-F11     step out
--
-- F5 is Rust-aware on purpose. Plain dap.continue() only works once a debug
-- configuration exists for the buffer's filetype, but rustaceanvim does not
-- populate dap.configurations.rust until one of its own debug commands runs.
-- So F5 routes the three cases:
--   1. a session is already active   -> dap.continue() resumes it
--   2. no session, filetype is rust  -> :RustLsp debuggables starts one
--   3. no session, any other type    -> dap.continue() (launch.json / configs)
-- This keeps F5 as the single "start or continue" key everywhere, the way it
-- behaves in VS Code, while still going through rustaceanvim to start on Rust.
-- ----------------------------------------------------------------------------
local function install_keymaps()
    local map = vim.keymap.set

    map("n", "<F5>", function()
        local dap = require("dap")
        if dap.session() then
            dap.continue()
        elseif vim.bo.filetype == "rust" then
            vim.cmd.RustLsp({ "debuggables" })
        else
            dap.continue()
        end
    end, { silent = true, desc = "DAP continue / start (Rust-aware)" })

    map("n", "<S-F5>", function()
        require("dap").terminate()
    end, { silent = true, desc = "DAP terminate session" })

    map("n", "<F6>", function()
        require("dap").pause()
    end, { silent = true, desc = "DAP pause" })

    map("n", "<F7>", function()
        require("dapui").toggle()
    end, { silent = true, desc = "DAP toggle UI panel" })

    map("n", "<F8>", function()
        vim.cmd.RustLsp({ "debuggables" })
    end, { silent = true, desc = "DAP pick Rust debuggable target" })

    map("n", "<F9>", function()
        require("dap").toggle_breakpoint()
    end, { silent = true, desc = "DAP toggle breakpoint" })

    map("n", "<S-F9>", function()
        local condition = vim.fn.input("Breakpoint condition: ")
        require("dap").set_breakpoint(condition)
    end, { silent = true, desc = "DAP conditional breakpoint" })

    map("n", "<F10>", function()
        require("dap").step_over()
    end, { silent = true, desc = "DAP step over" })

    map("n", "<F11>", function()
        require("dap").step_into()
    end, { silent = true, desc = "DAP step into" })

    map("n", "<S-F11>", function()
        require("dap").step_out()
    end, { silent = true, desc = "DAP step out" })
end

-- ----------------------------------------------------------------------------
-- Entry point. Order: dependencies that other steps rely on first (mason-dap
-- install, then dap-ui / virtual-text), then the listeners that reference
-- dap-ui, then signs and keymaps.
-- ----------------------------------------------------------------------------
function M.setup()
    install_mason_dap()
    install_ocaml()
    install_dapui()
    install_virtual_text()
    install_listeners()
    install_signs()
    install_keymaps()
end

return M
