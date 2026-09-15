" Symbol concealing for Rocq (2026-09-12; fixed and extended 2026-09-13).
"
" Renders the quantifiers and the two logical connectives as the glyphs they
" would be written with on paper. Display only: 'conceallevel' is a WINDOW
" option, so the bytes on disk, the buffer, the git diff and what Rocq itself
" reads are all untouched - open the same file in two windows with different
" levels and the text is identical in both.
"
" The replacement characters are built with nr2char() from their codepoints
" rather than typed in literally. That keeps this file pure ASCII, the same way
" the Nerd Font icons elsewhere in this config and the prompt glyphs in
" ~/.bashrc are written as escapes: a codepoint survives an encoding mishap, a
" pasted glyph does not, and grep for U+2200 finds this line.
"
" 'cchar' accepts exactly ONE character, which bounds what can ever go in these
" tables: forall -> a single glyph works, and any substitution needing two or
" more characters is not expressible here at all.
"
" The options and the :RocqConceal / :RocqUnconceal commands live in
" after/ftplugin/coq.lua, which is where window options and buffer commands
" belong; this file only defines what a symbol looks like.
"
" ----------------------------------------------------------------------------
" Why there are two tables, and why every rule carries containedin=ALL.
"
" The first version of this file (2026-09-12) defined plain top-level matches
" and concealed NOTHING - the rules were created, they showed up in :syntax
" list, and they were dead. Two separate rules of Vim's syntax engine were in
" the way, and each needs its own answer.
"
"   1. A region only ever matches the items named in its own `contains=`.
"      Coqtail wraps essentially every interesting position in one: a `forall`
"      inside a theorem statement sits under coqThm > coqThmName > coqThmTerm,
"      whose contains list names Coqtail's own groups and nothing else, so a
"      top-level item is never offered the position at all. `containedin=ALL`
"      says "this item may begin inside any other item", which puts it back in
"      the running. It is load-bearing on every line below.
"
"   2. Keywords outrank matches, whatever the definition order. Where two
"      MATCHES overlap, the last defined wins - and an after/syntax file is
"      sourced after the syntax file it augments (:scriptnames shows Coqtail's
"      coq.vim, then this one), so a match here beats Coqtail's coqKwd match.
"      That is enough for `exists`, `\/` and `/\`. It is NOT enough for
"      `forall`, which Coqtail defines with `syn keyword` (syntax/coq.vim):
"      a keyword beats any match no matter who was defined last. The only
"      thing that outranks a keyword is another keyword, so the word-shaped
"      substitutions are declared with :syn keyword and the operator-shaped
"      ones with :syn match.
" ----------------------------------------------------------------------------

" Declared as KEYWORDS so they outrank Coqtail's own, which is the only thing
" that can. Keywords match whole words by 'iskeyword' on their own, so no
" \< \> is needed - and none can be written, because a keyword is a literal
" word, not a pattern.
"
" Only the two quantifiers are here, and the reason the constants are not is
" below. These two are safe as bare words because both are RESERVED in Rocq:
" neither can be a module name, so neither can turn up as a component of a
" qualified name the way an ordinary identifier can.
"
" `fun` is deliberately absent. It was drawn as a lambda here between
" 2026-09-13 and 2026-09-15 and taken back out; OCaml still does it, in
" after/ftplugin/ocaml.lua.
let s:words = [
      \ ['forall', 0x2200],
      \ ['exists', 0x2203],
      \ ]

