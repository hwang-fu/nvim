" Symbol concealing for Rocq. Display only: 'conceallevel' is a window option,
" so the file on disk, the buffer, grep and the git diff are all untouched.
"
" Replacement characters are built with nr2char() so this file stays pure
" ASCII. The window options and the :RocqConceal / :RocqUnconceal commands are
" in after/ftplugin/coq.lua; docs/keymappings/lsp/rocq.md has the full table
" and the reasoning behind what is in it and what is deliberately not.
"
" Coqtail's Goal and Info panels source this same file from
" after/syntax/coq-goals.vim and coq-infos.vim, so every rule here applies to
" them too, and b:current_syntax tells the three apart where that matters.
"
" Two engine rules shape everything below, and both cost a version of this
" file before they were understood:
"
"   * A region only matches the items its own contains= names, and Coqtail
"     wraps every interesting position in one. Without containedin=ALL a rule
"     here is created, listed by :syntax list, and never fires.
"   * Keywords outrank matches whatever the definition order, and only another
"     keyword can override one. Coqtail declares `forall` with :syn keyword,
"     so ours must be a keyword too.
"
" 'cchar' takes exactly one character, which is why anything needing two or
" three glyphs goes through the chunking in s:sets rather than a plain row.

" Keywords, so they outrank Coqtail's. Safe as bare words because both are
" RESERVED: neither can be a module name, so neither appears in a qualified
" name the way an ordinary identifier can.
let s:words = [
      \ ['forall', 0x2200],
      \ ['exists', 0x2203],
      \ ]

" The two guards every word-shaped rule carries. Ordinary identifiers, unlike
" the reserved quantifiers above, turn up inside qualified names.
"
"   s:pre   not preceded by a dot, and not preceded by a vernacular that takes
"           a module name. A LEADING dot can only be a qualifier separator, so
"           that half alone kills `a.True.b` and `Nat.True`. The second half
"           is for `Module Bool.` and its `End Bool.`, where the word names a
"           module rather than the type.
"   s:post  after the name allow apostrophes, then refuse an identifier
"           character or a dot that starts one. That draws three lines at
"           once: `beta'` is drawn and `beta'x` is not; `beta_conv` and
"           `betax` are not; and a TRAILING dot stays ambiguous as it is in
"           Rocq, where `.` before whitespace ends a sentence - so
"           `Lemma l : True.` is drawn - while `.` before an identifier
"           character separates a qualifier and is not.
"   s:setpost  the same, minus the qualifier half. It is used by the type and
"           number-set names in s:sets and by nothing else, because there the
"           word before the dot IS the type: Rocq's convention is that the
"           operations on a type live in a module of the same name, so
"           `Bool.and` and `Nat.add` are reached through the very word being
"           drawn. `alpha.b` is not the same shape - there `alpha` names a
"           module that happens to be spelled like a letter - so the constants
"           and the Greek letters keep the stricter guard.
"
" s:post needs a lookahead rather than a plain \>, because an apostrophe is in
" 'iskeyword' here and `beta'` is therefore ONE word to Vim. Note the doubled
" apostrophe: in a single-quoted Vim string `''` is one literal apostrophe.
"
" The module half of s:pre looks redundant against Coqtail, which wraps a
" module in one region and puts both `Module <name>` and the matching
" `End <name>` in its matchgroup, where nothing here can reach them - but that
" holds only while the parser knows the region is open. Coqtail sets
" `syn sync minlines=50`, so in a module longer than fifty lines the state is
" lost whenever the screen is reached by a jump rather than by scrolling down,
" and the End line then drew the symbol or not depending on how the cursor got
" there. Guarding here is independent of parse state, and it is also the only
" half that covers a module whose End names something else.
let s:pre = '\%(\.\|\<\%(Module\|Section\|End\)\%(\s\+\%(Type\|Import\|Export\)\)\?\s\+\)\@<!\<'
let s:post = '\%(''*\%(\k\|\.\k\)\@!\)\@='
let s:setpost = '\%(''*\k\@!\)\@='

