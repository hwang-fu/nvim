# Rust

*LSP owned by rustaceanvim (`lua/hwangfu/plugins/spec/rustaceanvim.lua`); server settings in `lua/hwangfu/lsp/servers/rust_analyzer.lua`.*

All common [LSP keys](lsp.md) apply, plus:

| Command / key | Action |
|---------------|--------|
| `:RustLsp <verb>` | rust-analyzer's extras, tab-completable: `expandMacro`, `explainError`, `openDocs`, `runnables`, `debuggables`, `parentModule`, `joinLines`, and more |
| `:RustFormat` | Format the buffer with rustfmt (format-on-save is off for Rust by choice) |
| `K` | Upgraded hover: shows actions you can pick, not just documentation |
| `F8` | Pick a cargo target to debug (see [debugging](../debugging.md)) |

Cargo.toml dependency management has its own page: [crates](../crates.md).
