-- ============================================================================
-- Roslyn: Microsoft's C# / Razor language server (2026-09-08, user request).
--
-- Ownership of the client passes to roslyn.nvim: the plugin resolves which
-- solution or project to target, launches the server over a pipe, and
-- restarts it when the target changes. That is why this file does NOT call
-- helpers.define_server like every other server module - define_server ends
-- with vim.lsp.enable(), which would have Neovim start a second client of its
-- own beside the plugin's.
--
-- What upstream does support is the ordinary config interface: "To configure
-- language server specific settings sent to the server, you can use the
-- vim.lsp.config interface with `roslyn` as the name of the server" (its
-- README). vim.lsp.config merges rather than replaces, so this table and
-- whatever roslyn.nvim registers coexist. Capabilities and on_attach are
-- passed by hand for the same reason - nothing else is filling them in, and
-- without on_attach a C# buffer would be the one place in this config where
-- K, gd and <leader>rn are missing.
--
-- The plugin spec, the server install and the Razor story are in
-- lua/jwa/plugins/spec/roslyn.lua.
-- ============================================================================

local helpers = require("jwa.lsp.helpers")

local M = {}

function M.setup()
    vim.lsp.config("roslyn", {
        capabilities = helpers.make_capabilities(),
        on_attach = helpers.standard_on_attach,

        settings = {
            -- Diagnostics for the whole solution, not just the files that
            -- happen to be open. C# is compiled and cross-file: renaming a
            -- member breaks callers in files you are not looking at, and
            -- openFiles scope would report that only once you opened them.
            -- Costs background CPU on a large solution; that is the trade
            -- being made deliberately.
            ["csharp|background_analysis"] = {
                background_analysis = {
                    dotnet_analyzer_diagnostics_scope = "fullSolution",
                    dotnet_compiler_diagnostics_scope = "fullSolution",
                },
            },

            -- Inlay hints on, matching the preference settled in the Rust,
            -- Lua and Java rounds. The two "implicit" ones are the point of
            -- the feature in C#: `var` and target-typed `new()` hide the type
            -- at exactly the place a reader wants it.
            ["csharp|inlay_hints"] = {
                csharp_enable_inlay_hints_for_implicit_object_creation = true,
                csharp_enable_inlay_hints_for_implicit_variable_types = true,
                csharp_enable_inlay_hints_for_lambda_parameter_types = true,
                csharp_enable_inlay_hints_for_types = true,
                dotnet_enable_inlay_hints_for_indexer_parameters = true,
                dotnet_enable_inlay_hints_for_object_creation_parameters = true,
                dotnet_enable_inlay_hints_for_other_parameters = true,
                dotnet_enable_inlay_hints_for_parameters = true,
                -- Literal parameters deliberately off: hinting the name in
                -- front of every bare 2 or "" is where these stop reading as
                -- annotation and start reading as noise.
                dotnet_enable_inlay_hints_for_literal_parameters = false,
            },

            -- Sort using directives whenever the buffer is formatted, which
            -- here means whenever :CSharpFmt runs. The .NET convention is
            -- sorted usings, and doing it on format keeps it off the list of
            -- things to remember.
            ["csharp|formatting"] = {
                dotnet_organize_imports_on_format = true,
            },

            -- Let completion and go-to-symbol reach into reference
            -- assemblies, so BCL types are findable by name rather than only
            -- through something that already mentions them.
            ["csharp|symbol_search"] = {
                dotnet_search_reference_assemblies = true,
            },
        },
    })
end

return M