" Operators and guarded words.
"
" '\\/' is the three characters \ \ / - an escaped backslash then a slash,
" matching Rocq's \/ - and '/\\' the same the other way round. '\~' is escaped
" because a bare ~ in a Vim pattern means the previous substitute string, and
" the carets because an unescaped ^ at the start of a pattern anchors to the
" start of the line. '<>' and '-/-' need no escaping: it is \< and \> that are
" the word boundaries, and the slash is only special as a pattern delimiter,
" which these patterns do not use. The bar in '|>' needs none either: 'magic'
" is in force, where a bar counts only as part of \|.
"
" The six bracket halves - '{|' '|}' '[|' '|]' '(|' '|)' - were drawn as white
" brackets for part of 2026-09-17 and removed. They are absent rather than
" pending: a record literal is punctuation the eye skips, and replacing both
" of its halves moved every field one column without making the line say more.
"
" The two triangles keep their guards even though the doubled spellings they
" were written against are gone: `<|` refuses a following bar and `|>` refuses
" a preceding one, so `<||` and `||>` stay entirely ASCII rather than coming
" out as a triangle with a stray bar beside it. That is the same job the
" `\%(>\)\@!` on `|-` does for `|->`, and the reason is the same - a half
" substitution reads worse than none.
"
" `::` refuses a colon on either side, so a run of three or more stays ASCII
" rather than drawing one proportion sign and a leftover colon. That is the
" same treatment `^^` gets, for the same reason.
"
" Reaching it in a class field takes the correction at the bottom of this
" file: Coqtail ends its coqRecField region on the colon, and a region's end
" match takes no contained items while a matchgroup is set on it, so before
" that correction the rule was never offered the column at all.
"
" The three equivalences nest inside each other and inside the negation, so
" all four rows carry guards and the set only works as a set. `~` refuses a
" following equals, which is what keeps it out of `~=` and `~==`; `~=` refuses
" a second equals, which is what keeps it out of `~==`; and `==` refuses a
" tilde, an equals or a less-than before it and an equals or a greater-than
" after it. That last list is not symmetry for its own sake - it is the four
" spellings a reader would otherwise meet half-drawn: `~==`, `===`, `==>` and
" `<==`. None of those four is in the table, and uniform ASCII beats one
" symbol with a leftover character stuck to it.
"
" No arrow is drawn. '->', '<->', '=>' and '|->' were tried on 2026-09-16 and
" removed, and '-/>' followed them on 2026-09-18 after a day in the table.
" '-/-' is the near miss worth naming: it shares those first two characters
" but is a slash bar rather than an arrow, and it needed no guard against the
" arrow while that existed, because the two differed in the third character.
"
" The caret rule refuses a caret on either side, so a run of three or more
" stays entirely ASCII. Without that `^^^` came out as TWO circled pluses -
" the engine finds a match at the first caret and another at the second - and
" half a substitution reads worse than none.
"
" `_\/_` contains `\/` and starts a column earlier, so the scan settles that
" pair the way it settles `||-` against `|-`; the lookbehind on `\/` is there
" to keep the outcome independent of this list's order.
"
" `||-` and `|-` overlap, and the scan settles it: it runs left to right, so
" at the first bar only `||-` can match and it consumes all three characters.
" The lookbehind on `|-` makes that independent of this list's order anyway.
" Its second guard, refusing a following `>`, is for a rule that no longer
" exists: it keeps `|->` entirely ASCII rather than a right tack plus a stray
" `>`, and half-substituted is worse than not substituted.
"
" `:=` is absent and cannot be added. The `:=` that opens a definition body is
" the start match of a region reached through nextgroup (coqDef ->
" coqDefContents1 in Coqtail's syntax/coq.vim), and a nextgroup target is
" forced rather than competed for, so no rule here is ever offered that column.
" It would conceal in ordinary term position only - the rarer half - and
" Coqtail has eleven such regions. Uniform ASCII beats half a substitution.
"
" `syn case match` is in force, so none of the capitalised words below touch
" the bool constructors `true` and `false`. That is also why the all-capital
" spellings are their own rows: relaxing case for VERUM would take TRUE and
" every other spelling with it.
"
" `bra` and `ket` draw the same two angle brackets the structure rows use, and
" they need no guard beyond the usual pair: `bracket` keeps both of them out
" by itself, since the trailing guard refuses the `c` after `bra` and no word
" boundary falls before the `k`.
"
" `Because` and `Therefore` are capitalised, and `syn case match` is what keeps
" the lower-case prose forms out. That leaves the capitalised forms, which do
" open sentences: a comment beginning `Therefore the goal` is drawn with the
" symbol in place of the word, the way `contains` was before it was renamed.
" Neither spelling appears anywhere in the library today, which is why they
" are here as written rather than under a suffixed name.
"
" `sqrt` and `cbrt` are drawn as the radical alone, without the vinculum that
" would run over the argument in print. Nothing here can draw that bar: a
" conceal replaces the characters of the word itself and reaches no further,
" and the argument after it is ordinary text of unknown length.
"
" The four membership relations are the only words here whose symbol
" conventionally sits BETWEEN its arguments. Concealing replaces text where it
" stands and cannot move it, so all four are drawn in the prefix position the
" source puts them in.
"
" Each negated form is its own row rather than a prefix rule, because an
" underscore is an identifier character and \< cannot match after one: no rule
" for `contains_member` can ever fire inside `does_not_contain_member`, which
" keeps the pair from ever drawing half of each other. It is also why any
" other spelling of a negation - `not_contains_member`, `contains_not`, or
" the shorter `does_not_contain` this row used to carry - is left alone
" whole, and would need a row of its own.
"
" `All` and `Any` take the N-ARY operators U+22C0 and U+22C1, and the pair is
" easy to assign backwards: the two glyphs differ only in which way the wedge
" points, and at one cell they are near enough identical to swap without
" noticing. What settles it is how the library defines them - `All` folds with
" /\ and is Verum on the empty list, `Any` folds with \/ and is Falsum - so
" All is the AND and Any is the OR.
"
" The doubled U+2A07 and U+2A08 were tried first and dropped on width: in the
" symbol font they advance 1.51 em against 1.18 for the n-ary pair, which at
" the cell in use is 1.93 cells against 1.51. Both still overflow, and these
" two are the widest entries in the table either way.
"
" Both are ordinary English words and so can be drawn in prose, the way the
" bare `contains` was. They are kept anyway because the collision is rarer -
" only a capitalised, whole-word `All` or `Any` matches, and a qualified
" `Core.All` or `Data.All` is already refused by the leading-dot guard.
"
" `All` carries one guard of its own: it refuses a preceding `Printing`, for
" `Unset Printing All.` - the debugging command, not the quantifier. Coqtail
" protects the `Set` form itself, inside a chain of regions whose last start
" match covers the word; it has no region for `Unset`, so without this guard
" that half drew the symbol.
"
" `contains_member` is named for this file's sake rather than Rocq's. The bare
" `contains` was tried first and is an ordinary English word; the rules apply
" inside comments, so a sentence saying one thing contains another came out
" with the set-theory symbol in the middle of it. Every other entry here is
" either punctuation or a name nobody writes in running prose, and the suffix
" is what puts this one in the same position.
"
" The cardinals use U+2135-U+2138, the four Hebrew LETTERLIKE SYMBOLS, not the
" Hebrew letters at U+05D0 onward. Those are bidi class R and would reorder the
" line around them, and STIX carries none of them. The block holds exactly four
" - there is no samekh.
let s:ops = [
      \ ['_\\/_', 0x22BB],
      \ ['\%(_\)\@<!\\/', 0x2228],
      \ ['/\\', 0x2227],
      \ ['\~\%(=\)\@!', 0x00AC],
      \ ['\~=\%(=\)\@!', 0x2248],
      \ ['\~==', 0x2245],
      \ ['\%(\~\|=\|<\)\@<!==\%(=\|>\)\@!', 0x2261],
      \ ['\%(\^\)\@<!\^\^\%(\^\)\@!', 0x2295],
      \ ['<>', 0x2260],
      \ ['-/-', 0x233F],
      \ ['||-', 0x22A9],
      \ ['\%(|\)\@<!|-\%(>\)\@!', 0x22A2],
      \ ['|=', 0x22A8],
      \ ['<|\%(|\)\@!', 0x25C1],
      \ ['\%(|\)\@<!|>', 0x25B7],
      \ ['\%(:\)\@<!::\%(:\)\@!', 0x2237],
      \ [s:pre . 'bra' . s:post, 0x27E8],
      \ [s:pre . 'ket' . s:post, 0x27E9],
      \ [s:pre . 'Because' . s:post, 0x2235],
      \ [s:pre . 'Therefore' . s:post, 0x2234],
      \ [s:pre . 'sqrt' . s:post, 0x221A],
      \ [s:pre . 'cbrt' . s:post, 0x221B],
      \ [s:pre . 'belongs_to' . s:post, 0x2208],
      \ [s:pre . 'contains_member' . s:post, 0x220B],
      \ [s:pre . 'does_not_belong_to' . s:post, 0x2209],
      \ [s:pre . 'does_not_contain_member' . s:post, 0x220C],
      \ ['\%(\<Printing\s\+\)\@<!' . s:pre . 'All' . s:post, 0x22C0],
      \ [s:pre . 'Any' . s:post, 0x22C1],
      \ [s:pre . 'True' . s:post, 0x22A4],
      \ [s:pre . 'Verum' . s:post, 0x22A4],
      \ [s:pre . 'VERUM' . s:post, 0x22A4],
      \ [s:pre . 'Truth' . s:post, 0x22A4],
      \ [s:pre . 'False' . s:post, 0x22A5],
      \ [s:pre . 'Falsum' . s:post, 0x22A5],
      \ [s:pre . 'FALSUM' . s:post, 0x22A5],
      \ [s:pre . 'Falsehood' . s:post, 0x22A5],
      \ [s:pre . 'Alef' . s:post, 0x2135],
      \ [s:pre . 'Bet' . s:post, 0x2136],
      \ [s:pre . 'Gimel' . s:post, 0x2137],
      \ [s:pre . 'Dalet' . s:post, 0x2138],
      \ ]

