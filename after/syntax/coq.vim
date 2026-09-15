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
let s:ops = [
      \ ['\\/', 0x2228],
      \ ['/\\', 0x2227],
      \ ['\~', 0x00AC],
      \ ['<>', 0x2260],
      \ ['\%(\.\)\@<!\<True\>\%(\.\k\)\@!', 0x22A4],
      \ ['\%(\.\)\@<!\<False\>\%(\.\k\)\@!', 0x22A5],
      \ ]

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
