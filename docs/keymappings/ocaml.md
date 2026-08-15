# OCaml - ocaml.nvim + utop REPL (spec in plugins/spec/ocaml.lua; REPL in lua/hwangfu/repl.lua)

Buffer-local to OCaml buffers. `<localleader>` is backslash, so the keys
below read as typed: `\c` means backslash then c.

| Key | Action |
|-----|--------|
| `\c` | Construct: fill the typed hole under the cursor from valid substitutions |
| `\n` / `\p` | Jump to next / previous typed hole |
| `\s` | Switch between .ml and .mli |
| `\i` | Infer the interface of the matching .ml (run from the .mli buffer) |
| `\t` | Type-enclosing session; then Up/Down grow/shrink the expression, Right/Left raise/lower type verbosity |
| `\j` | Syntax-aware jump (fun / let / match / module targets) |
| `\pn` / `\pp` | Next / previous phrase (top-level item) |
| `\r` | Toggle the project-scoped utop REPL float |

(\p waits timeoutlen before firing since it prefixes \pn / \pp -
upstream's default, kept as-is.)

Command-only extras: `:OCamlTypeExpression <expr>`,
`:OCamlFindIdentifierDefinition` / `:OCamlFindIdentifierDeclaration` /
`:OCamlDocumentIdentifier <ident>`, and type-based search
`:OCamlSearchDefinition` / `:OCamlSearchDeclaration <type>`
(e.g. "int -> string").

The REPL float runs `dune utop .` at the project root (project libraries
loaded) or plain `utop` outside a project. Toggling it away only hides
the window - the session keeps running per project; utop ends with
`#quit` or Ctrl-D. Escape hatch: `Ctrl-\ Ctrl-N` leaves terminal mode,
`i` resumes.