" The 24 Greek letters in both cases, generated rather than listed so a
" codepoint can only be got wrong in one place instead of forty-eight. Both
" blocks run in the order below, which makes the codepoint the index - with
" one irregularity: U+03A2 is unassigned and U+03C2 is FINAL sigma, so both
" blocks shift by one from index 17, and they shift at the same index.
let s:greek = ['alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'eta',
      \ 'theta', 'iota', 'kappa', 'lambda', 'mu', 'nu', 'xi', 'omicron', 'pi',
      \ 'rho', 'sigma', 'tau', 'upsilon', 'phi', 'chi', 'psi', 'omega']

let s:i = 0
for s:name in s:greek
  let s:skip = s:i >= 17 ? 1 : 0
  let s:Name = toupper(s:name[0]) . s:name[1:]
  call add(s:ops, [s:pre . s:Name . s:post, 0x0391 + s:i + s:skip])
  call add(s:ops, [s:pre . s:name . s:post, 0x03B1 + s:i + s:skip])
  let s:i += 1
endfor

" Type and number-set names. Most want more than one glyph and 'cchar' takes
" one, so the word is cut into as many adjacent pieces as there are glyphs and
" each piece gets its own rule. The glyphs appear in the order the PIECES do,
" not in any order the word implies, so where the cut falls is arbitrary.
"
" Pieces chain with contained + nextgroup. The two obvious alternatives fail:
" \zs moves where a match is reported but not where the engine starts trying
" it, so a second rule still has to begin at a column the first already
" consumed and never fires at all; a lookbehind is correct but drops Vim onto
" its backtracking engine and is then attempted at every column of every line,
" which doubled the buffer's whole syntax cost.
"
" Bool, Type, Prop, Empty and Unit are the supplementary-plane codepoints.
"
" For the first two it is Unicode's history showing through. A scattering of
" mathematical letters went into Letterlike Symbols long before the full
" alphabets arrived at U+1D400, so each alphabet now has holes where its
" earlier spelling already lived, and a letter is in the block or in the hole
" depending only on which side of that split it fell. Double-struck skips
" C H N P Q R Z - which is why every number set above sits under U+FFFF and B
" does not - and script skips B E F H I L M R, which is why List is U+2112 down
" in Letterlike while the script U of Type and Prop is U+1D4B0 up in the
" block.
"
" Empty and Unit have no such history: the double-struck DIGITS at U+1D7D8 are
" a complete run of ten with no earlier spellings and therefore no holes, so
" the cardinality of the type is simply its digit. That is also why they are
" these and not the ASCII 0 and 1 - those would read as numerals rather than
" as the types, next to the ASCII 0 the monoid rows already draw.
"
" nr2char() returns a four-byte single character for all of them, and cchar
" accepts it.
"
" Type and Prop share one letter, the script U, and Prop adds a subscript p.
" Set is deliberately absent. It was drawn with a subscript zero for part of
" 2026-09-18 and removed: Set is also a vernacular COMMAND - `Set Implicit
" Arguments.` - which Coqtail parses with a region starting on the word, and a
" rule here wins that column by definition order and breaks the command. A
" guard refusing a following capitalised word kept the command whole, but the
" word is common enough in both roles that it was not worth carrying.
"
" Prop's subscript p is U+209A, which the symbol font does not carry. It is
" deliberately left out of both font lists: routing it there would draw tofu
" in kitty, where a symbol_map hit is final. Unrouted, both terminals fall back
" to Noto Sans for it, whose subscript sits within 0.02em of the symbol font's
" subscript zero, so it does not look borrowed next to the number sets.
"
" The algebraic structures stretch the same machinery further: a whole
" identifier is drawn as its carrier, operation and unit inside angle
" brackets, which needs five to eight pieces and so that many source
" characters to hang them on. Only the brackets and the carrier come from the
" symbol font; the comma, `+` and `0` are the ASCII the surrounding text is
" already drawn in.
"
" The product projections and the sum injections are here rather than among
" the Greek rows because each needs a second glyph for its subscript. They
" cannot collide with the plain `pi` and `iota` rows that the Greek loop
" generates: those rows' trailing guard refuses the `_` following them here,
" the same way `Bool` steps aside for the monoids. Their subscripts are the
" only two codepoints in the table that no single-glyph row uses.
"
" `List` is the type constructor and is drawn as the bare script L, with its
" parameter left standing beside it as written: `List Nat` reads as the script
" L followed by Nat's own symbol. Drawing the parameter inside brackets was
" tried and dropped - a literal `A` there cannot follow the real argument, and
" following it is not reachable anyway, since the closing bracket would need a
" source character AFTER the argument to hang on.
"
" These cannot collide with the plain rows above even though each shares its
" first characters with one: `Bool`, `Nat` and `NatWithZero` all have a
" trailing guard that refuses the `_` following them here, so none of those
" rows matches in the first place.
"
"          word, cut into pieces            one codepoint per piece
let s:sets = [
      \ [['Bool'],                         [0x1D539]],
      \ [['List'],                         [0x2112]],
      \ [['Empty'],                        [0x1D7D8]],
      \ [['Unit'],                         [0x1D7D9]],
      \ [['Type'],                         [0x1D4B0]],
      \ [['Pro', 'p'],                     [0x1D4B0, 0x209A]],
      \ [['pi', '_1'],                     [0x03C0, 0x2081]],
      \ [['pi', '_2'],                     [0x03C0, 0x2082]],
      \ [['iota', '_1'],                   [0x03B9, 0x2081]],
      \ [['iota', '_2'],                   [0x03B9, 0x2082]],
      \ [['Nat'],                          [0x2115]],
      \ [['NatWithZer', 'o'],              [0x2115, 0x2080]],
      \ [['Integer'],                      [0x2124]],
      \ [['PosInteg', 'er'],               [0x2124, 0x207A]],
      \ [['NegInteg', 'er'],               [0x2124, 0x207B]],
      \ [['NonNegInte', 'g', 'er'],        [0x2124, 0x207A, 0x2080]],
      \ [['Rational'],                     [0x211A]],
      \ [['PosRation', 'al'],              [0x211A, 0x207A]],
      \ [['NegRation', 'al'],              [0x211A, 0x207B]],
      \ [['Complex'],                      [0x2102]],
      \ [['Real'],                         [0x211D]],
      \ [['PosRe', 'al'],                  [0x211D, 0x207A]],
      \ [['NegRe', 'al'],                  [0x211D, 0x207B]],
      \
      \ [['B', 'o', 'o', 'l', '_', 'a', 'n', 'd_monoid'],
      \  [0x27E8, 0x1D539, 0x2C, 0x26, 0x26, 0x2C, 0x22A4, 0x27E9]],
      \ [['B', 'o', 'o', 'l', '_', 'o', 'r', '_monoid'],
      \  [0x27E8, 0x1D539, 0x2C, 0x7C, 0x7C, 0x2C, 0x22A5, 0x27E9]],
      \ [['B', 'o', 'o', 'l', '_', 'x', 'or_monoid'],
      \  [0x27E8, 0x1D539, 0x2C, 0x2295, 0x2C, 0x22A5, 0x27E9]],
      \ [['N', 'a', 't', 'W', 'i', 't', 'h', 'Zero_add_monoid'],
      \  [0x27E8, 0x2115, 0x2080, 0x2C, 0x2B, 0x2C, 0x30, 0x27E9]],
      \ [['N', 'a', 't', '_', 'add_semigroup'],
      \  [0x27E8, 0x2115, 0x2C, 0x2B, 0x27E9]],
      \ ]

