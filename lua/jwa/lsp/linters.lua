-- ============================================================================
-- External linters wired up as vim.diagnostic sources.
--
-- These are CLI tools (not LSPs) that produce diagnostics from stdout. The
-- shared shape is: register a private namespace, run the tool on save / read,
-- parse its output into vim.diagnostic items, publish under the namespace.
-- define_linter() captures all of that boilerplate, so each linter just
-- declares its name, command, file patterns, and a parse function.
--
-- The skip-if-binary-missing check inside define_linter means having a linter
-- not installed on this machine is silent - no errors, just no diagnostics.
-- Same goes for buffers with no on-disk filename (scratch buffers, etc.).
--
-- Linters currently wired up:
--   * shellcheck - sh / bash, JSON output with end positions
--   * hadolint   - Dockerfile / Containerfile, JSON output
--   * checkmake  - Makefile / *.mk, line-based "lnum:rule:msg" output
--   * yamllint   - YAML, parsable output "file:lnum:col: [level] msg (rule)".
--                  Complements yaml-language-server: yamlls does schema /
--                  syntax / structural validation; yamllint adds opinionated
--                  style + footgun checks (truthy values, key duplicates,
--                  indentation consistency, trailing whitespace, comments
--                  formatting). User config at ~/.config/yamllint/config
--                  picks which rules fire and at what severity.
--
-- Public API:
--   require("jwa.lsp.linters").setup()
--     Registers the autocmds. Called once from lua/jwa/lsp/init.lua.
-- ============================================================================

local M = {}

