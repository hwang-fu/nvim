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

" Word-shaped: declared as KEYWORDS so they outrank Coqtail's own. Keywords
" match whole words by 'iskeyword' on their own, so no \< \> is needed - and
" none can be written, because a keyword is a literal word, not a pattern.
" `True` and `False` are the Prop-level constants, not the bool constructors
" `true` and `false`. Coqtail sets `syn case match` (syntax/coq.vim), so these
" keywords are case-sensitive and the lowercase bool values are left alone -
" which is the distinction that matters, since only the capitalised pair are
" propositions and therefore the ones worth drawing as verum and falsum.
let s:words = [
      \ ['forall', 0x2200],
      \ ['exists', 0x2203],
      \ ['True', 0x22A4],
      \ ['False', 0x22A5],
      \ ['fun', 0x03BB],
      \ ]

" Operator-shaped: these have to be MATCHES, because they are not words.
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
let s:ops = [
      \ ['\\/', 0x2228],
      \ ['/\\', 0x2227],
      \ ['\~', 0x00AC],
      \ ['<>', 0x2260],
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