" Emitted back to front so every nextgroup target exists before it is named,
" and numbered per set so two sets sharing a chunk spelling - "al" ends both
" PosRational and PosReal - cannot chain into each other's tail. Piece one
" carries both guards and, through \ze, requires the rest of the word to
" follow, which is what leaves the later pieces nothing to re-check.
let s:s = 0
for [s:chunks, s:codes] in s:sets
  let s:s += 1
  let s:k = len(s:chunks) - 1
  while s:k >= 0
    let s:after = join(s:chunks[s:k + 1 :], '')

    if s:k == 0
      let s:pat = s:pre . s:chunks[0]
      let s:opts = 'containedin=ALL'
    else
      let s:pat = s:chunks[s:k]
      let s:opts = 'contained'
    endif

    if s:after !=# ''
      let s:pat .= '\ze' . s:after
      let s:opts .= printf(' nextgroup=rocqNumSet%d_%d', s:s, s:k + 1)
    endif
    if s:k == 0
      let s:pat .= s:setpost
    endif

    execute printf('syntax match rocqNumSet%d_%d "%s" conceal %s cchar=%s',
          \ s:s, s:k, s:pat, s:opts, nr2char(s:codes[s:k]))
    let s:k -= 1
  endwhile
endfor

let s:n = 0
for [s:word, s:code] in s:words
  let s:n += 1
  execute 'syntax keyword rocqConcealed' . s:n . ' ' . s:word
        \ . ' conceal containedin=ALL cchar=' . nr2char(s:code)
