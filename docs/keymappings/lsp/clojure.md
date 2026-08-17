# Clojure

*REPL keys from conjure and structural editing from parinfer (`lua/hwangfu/plugins/spec/lisp.lua`); static analysis from clojure-lsp (`lua/hwangfu/lsp/servers/clojure_lsp.lua`).*

Two engines share the work. clojure-lsp reads the code statically: completion, `gd`-style navigation, `<leader>rn` rename, `grr` references, format on save (cljfmt). Conjure talks to a **live REPL**: everything below with a `\` prefix evaluates real code in your running program. The localleader is backslash, so `\ee` means: press backslash, then `e`, then `e`.

All common [LSP keys](lsp.md) apply. Conjure shadows two of them in Clojure buffers: `gd` and `K` go through conjure first (definition and docs from the live REPL, falling back to the LSP).

## Starting the REPL

Conjure does not start the REPL - you do, once per project, in a terminal at the project root:

```
clj -M:nrepl:portal
```

The server writes a `.nrepl-port` file and conjure connects through it automatically when you open a Clojure buffer - if the REPL started after the buffer was already open, `\cf` connects on demand.

The `:portal` half only puts the Portal data inspector on the classpath; it costs nothing until opened from the REPL, which is why the chained form is the recommended habit. Plain `clj -M:nrepl` works whenever Portal is not wanted. Everything in the tables below needs that connection; without it, evaluations report no connected server.

The `:nrepl` alias is defined once in the user-level `~/.clojure/deps.edn` (set up 2026-08-17), so every project on the machine has it. That file carries four more aliases, each documented by its own comments there:

| Alias | Invocation | Purpose |
|-------|------------|---------|
| `:nrepl` | `clj -M:nrepl` | The REPL server conjure connects to, with tools.namespace bundled for the refresh keys below |
| `:outdated` | `clj -M:outdated` | Report every dependency with a newer release (antq) |
| `:portal` | `clj -M:nrepl:portal` | Add the Portal GUI data inspector to the REPL classpath |
| `:rebel` | `clj -M:rebel` | A pleasant standalone terminal REPL, for poking without Neovim |
| `:test` | `clj -X:test` | Run the project's tests from the CLI or a Makefile (Cognitect test-runner) |

Aliases compose by chaining colons, as the `:portal` row shows - with one caveat noted in the file: when several chained aliases define a main entry, only the last one wins.

## Evaluating

| Key | Action |
|-----|--------|
| `\ee` | Evaluate the expression under the cursor |
| `\er` | Evaluate the top-level form under the cursor - the workhorse: edit a function, `\er`, it is live |
| `\eb` | Evaluate the whole buffer |
| `\ew` | Evaluate the word under the cursor - inspect what a symbol currently holds |
| `\e!` | Evaluate the form and replace it in the buffer with its result |
| `\E` | Evaluate the visual selection |
| `\ei` | Interrupt the oldest running evaluation - the escape hatch for an accidental infinite loop |
| `\xr` | Show the macroexpansion of the current form (`\x1` expands one step, `\xa` expands everything) |
| `\ls` / `\lv` | Open conjure's log of results in a split / vsplit |

The idiomatic scratchpad is the rich comment block: a `(comment ...)` at the bottom of a file full of loose expressions. The compiler ignores it; you put the cursor inside any form and `\ee` it. Experiments stay in the file, versioned, without ever running at load time.

## Tests

Tests are expressions too - these run them in the live REPL, no separate command:

| Key | Action |
|-----|--------|
| `\tc` | Run the test under the cursor |
| `\tn` | Run all tests in this namespace |
| `\tN` | Run the tests of the alternate namespace - from `foo.clj`, runs `foo-test` |
| `\ta` | Run every currently loaded test |

## Refreshing - the reloaded workflow

Hours of redefining things make the live process drift from what a cold start would produce (deleted functions linger, stale definitions survive). The cure is refreshing namespaces from disk, and it is one key:

| Key | Action |
|-----|--------|
| `\rr` | Reload every namespace whose file changed |
| `\ra` | Reload all namespaces, changed or not |
| `\rc` | Clear the refresh cache, when a refresh gets confused |

Refresh often; treat a fresh JVM (and CI) as the source of truth.

## Inspecting

| Key | Action |
|-----|--------|
| `\vt` | View and drain everything sent to `tap>` - sprinkle `(tap> x)` in code instead of print statements, collect the values here |
| `\ve` | View the last exception as structured data instead of a stack-trace wall |
| `\v1` / `\v2` / `\v3` | Recall the three most recent evaluation results |
| `\vs` | View the source of the symbol under the cursor |

## Connection

| Key | Action |
|-----|--------|
| `\cf` | Connect to the server from the `.nrepl-port` file (what auto-connect does; use it after starting the REPL with Neovim already open) |
| `\cd` | Disconnect |

Conjure also manages multiple nREPL sessions under `\s*`; that is rarely needed day one - `:help conjure-client-clojure-nrepl` has the full list.

> [!NOTE]
> The general Lisp-family story (parinfer, rainbow-delimiters, Fennel / Racket / Scheme evaluation, slimv for Common Lisp) lives in [lisp](lisp.md); this page is the Clojure-specific REPL workflow.
