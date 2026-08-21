# Rust

*LSP owned by rustaceanvim (`lua/jwn/plugins/spec/rustaceanvim.lua`); server settings in `lua/jwn/lsp/servers/rust_analyzer.lua`.*

All common [LSP keys](lsp.md) apply, plus:

| Command / key | Action |
|---------------|--------|
| `:RustFormat` | Format the buffer with rustfmt (format-on-save is off for Rust by choice) |
| `K` | Upgraded hover: shows actions you can pick, not just documentation |

Cargo.toml dependency management has its own page: [crates](../crates.md).

> [!NOTE]
> Inlay hints run near-maximal: types, parameter names, chaining types, closing braces, closure return types, elided lifetimes, binding modes - and inferred generic arguments at call sites (`collect::<Vec<&str>>()` style), type and const args only. The knobs live in `lua/jwn/lsp/servers/rust_analyzer.lua`.

## The `:RustLsp` commands

rust-analyzer's extras, available once the server has attached; every subcommand tab-completes.

A bang - `:RustLsp!` - repeats the last runnable, debuggable, or testable without asking again.

| Command | Action |
|---------|--------|
| `:RustLsp runnables` | Pick any runnable target in the project (binaries, tests, doctests) and run it |
| `:RustLsp run` | Run the target at the cursor position |
| `:RustLsp debuggables` | Pick a target and debug it through nvim-dap - errors here, since this config ships no debugger stack |
| `:RustLsp debug` | Like `debuggables` for the target at the cursor position; same caveat |
| `:RustLsp testables` | Pick a test target and run it |
| `:RustLsp relatedTests` | Open the tests rust-analyzer associates with the symbol under the cursor |
| `:RustLsp flyCheck` | Run `cargo check` in the background and publish its diagnostics; `clear` and `cancel` arguments manage a running check |
| `:RustLsp explainError` | Hover window with the Rust error index explanation, cycling from the cursor to the next error that has an error code |
| `:RustLsp renderDiagnostic` | Hover window with the next diagnostic exactly as `cargo build` would print it |
| `:RustLsp relatedDiagnostics` | Jump to the diagnostics related to the one under the cursor; several results land in the quickfix list |
| `:RustLsp codeAction` | Code action picker that understands rust-analyzer's grouped actions, which the built-in `<leader>ca` flattens |
| `:RustLsp hover range` | Hover for the visually selected expression (normal mode hover is already on `K`) |
| `:RustLsp expandMacro` | Expand the macro under the cursor recursively into a floating window |
| `:RustLsp moveItem up` | Move the item under the cursor up; `moveItem down` for the other direction |
| `:RustLsp joinLines` | Syntax-aware version of `J`: joining fixes up commas, braces, and string literals instead of just gluing text |
| `:RustLsp ssr <query>` | Structural search and replace, over the buffer in normal mode or the selection in visual mode |
| `:RustLsp openCargo` | Open the `Cargo.toml` of the current package |
| `:RustLsp openDocs` | Open the docs.rs page for the symbol under the cursor |
| `:RustLsp parentModule` | Jump to the parent module of the current file |
| `:RustLsp workspaceSymbol` | Filtered workspace symbol search; with the bang, dependencies are searched too |
| `:RustLsp crateGraph` | Render the crate dependency graph (needs graphviz installed) |
| `:RustLsp syntaxTree` | Show the parsed syntax tree of the buffer |
| `:RustLsp view hir` | Show rust-analyzer's HIR of the function under the cursor; `view mir` shows the MIR |
| `:RustLsp logFile` | Open the rust-analyzer log file |