" Everything that needs a pattern: the operators, which are not words at all,
" and the two Prop constants, which are words but need a guard.
"
" The patterns read oddly because Vim's regex escape is the same character
" Rocq uses in the operators themselves. In a single-quoted Vim string a
" backslash is literal, so '\\/' is the three characters \ \ / - a regex
" meaning "an escaped backslash, then a slash", which matches Rocq's \/ - and
" '/\\' matches /\ the same way round.
"
" '\~' is escaped for a different reason: a bare ~ in a Vim pattern means "the
" previous substitute string", not a tilde, so matching Rocq's negation needs
" the backslash.
" '<>' needs no escaping at all: < and > are literal in a Vim pattern, and it
" is \< and \> that are the word boundaries. It matches only a < with a >
" immediately after it, so the neighbouring operators '<=' and '<->' are
" untouched - both are deliberately absent and keep their ASCII, '<->' having
" been tried as U+27F7 and dropped on 2026-09-13.
" U+2228 and U+2227 are the BINARY connectives, which is what Rocq's \/ and /\
" are. The n-ary forms U+22C1 and U+22C0 were used first and swapped out on
" 2026-09-13: they are the large operators for taking a disjunction over a
" family, and almost no monospaced font carries them - of everything installed
" on this machine only Iosevka and FreeMono did, while the binary pair is in
" DejaVu, JetBrains Mono, Fira Code and Noto Sans Mono as well. Correct symbol
" and a far wider choice of font, so there was nothing to trade off.
"
" `True` and `False` are matches rather than keywords because a keyword cannot
" carry a guard, and they need one. Unlike the quantifiers they are ordinary
" identifiers - Coq.Init.Logic.True - so they turn up inside QUALIFIED NAMES,
" and `a.True.b` was being drawn as `a.verum.b` (reported 2026-09-15). A dot is
" not in 'iskeyword', so to Vim the `True` in `a.True.b` is a whole word and a
" keyword matched it happily.
"
" The two guards, and why they are not symmetric.
"
" LEADING - `\%(\.\)\@<!\<` - the name must start a word and must not be
" preceded by a dot. A leading dot is unambiguous: it can only be a qualifier
" separator, so this alone kills `a.True.b` and `Nat.True`.
"
" TRAILING - `\%('*\%(\k\|\.\k\)\@!\)\@=` - after the name, allow any number of
" apostrophes, then require that what follows is neither an identifier
" character nor a dot that itself starts an identifier. Three separate things
" are being said at once:
"
"   * `beta'` and `beta''` ARE drawn (2026-09-15, user request), as the letter
"     followed by the apostrophes: only the name is matched, so only the name
"     is replaced. This is the whole reason the guard is a lookahead and not
"     the plain `\>` it used to be - an apostrophe is in 'iskeyword' here, so
"     `beta'` is ONE word and `\>` refused it.
"   * `beta'x` is NOT drawn. The apostrophes must end the identifier. A name
"     like `beta'x` is its own thing rather than a derived `beta`, and reading
"     it as one would be wrong; the negative lookahead after `'*` is what draws
"     that line. `beta_conv`, `beta1` and `betax` fall out the same way.
"   * A TRAILING dot stays ambiguous in Rocq and has to be treated as such:
"     `.` before whitespace or end of line ends a sentence, so
"     `Lemma l : True.` must still be drawn, while `.` before an identifier
"     character separates a qualifier and must not. Hence `\.\k` rather than
"     a bare `\.`.
"
" Note the doubled apostrophe in the string below: inside a single-quoted Vim
" string `''` is one literal apostrophe, so `''*` is the regex `'*`.
"
" Nothing has to be done about case: Coqtail sets `syn case match`
" (syntax/coq.vim), so these never touch the bool constructors `true` and
" `false`. That distinction is the point - only the capitalised pair are
" propositions, and so only they are worth drawing as verum and falsum.
"
" The cardinals (2026-09-16, user request) ride on exactly the same two guards,
" being ordinary identifiers like the constants above rather than reserved
" words. Only the capitalised spellings are drawn, again because
" `syn case match` is in force - a variable named `alef` is left alone.
"
" The codepoints are U+2135-U+2138, the four HEBREW LETTERLIKE SYMBOLS from the
" Letterlike Symbols block, NOT the Hebrew letters themselves at U+05D0-U+05D3.
" They look nearly identical and are not interchangeable here, for two reasons
" that both matter in a terminal:
"
"   * Bidirectionality. The letterlike symbols are bidi class L; the Hebrew
"     letters are class R, and a right-to-left character dropped into a line of
"     left-to-right code makes the surrounding text reorder itself on screen.
"   * Fonts. STIX Two Math carries all four letterlike symbols and none of the
"     Hebrew letters, so the Hebrew spellings would fall out of the symbol
"     routing set up for everything else and land in whatever Hebrew-capable
"     font fontconfig reaches for.
"
" That block holds exactly four: alef, bet, gimel and dalet. There is no
" samekh - U+2139 is the information source sign - so a `Samech` rule could
" only use the Hebrew letter and would carry both problems above.
let s:pre = '\%(\.\)\@<!\<'
let s:post = '\%(''*\%(\k\|\.\k\)\@!\)\@='

