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

Fifty-one pieces of ASCII are drawn as the symbols they stand for, plus the twenty-four Greek letter names in both cases ([below](#greek-letters)), so a statement reads closer to how it would be written on paper. It is on by default, and it applies everywhere in the file - inside theorem statements, inside definitions, and inside comments alike.

| Written | Drawn | Codepoint |
|---------|-------|-----------|
| `Bool` | double-struck B | U+1D539 |
| `List` | script L | U+2112 |
| `Pair` | script P | U+1D4AB |
| `Empty` | double-struck zero | U+1D7D8 |
| `Unit` | double-struck one | U+1D7D9 |
| `pi_1` | pi with a subscript one | U+03C0 U+2081 |
| `pi_2` | pi with a subscript two | U+03C0 U+2082 |
| `iota_1` | iota with a subscript one | U+03B9 U+2081 |
| `iota_2` | iota with a subscript two | U+03B9 U+2082 |
| `forall` | the universal quantifier | U+2200 |
| `exists` | the existential quantifier | U+2203 |
| `\/` | logical OR | U+2228 |
| `/\` | logical AND | U+2227 |
| `_\/_` | exclusive OR | U+22BB |
| `^^` | circled plus | U+2295 |
| `~` | the not sign | U+00AC |
| `<>` | not equal to | U+2260 |
| `~=` | almost equal to | U+2248 |
| `~==` | approximately equal to | U+2245 |
| `==` | identical to | U+2261 |
| `-/-` | slash bar | U+233F |
| `\|-` | right tack - entails | U+22A2 |
| `\|=` | double turnstile - models | U+22A8 |
| `\|\|-` | forces | U+22A9 |
| `::` | proportion | U+2237 |
| `<\|` | white left-pointing triangle | U+25C1 |
| `\|>` | white right-pointing triangle | U+25B7 |
| `belongs_to` | element of | U+2208 |
| `contains_member` | contains as member | U+220B |
| `does_not_belong_to` | not an element of | U+2209 |
| `does_not_contain_member` | does not contain as member | U+220C |
| `sqrt` | the radical | U+221A |
| `cbrt` | the cube radical | U+221B |
| `bra` | left angle bracket | U+27E8 |
| `ket` | right angle bracket | U+27E9 |
| `Because` | because | U+2235 |
| `Therefore` | therefore | U+2234 |
| `All` | n-ary logical AND - the list conjunction | U+22C0 |
| `Any` | n-ary logical OR - the list disjunction | U+22C1 |
| `True`, `Verum`, `VERUM`, `Truth` | verum / top | U+22A4 |
| `False`, `Falsum`, `FALSUM`, `Falsehood` | falsum / bottom | U+22A5 |
| `Alef` | alef | U+2135 |
| `Bet` | bet | U+2136 |
| `Gimel` | gimel | U+2137 |
| `Dalet` | dalet | U+2138 |

The **triangles** `<|` and `|>` keep guards against a doubled bar even though `<||` and `||>` are not in the table: `<|` refuses a following bar and `|>` refuses a preceding one, so those two spellings stay entirely ASCII rather than coming out as a triangle with a stray bar beside it. That is the same job the guard on `|-` does for `|->`.

`sqrt` and `cbrt` are drawn as the **radical alone**, with the argument beside it rather than under it. Nothing here can draw the bar that would run over the argument in print: a conceal replaces the characters of the word itself and reaches no further, and the argument is ordinary text of unknown length.

`Because` and `Therefore` are **capitalised**, and case sensitivity is what keeps the lower-case prose forms out. The capitalised forms do open sentences, though, so a comment beginning "Therefore the goal" is drawn with the symbol in place of the word - the same trap `contains` fell into before it was renamed. Neither spelling appears anywhere in the library today, which is why they are here as written rather than under a suffixed name.

`bra` and `ket` reach the same two angle brackets the [structures](#algebraic-structures) use. `bracket` keeps both of them out by itself: the trailing guard refuses the `c` after `bra`, and no word boundary falls before the `k`.

The three **equivalences** nest inside each other and inside the negation, so `~`, `~=`, `~==` and `==` only work as a set. `~` refuses a following equals, which keeps it out of the other three; `~=` refuses a second equals, which keeps it out of `~==`; and `==` refuses a tilde, an equals or a `<` before it and an equals or a `>` after it. That last list is not symmetry for its own sake - it is the four spellings a reader would otherwise meet half-drawn: `~==`, `===`, `==>` and `<==`. None of those is in the table, and uniform ASCII beats one symbol with a leftover character stuck to it. A tilde that is *not* part of an equivalence is still the negation, so `~=~` draws as two symbols side by side, and `::` likewise refuses a colon on either side so a run of three stays as written.

The four **membership relations** are words, not operators, and they are drawn where the word stands rather than where the symbol conventionally goes: `belongs_to x s` reads as the element-of sign followed by its two arguments, in prefix position, not as `x` element-of `s`. Concealing replaces text in place and cannot move it, so an infix reading would have to come from a Rocq `Notation` instead.

Each negation is its own row rather than a prefix rule, and it has to be: an underscore is an identifier character, and a word boundary cannot fall after one, so no rule for `contains_member` can ever fire inside `does_not_contain_member`. That is what stops the pair from drawing half of each other - and it is equally why **any other spelling of a negation is left alone whole**. `not_contains_member`, `contains_not`, `does_not_belong` and the shorter `does_not_contain` are all untouched, and each would need a row of its own.

`contains_member` carries its suffix for this table's sake rather than Rocq's. The bare `contains` was tried on 2026-09-17 and taken back out: it is an ordinary **English word**, and since the rules apply inside comments, a sentence saying that one thing contains another came out with the set-theory symbol sitting in the middle of it. Every other entry here is either punctuation or a name nobody writes in running prose, and the suffix is what puts this one in the same position. The name has to match whatever the Rocq source actually calls the relation - concealing draws the identifier, it does not rename it.

`All` and `Any` take the **n-ary** operators, and which glyph goes to which word is worth stating because the two differ only in the direction of the wedge and at one cell are near enough identical to swap without noticing. The library settles it: `All` folds with `/\` and is `Verum` on the empty list, `Any` folds with `\/` and is `Falsum`, so `All` is the AND and `Any` is the OR. The doubled U+2A07 and U+2A08 were used first and dropped on **width** - they advance 1.51 em in the symbol font against 1.18 for the n-ary pair, which at the cell in use is 1.93 cells against 1.51. Coverage did not decide it either way: only the routed family has to carry them, and it carries all four.

Both are also ordinary **English words**, so like the bare `contains` they can be drawn inside prose - a comment opening with "All three cases" is drawn with the symbol. They are kept as they are because the collision is rarer: only a capitalised whole word matches, and the qualified `Core.All` and `Data.All` of the umbrella-import convention are already refused by the leading-dot guard.

**The six bracket halves are deliberately absent.** `{|`, `|}`, `[|`, `|]`, `(|` and `|)` were drawn as white brackets for part of 2026-09-17 and taken back out. A record literal is punctuation the eye skips over; replacing both of its halves shifted every field one column and left the line saying no more than before.

**No arrow is drawn.** `->`, `<->`, `=>` and `|->` were drawn as arrows for part of 2026-09-16 and taken back out; `-/>` followed them on 2026-09-18 after a day in the table, which removed the last of them. `<=`, `>=`, `:=` and `fun` are absent too. `-/-` is the near miss worth naming: it shares `-/` with the arrow that is gone, but it is a slash bar rather than an arrow and it stays. `fun` is still drawn in OCaml, see [ocaml](ocaml.md), and `:=` is the interesting absence - it is explained at the end of this section.

**Where two rules overlap, the longer one wins**, which matters twice in the table as it now stands: `||-` is one forces sign rather than a bar followed by a right tack, and `_\/_` is one exclusive-or rather than an underscore, a disjunction and another underscore. That falls out of the scan running left to right - it reaches the first character of the longer rule, matches the longest thing available there and consumes all of it - but `|-` and `\/` each also carry a lookbehind refusing the character that precedes them in the longer form, so the outcome depends on neither the order of the table nor on anything a later rule might do.

That distinction is worth keeping in mind before adding anything, because the scan only settles overlaps where the longer rule starts an **earlier column**. Where two rules would start at the **same** column, Vim takes the one *defined last* instead, which would make the result depend on where the next row happens to be inserted. Any rule that can be a prefix of another needs an explicit guard rather than a position in the list.

Two rules carry guards for the same reason - **half a substitution reads worse than none**. `|-` refuses a following `>`, so `|->` stays entirely as ASCII rather than coming out as a right tack and a stray `>`. `^^` refuses a caret on either side, so a run of three or more stays ASCII too; without that, `^^^` came out as *two* circled pluses, the engine having found a match at the first caret and another at the second.

Ordinary uses of the same characters are untouched, because every rule needs its characters **adjacent**: `| Z` in a `match` branch, `x || y`, `a <= b`, `a >= b`, `a -> b` and the `-` `+` `*` bullets that open a proof step are all left as written.

The four cardinals use U+2135 to U+2138, the **Hebrew letterlike symbols** from the Letterlike Symbols block, and not the Hebrew letters themselves at U+05D0 onwards. The two sets look nearly identical and are not interchangeable here. The letterlike symbols are bidi class `L`; the Hebrew letters are class `R`, and a right-to-left character dropped into a line of left-to-right code makes the surrounding text reorder itself on screen. STIX Two Math also carries all four letterlike symbols and none of the Hebrew letters, so the Hebrew spellings would fall out of the symbol routing and land in whatever Hebrew-capable font fontconfig reached for. That block holds exactly four - alef, bet, gimel, dalet - so there is no fifth to add: U+2139 is the information source sign, not samekh.

**`:=` cannot be done, and the reason is structural rather than a matter of effort.** It was added and removed on the same day. The `:=` that opens a definition body is not an ordinary token: it is the *start match of a region*, and Coqtail reaches that region through `nextgroup` rather than by letting it compete. A `nextgroup` target is forced, so a rule of ours is never offered the column at all - the same mechanism the number sets above exploit deliberately, here working against us. Coqtail has at least eleven such regions, opening the bodies of `Definition`, `Instance`, `Fixpoint`, `Ltac`, `Notation`, `Module`, `Obligation`, `Coercion` and `Inductive`. A `:=` in ordinary term position *did* conceal, which is the worst of both outcomes: the common occurrence would have stayed ASCII while the rare one became a symbol. Getting it properly would mean redefining those eleven regions in `after/syntax/coq.vim`, which is forking Coqtail's syntax file in all but name.

### Fonts

A substitution is only as good as the font behind it. Where the terminal font lacks a codepoint the terminal silently falls back to some other installed font, and the glyph arrives at the wrong weight and size - the usual symptom is a symbol that looks shrunken next to the letters around it.

`fc-list ":charset=<hex>" family` answers whether a font has one, so a candidate can be checked before it goes in the table rather than after it looks wrong on screen. Nerd Font *Symbols* never helps here - it covers the icon Private Use Area, not the mathematical blocks.

Measuring the installed fonts against this table is what set two of its entries. The **n-ary** operators U+22C0 and U+22C1 were the first choice for `/\` and `\/`, and almost nothing carries them - of every monospaced family on this machine, only Iosevka and FreeMono did. The **binary** connectives U+2227 and U+2228 are what Rocq's operators actually mean, and they are additionally present in DejaVu Sans Mono, JetBrains Mono, Fira Code and Noto Sans Mono, so the swap cost nothing and widened the field considerably.

With the table as it now stands, Fira Code, Iosevka, DejaVu Sans Mono, JetBrains Mono, Noto Sans Mono and FreeMono each carry all nine; Hack misses only falsum. The terminal's own default font need not carry any of them, because the routing happens outside it, in two places that hold the same list and have to be changed together: kitty's `symbol_map` in `~/.config/kitty/modules/fonts.conf`, and `~/.config/fontconfig/conf.d/75-math-symbol-fallback.conf` for Ptyxis and Alacritty, which have no `symbol_map` of their own. Both send the list to **STIX Two Math Big**, a local copy of STIX Two Math that draws larger at the same point size.

Size is a separate question from coverage, and worth measuring rather than eyeballing: at the same point size, different families draw the same symbol at noticeably different heights relative to their own capitals. Rendering each candidate's glyph and comparing its ink height against the terminal font's `A` is enough to rank them.

Each of the two constants has **four accepted spellings**, for developments that name them differently: `True`, `Verum`, `VERUM` and `Truth` all become the top symbol, and `False`, `Falsum`, `FALSUM` and `Falsehood` all become the bottom one. They are ordinary extra rows, not a different kind of rule.

All of them are matched **case-sensitively**, and the all-capital pair are listed separately for that reason rather than out of clumsiness. Case sensitivity is what keeps the `bool` constructors `true` and `false` untouched; relaxing it for `VERUM` would take `TRUE`, `tRue` and every other spelling with it. `TRUE` and `FALSE` are therefore *not* drawn, and neither is an identifier that merely contains one of the words - `True_is_true`, `Truthy`, `Falsums` and `VERUMS` are each one word to Vim and are left alone.

They are also left alone inside a **qualified name**: `a.True.b` and `Nat.False` stay as written, because a component of a dotted path is a reference to something in a module rather than the constant itself. A sentence-ending dot is a different thing and still works - `Lemma l : True.` is drawn with the symbol. The two cases are told apart by what follows the dot, since Rocq itself does the same: a `.` before whitespace or end of line ends a sentence, a `.` before an identifier character separates a qualifier. The type and number-set names are the one **exception** and are drawn even with a qualifier after them, for the reason given [below](#number-sets).

And left alone once more in **module position** - the word directly after `Module`, `Module Type`, `Section` or `End` names a module rather than the type, so `Module Bool.` and its closing `End Bool.` both stay as written while `(b : Bool)` inside is drawn.

That guard looks redundant and is not. Coqtail wraps a module in a single region and puts `Module <name>` and the matching `End <name>` in its `matchgroup`, which no rule an `after/syntax` file defines can reach - the same wall that keeps `:=` off the table. But it only holds while the parser knows the region is open, and Coqtail sets `syn sync minlines=50`: in a module longer than fifty lines that state is lost whenever the screen is reached by a **jump** rather than by scrolling down from the top, and the `End` line then drew the symbol or not depending on how the cursor had arrived. Guarding here does not depend on parse state at all, and it is also the only half that covers a module whose `End` names something else.

### Number sets

Fifteen type and number-set names are drawn as a letter of their own, with superscripts and subscripts where the name carries them, and five more as bracketed structures ([below](#algebraic-structures)). `Bool` and `List` are listed in the main table above; the thirteen number sets are:

| Written | Drawn | | Written | Drawn |
|---------|-------|-|---------|-------|
| `Nat` | double-struck N | | `Rational` | double-struck Q |
| `NatWithZero` | N with subscript zero | | `PosRational` | Q with superscript plus |
| `Integer` | double-struck Z | | `NegRational` | Q with superscript minus |
| `PosInteger` | Z with superscript plus | | `Real` | double-struck R |
| `NegInteger` | Z with superscript minus | | `PosReal` | R with superscript plus |
| `NonNegInteger` | Z, superscript plus, subscript zero | | `NegReal` | R with superscript minus |
| `Complex` | double-struck C | | | |

`List` is a **type constructor** rather than a type, and only the constructor is drawn: `List Nat` reads as the script L followed by `Nat`'s own symbol, with the argument left standing beside it as written. Drawing the parameter inside brackets was tried on 2026-09-17 and dropped - a literal `A` there is not the real argument, and following the real one is not reachable, since the closing bracket would need a source character *after* the argument to hang on and the word offers only its own four.

These names, and the five structures below, are the **one group drawn with a qualifier after them**: `Bool.and`, `Nat.add` and `NatWithZero.add` are drawn, where `alpha.b` and `True.b` are not. The reason is that Rocq's convention puts the operations on a type in a module of the same name - `Module Bool.` holds `Bool.and` - so the word before the dot *is* the type, and hiding it there would hide the type in exactly the position where a proof mentions it most. `alpha.b` has the same shape and not the same meaning: there `alpha` names a module that merely happens to be spelled like a letter.

A leading dot is still refused for all of them, so the right-hand side of a path is left alone - `M.Nat` and `Coq.Init.Logic.True` stay as written - and so is a name in module position, `Module Bool.` and its `End Bool.`.

### Algebraic structures

Five names are drawn as the structure they stand for - carrier, operation and unit inside **angle brackets** - rather than as a single symbol:

| Written | Drawn |
|---------|-------|
| `Bool_and_monoid` | left angle, double-struck B `,&&,` top, right angle |
| `Bool_or_monoid` | left angle, double-struck B `,\|\|,` bottom, right angle |
| `Bool_xor_monoid` | left angle, double-struck B `,` circled plus `,` bottom, right angle |
| `NatWithZero_add_monoid` | left angle, double-struck N, subscript zero `,+,0`, right angle |
| `Nat_add_semigroup` | left angle, double-struck N `,+`, right angle |

These are the same chunking as the number sets, pushed as far as it goes: the longest needs eight glyphs and therefore eight pieces and eight source characters to hang them on, which a twenty-two-character identifier has to spare. A semigroup carries no unit, so it is a pair rather than a triple and needs only five.

The commas, ampersands, bars, `+` and `0` are ASCII and so come from the terminal font like any other punctuation; only the angle brackets (U+27E8 and U+27E9), the double-struck letters and the two constants are routed to the symbol font. Nothing here can collide with the plain `Bool`, `Nat` or `NatWithZero` rows, because each of those carries a trailing guard that refuses the `_` following it here.

### Codepoints outside the basic plane

Four substitutions have codepoints in the **supplementary plane**: `Bool`, `Pair`, `Empty` and `Unit`.

For `Bool` and `Pair` it is Unicode's history showing through. A scattering of mathematical letters went into the Letterlike Symbols block long before the full alphabets arrived at U+1D400, so each alphabet now has **holes** where its earlier spelling already lived - and whether a given letter sits in the block or in the hole depends on nothing but which side of that split it fell on. Double-struck skips C, H, N, P, Q, R and Z, which is why every number set above is under U+FFFF while `Bool` is not. Script skips B, E, F, H, I, L, M and R, which is why `List` is U+2112 down in Letterlike while `Pair` is U+1D4AB up in the block - two script capitals, forty-seven thousand codepoints apart, for no reason visible in the glyphs.

`Empty` and `Unit` have no such history. The double-struck **digits** at U+1D7D8 are a complete run of ten with no earlier spellings and so no holes, and the type is drawn as its own cardinality: nothing inhabits `Empty`, one thing inhabits `Unit`. They are these rather than a plain ASCII `0` and `1` because those would read as numerals - particularly next to the ASCII `0` that the monoid rows already draw as a unit element.

Vim takes any of them: `cchar` means one character, not one byte.

Eight of the thirteen number sets need **more than one glyph**, and `cchar` accepts exactly one. The way round it is to stop thinking of a rule as covering a word: the word is cut into as many adjacent pieces as there are glyphs, and each piece gets its own one-character rule. Vim draws one replacement per concealed region and keeps neighbouring regions from different groups separate, so the pieces arrive side by side. Where the cut falls is arbitrary, because the glyphs appear in the order the *pieces* do rather than in any order the word implies.

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

The product projections `pi_1`, `pi_2` and the sum injections `iota_1`, `iota_2` are drawn as their Greek letter with a subscript, and they are listed in the main table rather than here because a second glyph makes them chunked rules rather than generated ones. The plain `pi` and `iota` rows cannot fire inside them: the underscore that follows is an identifier character and the trailing guard refuses it, which is the same way `Bool` steps aside for `Bool_and_monoid`. That guard is also what leaves `pi_3`, `pi_10`, `pi_1_snd` and `iota_1x` entirely alone - only the four exact names are drawn.

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

### Two corrections to Coqtail

`after/syntax/coq.vim` ends with the file's only changes to Coqtail's own parsing rather than additions on top of it. Both repair the same shape of defect: **one token drawn in more than one colour**, because Coqtail predates the spelling.

Rocq lets a class field be written `field :: T`, which declares it an **instance** as well as a projection. Coqtail predates that form: its `coqRecField` region ends on a single colon, so in `reflexive :: Reflexive.R` the first colon closes the region as `coqVernacPunctuation` and the second falls through to the term inside as `coqTermPunctuation`. One token, drawn in two different colours - yellow then blue.

The fix is Coqtail's own two region definitions, copied from `syntax/coq.vim:385-386` with three changes. The end pattern is widened from `:` to `::\|:`, ordered longest-first so a single-colon field parses exactly as it did and a record mixing both forms gets each field right.

The other two changes are what make `::` **concealable** there, and they are worth reading together because each one repairs what the other breaks:

- `matchgroup=NONE` on the end. A region's end match takes no contained items while a matchgroup is set on it - the same wall that keeps `:=` and `Module <name>` out of reach - so before this the conceal rule was never offered the column at all and `::` drew nothing in a class field while working everywhere else.
- `keepend`. Without the matchgroup the conceal rule *does* reach the colons, and then it swallows them: the region's own end pattern no longer matches, the field region runs on to the end of the line, and the field's type comes out coloured as another field name. `keepend` stops a contained match extending past the end.

Dropping the matchgroup costs the single colon its `coqVernacPunctuation` colour, since it now takes the region's own. That is why `coqRecField` is linked to `coqVernacPunctuation` on the line after - the colour is kept by naming it rather than by the matchgroup.

The second correction is `-/>`. Coqtail matches its operators with one long alternation of single and double characters (`syntax/coq.vim:75`), and `-/>` is in none of its branches - so the three characters came out as **three runs**: `-` and `>` each matched their own branch as `coqKwd`, and the slash between them matched nothing and fell through to whatever region enclosed it. One operator, split down the middle in two colours.

A single match over the whole spelling replaces all three, and it wins the column for the ordinary reason: match against match is settled by definition order, and an `after/syntax` file is sourced last. It is linked to **`Type`**, because `a -/> b` is the proposition that `a` does not imply `b` and so reads as a constructor of propositions rather than as punctuation. The link is a `default` one, so naming the group elsewhere overrides it without editing this file.

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
