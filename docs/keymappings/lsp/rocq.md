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

`<leader>cl` is the one you will use most: put the cursor where you are working and let Rocq catch up.

Two more for finding your place after scrolling:

| Key | Command | What it does |
|-----|---------|--------------|
| `<leader>cG` | `RocqJumpToEnd` | Cursor to the end of the checked region |
| `<leader>cE` | `RocqJumpToError` | Cursor to where Rocq objected |

And three that sit outside the rhythm:

| Key | Command | What it does |
|-----|---------|--------------|
| `<leader>cT` | `RocqToTop` | Rewind the whole file - the checked region goes back to nothing |
| *(no mapping)* | `RocqOmitToLine` | Like `RocqToLine`, but **skips the proof bodies** rather than checking them. Much faster when you only want to reach a later point in a long file and do not care whether the proofs behind you still go through |
| `<leader>cd` | `RocqToggleDebug` | Coqtail's own debug log, on and off |

## Counts

**Pressing a key on its own runs it once.** That is already the default; nothing extra is needed, and most of the time it is what you want.

A count is an **optional prefix typed before the key**, exactly like `5j` or `3dd` in ordinary Vim - the digits come first, ahead of the Space that starts `<leader>`. So `5<leader>cj` is typed `5`, `Space`, `c`, `j`.

Two different defaults are in play, and the difference matters:

| Key | On its own | With a count |
|-----|------------|--------------|
| `<leader>cj` | send 1 sentence | `5<leader>cj` sends 5 |
| `<leader>ck` | take 1 back | `3<leader>ck` takes 3 back |
| `<leader>cgg` | scroll to goal 1 | `3<leader>cgg` scrolls to goal 3 |
| `<leader>cl` | move to the **line the cursor is on** | `42<leader>cl` moves to line 42 |

The first three count *sentences* or *goals* and fall back to **1**. `<leader>cl` counts *lines* and falls back to **0**, which Coqtail reads as "wherever the cursor is" - that is why the bare key does the useful thing rather than jumping to line 1.

The commands take a count the same way, in front of the name: `:5RocqNext`, `:3RocqUndo`, `:42RocqToLine`.

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

**Every key on this page is normal or visual mode only.** Coqtail maps nine of its commands in **insert** mode as well, and that half is switched off here (`g:coqtail_noimap`, set in `lua/jwa/plugins/spec/coqtail.lua`). The reason is that `<leader>` is Space: an insert-mode `<Space>cj` makes every space you type the prefix of a mapping, so Vim waits the full `'timeoutlen'` - a whole second - before committing it, and typing a proof stalls on every word boundary. Nothing on this page changes, because stepping a proof from insert mode was never useful.

**`CTRL-C` is bound to `RocqInterrupt`** in Rocq buffers - it sends SIGINT to Rocq, which is what you want when a tactic is spinning, and is not what your fingers expect. To free it: `map <leader>ci <Plug>RocqInterrupt` before Coqtail loads.

**Undo is not free.** `<leader>ck` makes Rocq forget the sentence, which for anything nontrivial means re-checking on the way forward. Rewinding across a long proof and replaying it is genuinely slow; `<leader>cl` to the line you care about is usually cheaper than stepping.

**Project settings come from `_CoqProject`.** Load paths, `-Q` and `-R` mappings, and flags belong in that file at the project root, not in this config. Coqtail reads it; so does `rocq compile`, so the two agree by construction.

**`.v` is a contested extension.** Verilog, Rocq and V all use it. This config no longer forces it to Verilog - Neovim reads the first 500 lines and decides, which gets both right. If it ever guesses wrong on a real file, `vim.g.filetype_v` overrides it outright.

## Symbols

Ten pieces of ASCII are drawn as the symbols they stand for, so a statement reads closer to how it would be written on paper. It is on by default, and it applies everywhere in the file - inside theorem statements, inside definitions, and inside comments alike.

