# OCaml

*Editing commands defined in `lua/hwangfu/plugins/spec/ocaml.lua` (ocaml.nvim); the REPL in `lua/hwangfu/repl.lua`.*

All common [LSP keys](lsp.md) apply. These keys exist only in OCaml buffers. The local leader is backslash, so `\c` means: press backslash, then `c`.

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

## Commands

Every key above also exists as a command (`:OCamlConstruct` for `\c`, `:OCamlSwitchIntfImpl` for `\s`, and so on). The ones below are command-only; each takes one argument.

| Command | Action |
|---------|--------|
| `:OCamlTypeExpression <expr>` | Print the type of any expression you give it, without putting it in the buffer |
| `:OCamlFindIdentifierDefinition <name>` | Jump to the definition of an identifier given by name - the `.ml` implementation side |
| `:OCamlFindIdentifierDeclaration <name>` | Jump to the declaration of an identifier given by name - the `.mli` interface side |
| `:OCamlDocumentIdentifier <name>` | Show the documentation of an identifier given by name |
| `:OCamlSearchDefinition <query>` | Search definitions by type, for example `int -> string`; a name works as a query too |
| `:OCamlSearchDeclaration <query>` | The same search, landing on declarations instead of definitions |

## The REPL float

`\r` opens utop in a floating terminal. Inside a dune project it runs `dune utop .` from the project root, so your own libraries are built and loaded; elsewhere it falls back to plain utop. Toggling the float away only hides it - the session keeps running per project until utop exits (`#quit` or `Ctrl-D`). To scroll or copy from the float, `Ctrl-\ Ctrl-N` leaves terminal mode and `i` returns.

## Project-wide references need the index

Finding references across files (`grr`, `Ctrl-LeftClick` at a definition) depends on index files that dune builds **only on request** - a plain `dune build` never creates them. Without the index, ocamllsp silently degrades to same-buffer occurrences: a `val` in an `.mli` reports exactly one reference, itself.

Build the index inside the project with:

```
dune build @ocaml-index
```

The files land in `_build` (`cctx.ocaml-index`, one per library or executable), so they add no source-tree noise - but `dune clean` deletes them, and they go stale as code changes. Rerun the command when references start looking thin, or keep `dune build @ocaml-index -w` running in a spare terminal during longer sessions.

## Notes

- `\p` pauses briefly before firing because it is also the start of `\pn` and `\pp`.
- Local opam switches are auto-detected: the nearest `_opam/` at or above the project root supplies `ocamllsp`, with its `bin` first on the server's PATH so dune and ocamlformat come from the same switch. This covers both a switch beside `dune-project` and one shared switch at the top of a multi-project repo. Without any `_opam` up-tree, the global `ocamllsp` runs.