endfor

for [s:pattern, s:code] in s:ops
  let s:n += 1
  execute 'syntax match rocqConcealed' . s:n . ' "' . s:pattern
        \ . '" conceal containedin=ALL cchar=' . nr2char(s:code)
endfor

unlet! s:words s:ops s:n s:word s:pattern s:code
unlet! s:pre s:post s:setpost s:greek s:i s:skip s:name s:Name
unlet! s:sets s:chunks s:codes s:s s:k s:after s:pat s:opts

" One correction to Coqtail's parsing rather than an addition to it.
"
" Rocq lets a class field be written `field :: T`, which declares it an
" instance as well as a projection. Coqtail predates that form: its
" coqRecField region ends on a single colon, so the first colon closes the
" region as coqVernacPunctuation and the second falls through to the term
" inside as coqTermPunctuation. One token, drawn in two different colours.
"
" The two regions below are Coqtail's own, at syntax/coq.vim:385-386, with two
" changes. The end pattern is widened to take both colons, ordered longest
" first so a single colon parses exactly as it did. And the end carries
" `matchgroup=NONE`, which is what lets the conceal rule reach it: a region's
" end match accepts no contained items while a matchgroup is set on it, and
" that is the whole reason `::` drew nothing here before.
"
" The cost of matchgroup=NONE is that an unconcealed colon takes the region's
" own colour instead of coqVernacPunctuation. That is why coqRecField is
" linked to it below - the colour is preserved by naming it rather than by
" the matchgroup.
"
" This file is also sourced for the Info and Goal panels. The Info panel's
" syntax carries the same two regions word for word (coq-infos.vim:122-123),
" so the correction applies there as well; the Goal panel's has no records at
" all, and `syntax clear` on a group it has never defined fails with E28.
if index(['coq', 'coq-infos'], get(b:, 'current_syntax', '')) >= 0
  syntax clear coqRecField
  syntax region coqRecField contained contains=coqField keepend
        \ matchgroup=coqVernacPunctuation start="{" matchgroup=NONE end="::\|:"
  syntax region coqRecField contained contains=coqField keepend
        \ matchgroup=coqVernacPunctuation start=";" matchgroup=NONE end="::\|:"
  highlight! link coqRecField coqVernacPunctuation
endif

" The second correction, and the same shape of problem in a different place.
"
" Coqtail matches its operators with one long alternation of single and double
" characters (syntax/coq.vim:75). `-/>` is in none of its branches, so the
" three characters are drawn as three runs: `-` and `>` each match the `-` and
" `>` branches as coqKwd, and the slash between them is in no branch at all
" and falls through to whatever region encloses it. One operator, two colours,
" split down the middle.
"
" One match over the whole spelling replaces all three. It is a match against
" Coqtail's match, which definition order settles, and an after/syntax file is
" sourced last - the same reason every conceal rule above wins its column.
"
" `Type` because this is a type-level operator: `a -/> b` is the proposition
" that a does not imply b, so it reads as a constructor of propositions rather
" than as punctuation. The link is a `default` one, so naming the group again
" elsewhere overrides it without touching this file.
syntax match rocqNotImplies "-/>" containedin=ALL
highlight default link rocqNotImplies Type