| Written | Drawn | Codepoint |
|---------|-------|-----------|
| `forall` | the universal quantifier | U+2200 |
| `exists` | the existential quantifier | U+2203 |
| `fun` | lambda | U+03BB |
| `\/` | logical OR | U+2228 |
| `/\` | logical AND | U+2227 |
| `~` | the not sign | U+00AC |
| `<>` | not equal to | U+2260 |
| `<->` | long left-right arrow | U+27F7 |
| `True` | verum / top | U+22A4 |
| `False` | falsum / bottom | U+22A5 |

`<=` is deliberately not in the table and keeps its ASCII. `<>` and `<->` cannot be confused with each other - one needs a `>` immediately after the `<`, the other a hyphen - so neither eats the other.

### Fonts

A substitution is only as good as the font behind it. Where the terminal font lacks a codepoint the terminal silently falls back to some other installed font, and the glyph arrives at the wrong weight and size - the usual symptom is a symbol that looks shrunken next to the letters around it.

`fc-list ":charset=<hex>" family` answers whether a font has one, so a candidate can be checked before it goes in the table rather than after it looks wrong on screen. Nerd Font *Symbols* never helps here - it covers the icon Private Use Area, not the mathematical blocks.

Measuring the installed fonts against this table is what set two of its entries. The **n-ary** operators U+22C0 and U+22C1 were the first choice for `/\` and `\/`, and almost nothing carries them - of every monospaced family on this machine, only Iosevka and FreeMono did. The **binary** connectives U+2227 and U+2228 are what Rocq's operators actually mean, and they are additionally present in DejaVu Sans Mono, JetBrains Mono, Fira Code and Noto Sans Mono, so the swap cost nothing and widened the field considerably.

With the table as it now stands, Fira Code, Iosevka, DejaVu Sans Mono, JetBrains Mono and FreeMono each carry all ten; Hack misses only falsum. The terminal's own default font need not carry any of them, because kitty's `symbol_map` in `~/.config/kitty/modules/fonts.conf` routes exactly these ten codepoints to one font that does.

`True` and `False` are matched **case-sensitively**, so the `bool` constructors `true` and `false` are left as they are - only the two `Prop`-level constants become symbols. An identifier that merely contains the word, such as `True_is_true`, is one word to Vim and is not touched either.

**Nothing is rewritten.** `conceallevel` is a window option, so the file on disk still says `forall`, and so do the buffer, `grep`, the git diff, and what Rocq reads. Open the same file in two splits with different settings and the text is identical in both - only the drawing differs.

| Command | Effect |
|---------|--------|
| `:RocqUnconceal` | Show the file as written, in this window |
| `:RocqConceal` | Back to symbols |

You rarely need either, because the line you are working on un-conceals itself. `concealcursor` is set to `n`, which means the cursor line joins the concealing **only in normal mode**: start typing or select a region and that line snaps back to `forall` while everything around it stays symbolic. That matters more than it sounds - a concealed word occupies one cell instead of six, so while it is drawn as a symbol the cursor's real column stops matching where it appears.

The symbol tables are in `after/syntax/coq.vim`. There are **two** of them, and which one a new substitution belongs in is not a style choice - it decides whether the rule works at all:

- **Word-shaped** substitutions (`forall`, `exists`) are declared with `:syn keyword`. They have to be, because Coqtail declares `forall` as a keyword too, and in Vim a keyword outranks a match no matter which was defined last. Only another keyword can override it.
- **Operator-shaped** substitutions (`\/`, `/\`) are declared with `:syn match`, since they are not words. Match-against-match is settled by definition order, and an `after/syntax` file is sourced after the syntax file it augments, so ours wins.

Every rule in both tables carries `containedin=ALL`, and that is load-bearing rather than decorative. Coqtail wraps almost every interesting position in a region with an explicit `contains=` list, and a region only ever matches the items that list names; without `containedin=ALL` the rules are created, appear in `:syntax list`, and never fire. That is exactly what the first version of this file did between 2026-09-12 and 2026-09-13: it concealed nothing.

One hard limit before extending either table - Vim's `cchar` accepts exactly **one** character, so any substitution needing two or more is not expressible at all.

### Colour

A replacement character is **always** painted with the `Conceal` highlight group. The syntax item's own group is ignored, so `hi link rocqConcealed1 ...` does nothing - verified by linking one of them to `Todo` and watching the drawn cell keep reporting `Conceal`.

That would normally mean every symbol turning up in whatever grey `Conceal` happens to be. `after/ftplugin/coq.lua` avoids it with `winhighlight`, which remaps a highlight group **for one window**: `Conceal:coqKwd` makes the glyphs render in Coqtail's keyword colour here and changes nothing in any other filetype. `coqKwd` is the right target because it is what Coqtail paints all seven substitutions with in the first place, so a symbol keeps the colour its ASCII had.

The catch is inherent rather than a shortcut: `Conceal` is one group per window, so all seven necessarily share a colour. Giving them different ones is not expressible through syntax concealment at all.

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
