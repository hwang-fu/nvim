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
" The two guards, and why they are not symmetric:
"   \%(\.\)\@<!   not preceded by a dot. A leading dot is unambiguous - it can
"                 only be a qualifier separator - so this alone kills
"                 `a.True.b` and `Nat.True`.
"   \%(\.\k\)\@!  not followed by a dot that itself starts an identifier. A
"                 TRAILING dot is ambiguous in Rocq: `.` before whitespace or
"                 end of line ends a sentence, and `Lemma l : True.` must still
"                 be drawn, while `.` before an identifier character separates
"                 a qualifier and must not. The lookahead draws exactly that
"                 line.
"
" Nothing has to be done about case: Coqtail sets `syn case match`
" (syntax/coq.vim), so these never touch the bool constructors `true` and
" `false`. That distinction is the point - only the capitalised pair are
" propositions, and so only they are worth drawing as verum and falsum.
let s:pre = '\%(\.\)\@<!\<'
let s:post = '\>\%(\.\k\)\@!'

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
let s:ops = [
      \ ['\\/', 0x2228],
      \ ['/\\', 0x2227],
      \ ['\~', 0x00AC],
      \ ['<>', 0x2260],
      \ ['||-', 0x22A9],
      \ ['\%(|\)\@<!|-', 0x22A2],
      \ ['|=', 0x22A8],
      \ [s:pre . 'True' . s:post, 0x22A4],
      \ [s:pre . 'False' . s:post, 0x22A5],
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
" `Setoid.gamma` must stay as written. Identifiers that merely contain a letter
" name are safe without any help - 'iskeyword' here is `@,48-57,192-255,_,'`,
" so `alpha_conv`, `beta'` and `gamma1` are each a single word and \< \> never
" splits them.
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
