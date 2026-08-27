# Clojure

*REPL keys from conjure (`lua/jwa/plugins/spec/lisp.lua`); static analysis from clojure-lsp (`lua/jwa/lsp/servers/clojure_lsp.lua`). No structural-editing plugin: parens are yours to type, and only format-on-save (whitespace-only) touches the code.*

Two engines share the work. clojure-lsp reads the code statically: completion, `gd`-style navigation, `<leader>rn` rename, `grr` references, format on save (cljfmt), and compact hovers (arities on one line, no file-path footer). Conjure talks to a **live REPL**: everything below with a `\` prefix evaluates real code in your running program. The localleader is backslash, so `\ee` means: press backslash, then `e`, then `e`.

All common [LSP keys](lsp.md) apply. Conjure shadows two of them in Clojure files: `gd` and `K` go through conjure first (definition and docs from the live REPL, falling back to the LSP). Throughout this page, "a Clojure file" means anything Neovim detects as the clojure filetype: `.clj`, `.cljs`, `.cljc`, and `.edn`.

## Starting the REPL

Conjure does not start the REPL - you do, once per project, in a terminal at the project root:

```
clj -M:nrepl:portal
```

The server writes a `.nrepl-port` file and conjure connects through it automatically when you open a Clojure file - if the REPL started after the file was already open, `\cf` connects on demand.

The `:portal` half only puts the Portal data inspector on the classpath; it costs nothing until opened from the REPL, which is why the chained form is the recommended habit. Plain `clj -M:nrepl` works whenever Portal is not wanted.

Forgetting is covered: opening a Clojure file inside a project with no live nREPL server prints a one-line error naming the command (once per project per session; error-level so it stands out in red). A leftover `.nrepl-port` file from a crashed server is detected too - the check actually probes the port instead of trusting the file. Everything in the tables below needs that connection; without it, evaluations report no connected server.

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

Every key also exists as a command, created by conjure in Clojure files - the Command column below. Four more are global: `:ConjureEval <code>` evaluates arbitrary text you type, `:ConjureConnect [host] [port]` connects anywhere, `:ConjureClientState` switches state keys, and `:ConjureSchool` starts conjure's interactive tutorial.

| Key | Command | Action |
|-----|---------|--------|
| `\ee` | `:ConjureEvalCurrentForm` | Evaluate the expression under the cursor |
| `\er` | `:ConjureEvalRootForm` | Evaluate the top-level form under the cursor - the workhorse: edit a function, `\er`, it is live |
| `\eb` | `:ConjureEvalBuf` | Evaluate the whole file as currently shown in the editor, saved or not |
| `\ew` | `:ConjureEvalWord` | Evaluate the word under the cursor - inspect what a symbol currently holds |
| `\e!` | `:ConjureEvalReplaceForm` | Evaluate the form and replace its text with the result, right in the file |
| `\E` | `:ConjureEvalVisual` | Evaluate the visual selection |
| `\ei` | `:ConjureCljInterrupt` | Interrupt the oldest running evaluation - the escape hatch for an accidental infinite loop |
| `\xr` | `:ConjureCljMacroExpand` | Show the macroexpansion of the current form (`\xa` / `:ConjureCljMacroExpandAll` expands everything) |
| `\ls` / `\lv` | `:ConjureLogSplit` / `:ConjureLogVSplit` | Open conjure's log of results in a split / vsplit |

The idiomatic scratchpad is the rich comment block: a `(comment ...)` at the bottom of a file full of loose expressions. The compiler ignores it; you put the cursor inside any form and `\ee` it. Experiments stay in the file, versioned, without ever running at load time.

## Tests

Tests are expressions too - these run them in the live REPL, no separate command:

| Key | Command | Action |
|-----|---------|--------|
| `\tc` | `:ConjureCljRunCurrentTest` | Run the test under the cursor |
| `\tn` | `:ConjureCljRunCurrentNsTests` | Run all tests in this namespace |
| `\tN` | `:ConjureCljRunAlternateNsTests` | Run the tests of the alternate namespace - from `foo.clj`, runs `foo-test` |
| `\ta` | `:ConjureCljRunAllTests` | Run every currently loaded test |

## Refreshing - the reloaded workflow

Hours of redefining things make the live process drift from what a cold start would produce (deleted functions linger, stale definitions survive). The cure is refreshing namespaces from disk, and it is one key:

| Key | Command | Action |
|-----|---------|--------|
| `\rr` | `:ConjureCljRefreshChanged` | Reload every namespace whose file changed |
| `\ra` | `:ConjureCljRefreshAll` | Reload all namespaces, changed or not |
| `\rc` | `:ConjureCljRefreshClear` | Clear the refresh cache, when a refresh gets confused |

Refresh often; treat a fresh JVM (and CI) as the source of truth.

## Inspecting

| Key | Command | Action |
|-----|---------|--------|
| `\vt` | `:ConjureCljViewTap` | View and drain everything sent to `tap>` - sprinkle `(tap> x)` in code instead of print statements, collect the values here |
| `\ve` | `:ConjureCljLastException` | View the last exception as structured data instead of a stack-trace wall |
| `\v1` / `\v2` / `\v3` | - | Recall the three most recent evaluation results (keys only, no command form) |
| `\vs` | `:ConjureCljViewSource` | View the source of the symbol under the cursor |

## Connection

| Key | Command | Action |
|-----|---------|--------|
| `\cf` | `:ConjureCljConnectPortFile` | Connect to the server from the `.nrepl-port` file (what auto-connect does; use it after starting the REPL with Neovim already open) |
| `\cd` | `:ConjureCljDisconnect` | Disconnect |

Conjure also manages multiple nREPL sessions under `\s*`; that is rarely needed day one - `:help conjure-client-clojure-nrepl` has the full list.

## Outside a project

A `.clj` file with no `deps.edn` or `project.clj` up-tree has nothing conjure can auto-connect to; opening one prints a single warning instead ("no nREPL to connect to (stray file, no project)"). Two ways forward:

**Upgrade the folder to a project** - the thirty-second fix, and the better habit:

```
echo '{}' > deps.edn
clj -M:nrepl:portal
```

An empty `{}` is a complete, working project file: the `clj` tool merges the installation defaults, then `~/.clojure/deps.edn` (where the `:nrepl` / `:portal` aliases live), then the project file - so everything is inherited and the whole workflow above just works. Do NOT copy the user-level file into projects; it already applies everywhere, and copies drift stale. A project's own `deps.edn` carries only what is specific to it, conventionally starting from `{:paths ["src"] :deps {}}` once a second namespace needs to `require` the first.

**Or connect by hand** - run `clj -M:nrepl` in any terminal, read the port it prints (or the `.nrepl-port` file it writes there), and `:ConjureConnect <port>`. Works, but nothing about the file's location is remembered; the project route makes it automatic next time.

> [!NOTE]
> The general Lisp-family story (parinfer, rainbow-delimiters, Fennel / Racket / Scheme evaluation, slimv for Common Lisp) lives in [lisp](lisp.md); this page is the Clojure-specific REPL workflow.