" The three turnstiles (2026-09-15, user request): |- entails, |= models, and
" ||- forces. A bar is literal in a Vim pattern - it is \| that means
" alternation - so none of the three needs escaping.
"
" `||-` CONTAINS `|-`, and that overlap is worth being explicit about because
" the usual tie-break does not apply to it. Vim settles two matches that begin
" at the SAME column by taking the last defined; these begin one column apart,
" so that rule never comes into play. What actually decides it is that scanning
" runs left to right: at the first bar only `||-` can match, it consumes all
" three characters, and scanning resumes past them, so the `|-` inside is never
" reached.
"
" That is already right, and the lookbehind on `|-` is here anyway. It costs
" nothing, and it makes the outcome independent of the order of this list and
" of whatever a later rule might do to the scan - without it, a `|-` reached at
" the SECOND bar of `||-` would draw a bar followed by a right tack instead of
" the single forces sign.
"
" `|-` also refuses a FOLLOWING `>`, which is about `|->` rather than about any
" rule here: `->`, `<->`, `=>` and `|->` were all drawn as arrows on 2026-09-16
" and taken back out the same day (user request). With them gone the guard
" still earns its place, because without it `|->` would come out as a right
" tack followed by a bare `>` - half substituted, which is worse than the plain
" ASCII it now stays as.
"
" `:=` is deliberately ABSENT, and the reason is worth recording so it is not
" tried a third time. It was added on 2026-09-16 and removed the same day,
" because it can only ever be drawn in HALF the places it appears. The `:=`
" that opens a definition body is not an ordinary token: it is the start match
" of a region, reached through `nextgroup` -
"
"     coqDef ... nextgroup=coqDefContents1                 (syntax/coq.vim:345)
"     coqDefContents1 ... matchgroup=... start=":="        (syntax/coq.vim:348)
"
" - and a nextgroup target is forced rather than competed for, so a rule here
" is never offered the column, exactly as with the \zs problem solved for the
" number sets above. Coqtail has at least eleven such regions: Definition,
" Instance, Fixpoint, Ltac, Notation, Module, Obligation, Coercion, Inductive
" and more. A `:=` in ordinary term position DID conceal, which is the worst
" of both: the most common occurrence stayed ASCII while the rarer one became
" a symbol. Uniform ASCII beats that. Getting it would mean redefining those
" eleven regions here, forking Coqtail's syntax file in all but name.
let s:ops = [
      \ ['\\/', 0x2228],
      \ ['/\\', 0x2227],
      \ ['\~', 0x00AC],
      \ ['<>', 0x2260],
      \ ['||-', 0x22A9],
      \ ['\%(|\)\@<!|-\%(>\)\@!', 0x22A2],
      \ ['|=', 0x22A8],
      \ [s:pre . 'True' . s:post, 0x22A4],
      \ [s:pre . 'False' . s:post, 0x22A5],
      \ [s:pre . 'Alef' . s:post, 0x2135],
      \ [s:pre . 'Bet' . s:post, 0x2136],
      \ [s:pre . 'Gimel' . s:post, 0x2137],
      \ [s:pre . 'Dalet' . s:post, 0x2138],
      \ ]

