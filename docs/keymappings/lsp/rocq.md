# Rocq (Coq)

*Interactive proofs via Coqtail (`lua/jwa/plugins/spec/coqtail.lua`). The one language page here that is **not** about a language server - see [Why not an LSP](#why-not-an-lsp).*

## The problem this solves

Writing a proof is not like writing a function. A function you can read and judge; a proof is a sequence of tactics where each one transforms an invisible thing - the **goal state** - and the only question that matters while you are typing is *what does the goal look like right now*. Syntax highlighting cannot answer it. Neither can a diagnostic that appears after you have written the whole thing.

So the editor has to run Rocq alongside you, feed it your file one sentence at a time, and show you what came back. That is what Coqtail does, and it is why proof assistants have always needed more than an ordinary editor plugin.

## The three windows

Opening a `.v` file and starting Coqtail splits the screen:

| Window | Holds |
|--------|-------|
| Your source | The proof, with the **checked region** highlighted - everything Rocq has accepted so far |
| **Goal** | The goal state at the end of the checked region: hypotheses above the line, what remains to prove below |
| **Info** | Whatever Rocq said - error messages, query answers, warnings |

The checked region is the thing to watch. It advances as you send sentences and retreats as you take them back, and the Goal panel always shows the state at its edge.

## The loop

Start with `<leader>cc`, then it is three keys:

| Key | Command | What it does |
|-----|---------|--------------|
| `<leader>cj` | `RocqNext` | Send the next sentence. The checked region grows by one |
| `<leader>ck` | `RocqUndo` | Take one back. The checked region shrinks, and Rocq forgets it |
| `<leader>cl` | `RocqToLine` | Jump the checked region to the cursor - forward or backward, whichever is needed |

`<leader>cl` is the one you will use most: put the cursor where you are working and let Rocq catch up. `{n}` prefixes work too, so `5<leader>cj` sends five sentences.

Two more for finding your place after scrolling:

| Key | Command | What it does |
|-----|---------|--------------|
| `<leader>cG` | `RocqJumpToEnd` | Cursor to the end of the checked region |
| `<leader>cE` | `RocqJumpToError` | Cursor to where Rocq objected |

## Asking Rocq questions

These answer in the Info panel, using the term under the cursor (or the visual selection):

| Key | Command | Question |
|-----|---------|----------|
| `<leader>ch` | `Rocq Check` | What is the type of this? |
| `<leader>ca` | `Rocq About` | Tell me about this - type, implicit arguments, where it came from |
| `<leader>cp` | `Rocq Print` | Show me its definition |
| `<leader>cf` | `Rocq Locate` | Where is this defined, and what does the notation mean? |
| `<leader>cs` | `Rocq Search` | What theorems mention this? |

`:Rocq <anything>` sends an arbitrary query, so vernacular commands with no mapping - `Print Assumptions foo`, `Search (_ + 0 = _)` - go through the same channel. Every `Rocq*` command also answers to a `Coq*` alias.

`<leader>cgd` (`RocqGotoDef`) jumps to a definition and fills the quickfix list with the candidates. `CTRL-]` works too, through `'tagfunc'`.

## Panels and goals

| Key | Command | What it does |
|-----|---------|--------------|
| `<leader>cr` | `RocqRestorePanels` | Re-open the Goal and Info windows after closing them |
| `]g` / `[g` | `RocqGotoGoalNext` / `Prev` | Scroll the Goal panel between goals when a tactic left several |
| `<leader>cgg` | `RocqGotoGoal` | Scroll to the nth goal |
| `<leader>cq` | `RocqStop` | Quit Rocq for this buffer |

## Things worth knowing before they surprise you

**`CTRL-C` is bound to `RocqInterrupt`** in Rocq buffers - it sends SIGINT to Rocq, which is what you want when a tactic is spinning, and is not what your fingers expect. To free it: `map <leader>ci <Plug>RocqInterrupt` before Coqtail loads.

**Undo is not free.** `<leader>ck` makes Rocq forget the sentence, which for anything nontrivial means re-checking on the way forward. Rewinding across a long proof and replaying it is genuinely slow; `<leader>cl` to the line you care about is usually cheaper than stepping.

**Project settings come from `_CoqProject`.** Load paths, `-Q` and `-R` mappings, and flags belong in that file at the project root, not in this config. Coqtail reads it; so does `rocq compile`, so the two agree by construction.

**`.v` is a contested extension.** Verilog, Rocq and V all use it. This config no longer forces it to Verilog - Neovim reads the first 500 lines and decides, which gets both right. If it ever guesses wrong on a real file, `vim.g.filetype_v` overrides it outright.

## Symbols

`forall` is drawn as the quantifier glyph and `exists` as its partner, so a statement reads closer to how it would be written on paper. It is on by default.

**Nothing is rewritten.** `conceallevel` is a window option, so the file on disk still says `forall`, and so do the buffer, `grep`, the git diff, and what Rocq reads. Open the same file in two splits with different settings and the text is identical in both - only the drawing differs.

| Command | Effect |
|---------|--------|
| `:RocqUnconceal` | Show the file as written, in this window |
| `:RocqConceal` | Back to symbols |

You rarely need either, because the line you are working on un-conceals itself. `concealcursor` is set to `n`, which means the cursor line joins the concealing **only in normal mode**: start typing or select a region and that line snaps back to `forall` while everything around it stays symbolic. That matters more than it sounds - a concealed word occupies one cell instead of six, so while it is drawn as a symbol the cursor's real column stops matching where it appears.

The symbol table is in `after/syntax/coq.vim` and is deliberately two entries long: long enough to find out whether concealing suits you, short enough that nothing has to be unlearned if it does not. Note the hard limit before extending it - Vim's `cchar` accepts exactly **one** character, so any substitution needing two or more is not expressible at all.

## Why not an LSP

Every other language here is driven by a language server, and `coq-lsp` exists - it is even installed in the opam switch. It was not chosen, for two reasons.

Continuous checking re-verifies the file on every edit, and a single `Qed` can take seconds. Step-through only checks as far as you have gone, which is why most Coq work is still done this way; it is a real property of proof checking, not nostalgia.

And the uniformity an LSP would have bought is thinner than it looks: coq-lsp's own capability table still answers "No" to references, code actions, semantic tokens and inlay hints. The familiar `K` / `gd` / `<leader>ca` keys would mostly have been familiar keys that did nothing.

One consequence: **no language server attaches to `.v` buffers**, so the common LSP keys are simply absent there and Coqtail's `<leader>c*` namespace has the buffer to itself. `<leader>ca` means "About" here, not "code action".

## What it needs

Both already installed on this machine.

**Python 3 with `pynvim`** - Coqtail's engine is Python and talks to Neovim through the python3 provider. `:checkhealth provider` confirms it.

**`coqidetop` on `PATH`** - and this is the non-obvious one. Rocq's IDE protocol is *not* part of the `rocq` binary; `rocq` has no `ide` subcommand at all. It lives in a separate XML protocol server, packaged in opam as `coqide-server`:

```
opam install coqide-server
```

Coqtail launches `coqidetop` by name, so without that package it fails at startup with nothing visibly wrong in the config. The whole Rocq toolchain here comes from the opam switch (`rocq-core`, `rocq-stdlib`, `coqide-server`), and `~/.local/bin/freshup` keeps it current through its `opam upgrade` step.
