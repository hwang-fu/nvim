-- ============================================================================
-- :checkhealth jwn - the fresh-machine report (2026-08-19).
--
-- The consolidated answer to "what is this machine still missing?".
-- Startup deliberately stays quiet (only ripgrep and missing formatters
-- warn there - see lsp/format.lua); everything else reports HERE, on
-- demand, where long output is welcome and costs nothing at startup.
--
-- Severity policy, agreed 2026-08-19:
--   * error - the editor's own dependencies whose absence breaks daily
--             keys confusingly (ripgrep).
--   * warn  - editor conveniences and build prerequisites (lazygit,
--             cargo/make/cc, the python provider, formatters).
--   * info  - language servers and linters. "Toolchain not installed
--             yet" is a legitimate state by this config's philosophy
--             (servers come from rustup / opam / ghcup per machine), so
--             a machine used for two languages should not drown in
--             warnings about the other eighteen.
--
-- Wired by Neovim's convention: this file being lua/jwn/health.lua
-- makes `:checkhealth jwn` call M.check(). No registration needed.
-- ============================================================================

local M = {}

local health = vim.health

local function has(bin)
    return vim.fn.executable(bin) == 1
end

-- ok/warn/info line for one binary, with an installation hint on miss.
local function probe(bin, level, hint)
    if has(bin) then
        health.ok(bin)
    else
        health[level](bin .. " not found" .. (hint and (" - " .. hint) or ""))
    end
end

function M.check()
    -- ------------------------------------------------------------------
    health.start("Editor runtime")
    probe("rg", "error", "every content search (<leader>fg, Ctrl-RightClick, grep pickers) shells out to ripgrep")
    probe("lazygit", "warn", "<leader>gg opens it; the git float is dead without it")

    -- ------------------------------------------------------------------
    health.start("Build prerequisites (plugin installs and parser compiles)")
    probe("git", "warn", "lazy.nvim installs and updates plugins with it")
    probe("cargo", "warn", "parinfer-rust compiles itself with cargo on install")
    probe("make", "warn", "telescope's fzf sorter builds with make")
    if has("cc") or has("gcc") or has("clang") then
        health.ok("C compiler (cc / gcc / clang)")
    else
        health.warn("no C compiler found - treesitter parsers and telescope's sorter cannot compile")
    end

    -- ------------------------------------------------------------------
    health.start("Python provider (slimv / Common Lisp only)")
    if not has("python3") then
        health.warn("python3 not found - slimv (Common Lisp) needs the python provider; everything else runs fine")
    else
        vim.fn.system({ "python3", "-c", "import pynvim" })
        if vim.v.shell_error == 0 then
            health.ok("python3 with pynvim")
        else
            health.warn("pynvim not importable - `pip install --user pynvim` for slimv; everything else runs fine")
        end
    end

    -- ------------------------------------------------------------------
    health.start("Format-on-save binaries")
    for _, f in ipairs(require("jwn.lsp.format").FORMATTER_BINARIES) do
        probe(f.cmd, "warn", f.label .. " will not format on save")
    end

    -- ------------------------------------------------------------------
    health.start("Linters (optional; they skip silently when absent)")
    for _, l in ipairs({
        { cmd = "shellcheck", label = "sh / bash" },
        { cmd = "hadolint", label = "Dockerfile" },
        { cmd = "checkmake", label = "Makefile" },
        { cmd = "yamllint", label = "YAML" },
    }) do
        probe(l.cmd, "info", "no extra " .. l.label .. " diagnostics")
    end

    -- ------------------------------------------------------------------
    health.start("Language servers (each comes from its language's toolchain)")
    for _, name in ipairs(require("jwn.lsp").SERVERS) do
        local cfg = vim.lsp.config[name]
        local cmd = cfg and cfg.cmd
        if type(cmd) == "table" and cmd[1] then
            probe(cmd[1], "info", "the " .. name .. " server; install via its toolchain")
        elseif type(cmd) == "function" then
            -- Dynamic resolution (ocamllsp picks a per-project _opam
            -- binary); the PATH fallback is what a fresh machine needs.
            probe(name, "info", "PATH fallback for the dynamically resolved " .. name .. " (project _opam switches override it)")
        else
            health.info(name .. ": no cmd resolvable (server config not loaded?)")
        end
    end

    -- Plugin-owned servers, not in the SERVERS table (see lsp/init.lua).
    probe("rust-analyzer", "info", "Rust; comes from `rustup component add rust-analyzer`")
    probe("haskell-language-server-wrapper", "info", "Haskell; comes from ghcup")
    -- ElixirLS: lsp/servers/elixirls.lua PINS cmd to a manual install,
    -- which disables elixir-tools' own auto-download - so on a fresh
    -- machine this is a real setup step, and the report says so.
    local elixirls_cmd = vim.fn.expand("~/.local/share/elixir-ls/language_server.sh")
    if vim.fn.executable(elixirls_cmd) == 1 then
        health.ok("ElixirLS (" .. elixirls_cmd .. ")")
    else
        health.info(
            "ElixirLS not found at " .. elixirls_cmd
                .. " - install it there, or drop the cmd pin in lsp/servers/elixirls.lua so elixir-tools auto-downloads it"
        )
    end
end

return M
