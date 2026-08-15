# Debugging

*Defined in `lua/hwangfu/dap.lua` (nvim-dap); nothing loads until the first debug key is pressed.*

| Key | Action |
|-----|--------|
| `F5` | Start or continue. In Rust buffers this routes through rustaceanvim's target picker |
| `Shift-F5` | Terminate the session |
| `F6` | Pause |
| `F7` | Toggle the debugger panel |
| `F8` | Pick a Rust cargo target to debug |
| `F9` / `Shift-F9` | Toggle a breakpoint / set a conditional breakpoint |
| `F10` / `F11` / `Shift-F11` | Step over / into / out |

## OCaml

OCaml debugging uses ocamlearlybird (installed through opam) and works on bytecode builds only. Give the executable stanza `(modes byte exe)`, run `dune build`, then press `F5`: the launch config finds `.bc` files under `_build` on its own - a single match runs directly, several offer a choice, and none prompts for a path.
