# Debugging - nvim-dap (lua/hwangfu/dap.lua; loads on first use)

| Key | Action |
|-----|--------|
| F5 | Start / continue (Rust-aware: routes through rustaceanvim) |
| Shift-F5 | Terminate session |
| F6 | Pause |
| F7 | Toggle dap-ui panel |
| F8 | `:RustLsp debuggables` - pick a cargo target to debug |
| F9 / Shift-F9 | Toggle breakpoint / conditional breakpoint |
| F10 / F11 / Shift-F11 | Step over / into / out |

OCaml sessions use ocamlearlybird (installed via opam, not mason) and
debug BYTECODE only: give the executable stanza `(modes byte exe)`, run
`dune build`, then F5. The launch config globs `_build/**/*.bc` - one
match runs directly, several offer a numbered choice, none prompts for
a path.
