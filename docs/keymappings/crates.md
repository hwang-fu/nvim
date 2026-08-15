# Cargo.toml dependencies

*Defined in `lua/hwangfu/crates.lua` (crates.nvim); active only in Cargo.toml buffers.*

This plugin has no keymappings, by choice - the `<leader>c` namespace stays free. Everything runs through its `:Crates` command, which tab-completes its subcommands once a Cargo.toml has been opened.

| Command | Action |
|---------|--------|
| `:Crates show_versions_popup` | Version list for the crate on the current line |
| `:Crates show_features_popup` | Its feature flags |
| `:Crates show_dependencies_popup` | Its dependencies |
| `:Crates update_crate` | Move to the newest version the requirement allows |
| `:Crates upgrade_crate` | Rewrite the requirement to the newest version |
| `:Crates update_all_crates` / `upgrade_all_crates` | The same, for every crate in the file |
| `:Crates toggle` | Show or hide the inline latest-version hints |
| `:Crates reload` | Drop the cache and fetch fresh data from crates.io |
| `:Crates expand_plain_crate_to_inline_table` | Turn `foo = "1"` into an inline table |
| `:Crates extract_crate_into_table` | Move a dependency into its own `[dependencies.foo]` section |
| `:Crates open_documentation` | Open the crate on docs.rs |
| `:Crates open_cratesio` / `open_homepage` / `open_repository` | Open its other pages |
| `:Crates use_git_source` | Point the dependency at its git repository |

For a visual selection, `update_crates` and `upgrade_crates` act on the selected lines: select, then `:'<,'>Crates update_crates`.

Completion, hover (`K`), and code actions (`<leader>ca`, which offers per-crate update and upgrade) come through the LSP layer: crates.nvim runs an in-process language server alongside taplo.