" The 24 Greek letters, both cases (2026-09-15, user request): `alpha` is drawn
" as the small letter and `Alpha` as the capital, and so on through `omega`.
"
" Generated rather than listed, because forty-eight literal rows would be a
" transcription exercise with forty-eight chances to put a codepoint one off.
" Both Greek blocks run in the order below, so the codepoint is the index.
"
" The one irregularity is the pair of holes at sigma. U+03A2 is unassigned, and
" U+03C2 is FINAL sigma - the form Greek uses at the end of a word, which is
" not what a mathematical sigma means. Both blocks therefore shift by one from
" index 17 onward, and both shift at the same index, so a single correction
" covers the two of them.
"
" They carry the same guard as True and False, and for the same reason: unlike
" the reserved quantifiers these are ordinary identifiers, so `M.alpha` and
" `Setoid.gamma` must stay as written, while `alpha_conv`, `gamma1` and
" `alphabet` are names in their own right and are left alone. `beta'` and
" `beta''` are the one shape that IS drawn, as the letter plus its apostrophes;
" see the guard above for why that needed a lookahead rather than `\>`.
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

" ----------------------------------------------------------------------------
" The number sets (2026-09-16, user request): Nat as the double-struck N,
" PosInteger as Z with a superscript plus, and so on.
"
" Eight of the thirteen want TWO OR THREE glyphs, and 'cchar' accepts exactly
" one. The way round it is to stop thinking of a rule as covering a word: cut
" the word into as many adjacent pieces as there are glyphs, and give each
" piece its own one-character rule. Vim draws one cchar per concealed region,
" and neighbouring regions from different groups stay separate, so the pieces
" come out side by side. Where the cut falls is arbitrary - the glyphs appear
" in the order the pieces do, not in any order the word implies - so the
" tables below cut wherever leaves a readable pair of chunks.
"
" The pieces are chained with `contained` + `nextgroup`, which is the mechanism
" Vim has for exactly this and is worth arriving at deliberately, because the
" two obvious alternatives both fail:
"
"   \zs does not work at all. It moves where a match is REPORTED, not where
"   the engine starts trying it, so a second rule written `\<PosInteg\zser`
"   still has to begin matching at the P - a column the first rule has already
"   consumed. It never fires and only the leading glyph appears.
"
"   A look-behind works but is expensive. `\%(\<PosInteg\)\@<=er` does begin
"   matching at the e and is correct, but any \@<= drops Vim onto its
"   backtracking engine, and the rule is then attempted at every column of
"   every line whether or not it can match: measured at 13 microseconds a call
"   against 1 for a plain word rule, which doubled the whole buffer's syntax
"   cost. Bounding the look-behind with \@N<= changed nothing, so the cost is
"   the engine choice and not the scan distance.
"
" `contained` + `nextgroup` has neither problem: a contained item is never
" tried on its own, and nextgroup offers it only at the column where the
" previous piece ended. It also makes the guards unnecessary on every piece
" but the first - piece one already requires the whole word and its trailing
" guard through \ze, so by the time piece two is offered, `M.PosInteger` and
" `PosIntegerX` have both already been refused.
"
" Substring collisions need no special handling, which is worth stating
" because it looks like they should. `Integer` inside `PosInteger` is not
" matched, since \< finds no word boundary after the s; `Nat` inside
" `NatWithZero` is not matched, since the trailing guard rejects the W that
" follows. Both fall out of guards that are there for other reasons.
"
"          word, cut into pieces            one codepoint per piece
let s:sets = [
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
      \ ]

" Emitted back to front so every nextgroup target exists before it is named,
" and numbered per set so two sets that share a chunk spelling - "al" ends
" both PosRational and PosReal - can never chain into each other's tail.
let s:s = 0
for [s:chunks, s:codes] in s:sets
  let s:s += 1
  let s:k = len(s:chunks) - 1
  while s:k >= 0
    let s:after = join(s:chunks[s:k + 1 :], '')

    if s:k == 0
      " Piece one carries both guards, and through \ze it also requires the
      " rest of the word and the trailing guard to follow. Everything the
      " later pieces would otherwise have to re-check is settled right here.
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
      let s:pat .= s:post
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
unlet! s:pre s:post s:greek s:i s:skip s:name s:Name
unlet! s:sets s:chunks s:codes s:s s:k s:after s:pat s:opts
