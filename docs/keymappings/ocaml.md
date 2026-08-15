# OCaml

*Editing commands defined in `lua/hwangfu/plugins/spec/ocaml.lua` (ocaml.nvim); the REPL in `lua/hwangfu/repl.lua`.*

These keys exist only in OCaml buffers. The local leader is backslash, so `\c` means: press backslash, then `c`.

| Key | Action |
|-----|--------|
| `\c` | Fill the typed hole under the cursor, choosing from valid substitutions |
| `\n` / `\p` | Jump to the next / previous typed hole |
| `\s` | Switch between the `.ml` and its `.mli` |
| `\i` | Infer the interface for the matching `.ml`; run it from the `.mli` buffer |
| `\t` | Start a type-enclosing session: `Up` / `Down` grow and shrink the inspected expression, `Right` / `Left` adjust type verbosity |
| `\j` | Jump to an enclosing target: fun, let, match, or module |
| `\pn` / `\pp` | Jump to the next / previous top-level phrase |
| `\r` | Toggle the utop REPL float for this project |

Some features are commands only: `:OCamlTypeExpression <expr>` prints an arbitrary expression's type, `:OCamlFindIdentifierDefinition` and friends look up a named identifier, and `:OCamlSearchDefinition` searches by type, for example `int -> string`.

## The REPL float

`\r` opens utop in a floating terminal. Inside a dune project it runs `dune utop .` from the project root, so your own libraries are built and loaded; elsewhere it falls back to plain utop. Toggling the float away only hides it - the session keeps running per project until utop exits (`#quit` or `Ctrl-D`). To scroll or copy from the float, `Ctrl-\ Ctrl-N` leaves terminal mode and `i` returns.

## Notes

- `\p` waits a moment before firing because it is a prefix of `\pn` and `\pp`. That is the upstream default, kept as is.