function M.setup()
    -- All linter autocmds below belong to a single named group, mirroring the
    -- FormatOnSave pattern. The `clear = true` flag wipes any previously-
    -- registered linter handlers before the new ones are added, so reloading
    -- this module mid-session replaces the autocmds rather than stacking
    -- additional copies that would run the linter multiple times per save.
    local linter_group = vim.api.nvim_create_augroup("Linters", { clear = true })

    -- Severity levels emitted by JSON-based linters (shellcheck, hadolint).
    local SEVERITY = {
        error = vim.diagnostic.severity.ERROR,
        warning = vim.diagnostic.severity.WARN,
        info = vim.diagnostic.severity.INFO,
        style = vim.diagnostic.severity.HINT,
    }

    -- Wires up an external linter as a vim.diagnostic source.
    --
    -- For each matching file, on BufWritePost / BufReadPost: spawn the linter
    -- with the file path appended, capture its stdout, hand it to `opts.parse`
    -- to convert into vim.diagnostic items, then publish those items under a
    -- private namespace so they don't collide with LSP diagnostics.
    --
    -- opts = {
    --   name      = "shellcheck",     -- namespace + display source name
    --   cmd       = { "shellcheck", "-f", "json" }, -- file path is appended
    --   patterns  = { "*.sh", "*.bash" },           -- autocmd patterns
    --   parse     = function(stdout_lines_array) return { diagnostic, ... } end,
    -- }
    --
    -- The cmd table is deep-copied per invocation because we mutate it with
    -- `table.insert(cmd, fname)`. Without the copy, a second file would get
    -- the first file's path appended too, producing wrong invocations.
    --
    -- The "binary not installed" check at the top means linters listed here
    -- don't have to be installed on every machine - missing tools just become
    -- silent no-ops. Same goes for buffers with no on-disk filename.
    local function define_linter(opts)
        local ns = vim.api.nvim_create_namespace(opts.name)
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
            group = linter_group,
            pattern = opts.patterns,
            callback = function()
                local bufnr = vim.api.nvim_get_current_buf()
                local fname = vim.api.nvim_buf_get_name(bufnr)

                if fname == "" or vim.fn.executable(opts.cmd[1]) ~= 1 then
                    return
                end

                local cmd = vim.deepcopy(opts.cmd)
                table.insert(cmd, fname)

                vim.fn.jobstart(cmd, {
                    stdout_buffered = true,
                    on_stdout = function(_, data)
                        if not data or #data == 0 or (data[1] == "" and #data == 1) then
                            vim.diagnostic.set(ns, bufnr, {})
                            return
                        end
                        vim.diagnostic.set(ns, bufnr, opts.parse(data) or {})
                    end,
                })
            end,
        })
    end

    -- ------------------------------------------------------------------------
    -- ShellCheck (JSON output, includes end_line / end_column)
    -- ------------------------------------------------------------------------
    define_linter({
        name = "shellcheck",
        cmd = {
            "shellcheck",
            "-f",
            "json",
        },
        patterns = { "*.sh", "*.bash" },
        parse = function(data)
            local ok, results = pcall(vim.json.decode, table.concat(data, "\n"))
            if not ok or not results then
                return {}
            end
            local diagnostics = {}
            for _, item in ipairs(results) do
                table.insert(diagnostics, {
                    lnum = item.line - 1,
                    col = item.column - 1,
                    end_lnum = item.endLine and (item.endLine - 1) or nil,
                    end_col = item.endColumn and (item.endColumn - 1) or nil,
                    severity = SEVERITY[item.level] or vim.diagnostic.severity.HINT,
                    message = item.message,
                    source = "shellcheck",
                    code = "SC" .. item.code,
                })
            end
            return diagnostics
        end,
    })

    -- ------------------------------------------------------------------------
    -- Hadolint (JSON output, no end positions)
    -- ------------------------------------------------------------------------
    define_linter({
        name = "hadolint",
        cmd = { "hadolint", "-f", "json" },
        patterns = {
            "Dockerfile",
            "Dockerfile.*",
            "*.dockerfile",
            "Containerfile",
            "Containerfile.*",
        },
        parse = function(data)
            local ok, results = pcall(vim.json.decode, table.concat(data, "\n"))
            if not ok or not results then
                return {}
            end
            local diagnostics = {}
            for _, item in ipairs(results) do
                table.insert(diagnostics, {
                    lnum = item.line - 1,
                    col = item.column - 1,
                    severity = SEVERITY[item.level] or vim.diagnostic.severity.WARN,
                    message = item.message,
                    source = "hadolint",
                    code = item.code,
                })
            end
            return diagnostics
        end,
    })

    -- ------------------------------------------------------------------------
    -- Checkmake (line-based output: "lnum:rule:msg")
    -- ------------------------------------------------------------------------
    define_linter({
        name = "checkmake",
        cmd = { "checkmake", "--format={{.LineNumber}}:{{.Rule}}:{{.Violation}}" },
        patterns = {
            "Makefile",
            "makefile",
            "GNUmakefile",
            "*.mk",
        },
        parse = function(data)
            local diagnostics = {}
            for _, line in ipairs(data) do
                local lnum, rule, msg = line:match("^(%d+):([^:]+):(.+)$")
                if lnum then
                    table.insert(diagnostics, {
                        lnum = tonumber(lnum) - 1,
                        col = 0,
                        severity = vim.diagnostic.severity.WARN,
                        message = msg,
                        source = "checkmake",
                        code = rule,
                    })
                end
            end
            return diagnostics
        end,
    })

    -- ------------------------------------------------------------------------
    -- yamllint (parsable output: "file:lnum:col: [level] msg (rule)")
    --
    -- yamllint's --format=parsable emits one diagnostic per line of stdout
    -- with the file path baked in. We discard the file path part (the autocmd
    -- already knows which buffer we're linting), and pull line / column /
    -- level / message / rule out of the rest.
    --
    -- The rule-extraction pattern uses ` %((.-)%)$` -- non-greedy + end-anchor
    -- -- so messages that happen to contain "(...)" segments themselves don't
    -- confuse the rule capture. (`(.+)` for the message half is greedy and
    -- gives back to let the rule pattern match the LAST `(rule)`.)
    --
    -- Severity: yamllint emits "error" / "warning" lowercase. Reuses the
    -- shared SEVERITY map at the top of M.setup.
    --
    -- Config lives at ~/.config/yamllint/config (or $XDG_CONFIG_HOME/yamllint
    -- /config). yamllint also reads project-local .yamllint / .yamllint.yml /
    -- .yamllint.yaml from the file's directory upward, which takes precedence
    -- over the user config. So per-project rule overrides Just Work.
    -- ------------------------------------------------------------------------
    define_linter({
        name = "yamllint",
        cmd = { "yamllint", "--format", "parsable" },
        patterns = { "*.yml", "*.yaml" },
        parse = function(data)
            local diagnostics = {}
            for _, line in ipairs(data) do
                local lnum, col, level, msg, rule =
                    line:match("^[^:]*:(%d+):(%d+): %[(%w+)%] (.+) %(([^)]+)%)$")
                if lnum then
                    table.insert(diagnostics, {
                        lnum = tonumber(lnum) - 1,
                        col = tonumber(col) - 1,
                        severity = SEVERITY[level] or vim.diagnostic.severity.WARN,
                        message = msg,
                        source = "yamllint",
                        code = rule,
                    })
                end
            end
            return diagnostics
        end,
    })
end

return M
