# Rust dependencies - crates.nvim (lua/hwangfu/crates.lua; Cargo.toml only)

No keymappings, by choice (2026-08-15; the former `<leader>c*` set was
removed to keep that namespace free). Use the plugin's own `:Crates`
command instead - tab-completable, available once a Cargo.toml has
been opened:

| Command | Action |
|---------|--------|
| `:Crates show_versions_popup` | Versions popup for the crate on the current line |
| `:Crates show_features_popup` | Features popup |
| `:Crates show_dependencies_popup` | Dependencies popup |
| `:Crates update_crate` | Update to the newest version the requirement allows |
| `:Crates update_crates` / `update_all_crates` | Same, for a visual range / the whole file |
| `:Crates upgrade_crate` | Rewrite the requirement to the newest version |
| `:Crates upgrade_crates` / `upgrade_all_crates` | Same, for a visual range / the whole file |
| `:Crates toggle` / `show` / `hide` | Inline latest-version info on / off |
| `:Crates reload` | Drop the cache and re-fetch from crates.io |
| `:Crates expand_plain_crate_to_inline_table` | `foo = "1"` becomes an inline table |
| `:Crates extract_crate_into_table` | Extract into a `[dependencies.foo]` section |
| `:Crates open_documentation` | Open the crate on docs.rs |
| `:Crates open_cratesio` / `open_homepage` / `open_repository` | Open its other pages |
| `:Crates use_git_source` | Switch the dependency to its git source |

Completion, hover (`K`) and code actions (`<leader>ca` - per-crate
update / upgrade / open docs) ride the LSP layer: crates.nvim runs an
in-process language server, and taplo's bindings query every attached
client.
