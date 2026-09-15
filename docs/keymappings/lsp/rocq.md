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

Twenty-one pieces of ASCII are drawn as the symbols they stand for, plus the twenty-four Greek letter names in both cases ([below](#greek-letters)), so a statement reads closer to how it would be written on paper. It is on by default, and it applies everywhere in the file - inside theorem statements, inside definitions, and inside comments alike.

| Written | Drawn | Codepoint |
|---------|-------|-----------|
| `forall` | the universal quantifier | U+2200 |
| `exists` | the existential quantifier | U+2203 |
| `\/` | logical OR | U+2228 |
| `/\` | logical AND | U+2227 |
| `~` | the not sign | U+00AC |
| `<>` | not equal to | U+2260 |
| `\|-` | right tack - entails | U+22A2 |
| `\|=` | double turnstile - models | U+22A8 |
| `\|\|-` | forces | U+22A9 |
| `True`, `Verum`, `VERUM`, `Truth` | verum / top | U+22A4 |
| `False`, `Falsum`, `FALSUM`, `Falsehood` | falsum / bottom | U+22A5 |
| `Alef` | alef | U+2135 |
| `Bet` | bet | U+2136 |
| `Gimel` | gimel | U+2137 |
| `Dalet` | dalet | U+2138 |

**The arrows are deliberately absent.** `->`, `<->`, `=>` and `|->` were drawn as arrows for part of 2026-09-16 and taken back out; `<=`, `>=`, `:=` and `fun` are absent too. `fun` is still drawn in OCaml, see [ocaml](ocaml.md), and `:=` is the interesting absence - it is explained at the end of this section.

**Where two rules overlap, the longer one wins**, which matters once in the table as it now stands: `||-` is one forces sign rather than a bar followed by a right tack. That falls out of the scan running left to right - it reaches the first bar, matches the longest thing available there and consumes all of it - but `|-` also carries a lookbehind refusing a preceding bar, so the outcome depends on neither the order of the table nor on anything a later rule might do.

That distinction is worth keeping in mind before adding anything, because the scan only settles overlaps where the longer rule starts an **earlier column**. Where two rules would start at the **same** column, Vim takes the one *defined last* instead, which would make the result depend on where the next row happens to be inserted. Any rule that can be a prefix of another needs an explicit guard rather than a position in the list.

`|-` carries a second guard for a rule that no longer exists: it refuses a following `>`, so `|->` stays entirely as ASCII rather than coming out as a right tack and a stray `>`. Half-substituted is worse than not substituted.

Ordinary uses of the same characters are untouched, because every rule needs its characters **adjacent**: `| Z` in a `match` branch, `x || y`, `a <= b`, `a >= b`, `a -> b` and the `-` `+` `*` bullets that open a proof step are all left as written.

The four cardinals use U+2135 to U+2138, the **Hebrew letterlike symbols** from the Letterlike Symbols block, and not the Hebrew letters themselves at U+05D0 onwards. The two sets look nearly identical and are not interchangeable here. The letterlike symbols are bidi class `L`; the Hebrew letters are class `R`, and a right-to-left character dropped into a line of left-to-right code makes the surrounding text reorder itself on screen. STIX Two Math also carries all four letterlike symbols and none of the Hebrew letters, so the Hebrew spellings would fall out of the symbol routing and land in whatever Hebrew-capable font fontconfig reached for. That block holds exactly four - alef, bet, gimel, dalet - so there is no fifth to add: U+2139 is the information source sign, not samekh.

**`:=` cannot be done, and the reason is structural rather than a matter of effort.** It was added and removed on the same day. The `:=` that opens a definition body is not an ordinary token: it is the *start match of a region*, and Coqtail reaches that region through `nextgroup` rather than by letting it compete. A `nextgroup` target is forced, so a rule of ours is never offered the column at all - the same mechanism the number sets above exploit deliberately, here working against us. Coqtail has at least eleven such regions, opening the bodies of `Definition`, `Instance`, `Fixpoint`, `Ltac`, `Notation`, `Module`, `Obligation`, `Coercion` and `Inductive`. A `:=` in ordinary term position *did* conceal, which is the worst of both outcomes: the common occurrence would have stayed ASCII while the rare one became a symbol. Getting it properly would mean redefining those eleven regions in `after/syntax/coq.vim`, which is forking Coqtail's syntax file in all but name.

### Fonts

A substitution is only as good as the font behind it. Where the terminal font lacks a codepoint the terminal silently falls back to some other installed font, and the glyph arrives at the wrong weight and size - the usual symptom is a symbol that looks shrunken next to the letters around it.

`fc-list ":charset=<hex>" family` answers whether a font has one, so a candidate can be checked before it goes in the table rather than after it looks wrong on screen. Nerd Font *Symbols* never helps here - it covers the icon Private Use Area, not the mathematical blocks.

Measuring the installed fonts against this table is what set two of its entries. The **n-ary** operators U+22C0 and U+22C1 were the first choice for `/\` and `\/`, and almost nothing carries them - of every monospaced family on this machine, only Iosevka and FreeMono did. The **binary** connectives U+2227 and U+2228 are what Rocq's operators actually mean, and they are additionally present in DejaVu Sans Mono, JetBrains Mono, Fira Code and Noto Sans Mono, so the swap cost nothing and widened the field considerably.

With the table as it now stands, Fira Code, Iosevka, DejaVu Sans Mono, JetBrains Mono, Noto Sans Mono and FreeMono each carry all nine; Hack misses only falsum. The terminal's own default font need not carry any of them, because kitty's `symbol_map` in `~/.config/kitty/modules/fonts.conf` routes exactly these codepoints to one font that does - Fira Code, at the time of writing.

Size is a separate question from coverage, and worth measuring rather than eyeballing: at the same point size, different families draw the same symbol at noticeably different heights relative to their own capitals. Rendering each candidate's glyph and comparing its ink height against the terminal font's `A` is enough to rank them.

Each of the two constants has **four accepted spellings**, for developments that name them differently: `True`, `Verum`, `VERUM` and `Truth` all become the top symbol, and `False`, `Falsum`, `FALSUM` and `Falsehood` all become the bottom one. They are ordinary extra rows, not a different kind of rule.

All of them are matched **case-sensitively**, and the all-capital pair are listed separately for that reason rather than out of clumsiness. Case sensitivity is what keeps the `bool` constructors `true` and `false` untouched; relaxing it for `VERUM` would take `TRUE`, `tRue` and every other spelling with it. `TRUE` and `FALSE` are therefore *not* drawn, and neither is an identifier that merely contains one of the words - `True_is_true`, `Truthy`, `Falsums` and `VERUMS` are each one word to Vim and are left alone.

They are also left alone inside a **qualified name**: `a.True.b` and `Nat.False` stay as written, because a component of a dotted path is a reference to something in a module rather than the constant itself. A sentence-ending dot is a different thing and still works - `Lemma l : True.` is drawn with the symbol. The two cases are told apart by what follows the dot, since Rocq itself does the same: a `.` before whitespace or end of line ends a sentence, a `.` before an identifier character separates a qualifier.

### Number sets

Thirteen names for the standard number sets are drawn as their double-struck letters, with superscripts and subscripts where the name carries them:

| Written | Drawn | | Written | Drawn |
|---------|-------|-|---------|-------|
| `Nat` | double-struck N | | `Rational` | double-struck Q |
| `NatWithZero` | N with subscript zero | | `PosRational` | Q with superscript plus |
| `Integer` | double-struck Z | | `NegRational` | Q with superscript minus |
| `PosInteger` | Z with superscript plus | | `Real` | double-struck R |
| `NegInteger` | Z with superscript minus | | `PosReal` | R with superscript plus |
| `NonNegInteger` | Z, superscript plus, subscript zero | | `NegReal` | R with superscript minus |
| `Complex` | double-struck C | | | |

Eight of the thirteen need **more than one glyph**, and `cchar` accepts exactly one. The way round it is to stop thinking of a rule as covering a word: the word is cut into as many adjacent pieces as there are glyphs, and each piece gets its own one-character rule. Vim draws one replacement per concealed region and keeps neighbouring regions from different groups separate, so the pieces arrive side by side. Where the cut falls is arbitrary, because the glyphs appear in the order the *pieces* do rather than in any order the word implies.

The pieces are chained with `contained` and `nextgroup`, which is worth knowing if you ever extend the table, because the two obvious alternatives both fail. `\zs` does nothing here at all: it moves where a match is reported, not where the engine starts trying it, so a second rule still has to begin matching at a column the first rule already consumed, and only the leading glyph ever appears. A look-behind is correct but expensive - any `\@<=` drops Vim onto its backtracking engine and is then attempted at every column whether it can match or not, which measured 13 microseconds a call against 1 for a plain word rule and **doubled the whole buffer's syntax cost**. Bounding the look-behind with `\@N<=` changed nothing, so the cost is the engine choice rather than the scan distance. Chaining with `nextgroup` has neither problem and brought the total back to within seven percent of where it started.

Substring collisions need no special handling, which is worth stating because it looks like they should: `Integer` inside `PosInteger` is not matched, since there is no word boundary after the `s`, and `Nat` inside `NatWithZero` is not matched, since the trailing guard rejects the `W`. Both fall out of guards that are there for other reasons.

### Primed names

A name followed only by apostrophes **is** drawn, as the symbol plus the apostrophes: `beta'` becomes the small letter with a prime after it, `alpha''` with two, and `True'` likewise. The convention that `x'` is "another `x`" survives the substitution, which is the point.

The apostrophes have to end the identifier. `beta'x` is left as written, because a name like that is its own thing rather than a derived `beta`, and reading it as a primed beta would be wrong. Everything else that merely *contains* a name is left alone for the same reason: `beta_conv`, `beta1`, `betax` and `alphabet` are all untouched.

This is why the guard is a lookahead rather than a plain word boundary. `'iskeyword'` in a Rocq buffer is `@,48-57,192-255,_,'` - the apostrophe is a word character - so `beta'` is a *single word* to Vim, and `\>` refused to match after `beta`. The lookahead says "apostrophes are allowed here, anything else that could continue an identifier is not", which a word boundary cannot express.

| Written | Drawn |
|---------|-------|
| `beta` | the letter |
| `beta'`, `beta''` | the letter, then the apostrophes |
| `beta'x` | as written |
| `beta_conv`, `beta1`, `betax` | as written |
| `M.beta`, `M.beta'` | as written |

### Greek letters

All twenty-four letter names are drawn as the letter, in both cases - `alpha` becomes the small letter, `Alpha` the capital, and so on through `omega` and `Omega`. The names are the ordinary spellings:

```
alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu
nu xi omicron pi rho sigma tau upsilon phi chi psi omega
```

They carry the same qualified-name guard as `True` and `False`, for the same reason - `M.alpha` and `Setoid.gamma` stay as written - and the same **primed-name** rule described below.

The forty-eight rules are **generated** from the name list in `after/syntax/coq.vim` rather than written out, so a codepoint can only be got wrong in one place instead of forty-eight. Both Greek blocks run in the order above, which makes the codepoint the index - with one irregularity worth knowing before editing the list: U+03A2 is unassigned and U+03C2 is *final* sigma, the word-ending form, which is not what a mathematical sigma means. Both blocks therefore shift by one from sigma onward, and because they shift at the same index a single correction covers both.

This is much the largest group here, and it is worth knowing it costs almost nothing. Measured with `:syntime` over sixty full redraws of a 449-line proof file, every syntax rule in the buffer together came to 15ms per redraw of the *whole file*, with the slowest of the new rules averaging a microsecond per call. A real redraw only covers the visible window. Adding the primed-name lookahead to all fifty guarded rules moved that total by about eight percent, which is the scale to expect from anything added here.

**Nothing is rewritten.** `conceallevel` is a window option, so the file on disk still says `forall`, and so do the buffer, `grep`, the git diff, and what Rocq reads. Open the same file in two splits with different settings and the text is identical in both - only the drawing differs.

| Command | Effect |
|---------|--------|
| `:RocqUnconceal` | Show the file as written, in this window |
| `:RocqConceal` | Back to symbols |

You rarely need either, because the line you are working on un-conceals itself. `concealcursor` is set to `n`, which means the cursor line joins the concealing **only in normal mode**: start typing or select a region and that line snaps back to `forall` while everything around it stays symbolic. That matters more than it sounds - a concealed word occupies one cell instead of six, so while it is drawn as a symbol the cursor's real column stops matching where it appears.

The symbol tables are in `after/syntax/coq.vim`. There are **two** of them, and which one a new substitution belongs in is not a style choice - it decides whether the rule works at all:

- **Word-shaped** substitutions (`forall`, `exists`) are declared with `:syn keyword`. They have to be, because Coqtail declares `forall` as a keyword too, and in Vim a keyword outranks a match no matter which was defined last. Only another keyword can override it.
- **Everything else** is declared with `:syn match`. That covers the operators, which are not words at all, and also `True` and `False`, which are words but need a **guard** a keyword cannot carry: unlike the reserved quantifiers they are ordinary identifiers, so they appear inside qualified names, and a bare keyword drew `a.True.b` as `a.verum.b`. Match-against-match is settled by definition order, and an `after/syntax` file is sourced after the syntax file it augments, so ours wins.

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
