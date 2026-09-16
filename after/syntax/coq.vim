" Symbol concealing for Rocq. Display only: 'conceallevel' is a window option,
" so the file on disk, the buffer, grep and the git diff are all untouched.
"
" Replacement characters are built with nr2char() so this file stays pure
" ASCII. The window options and the :RocqConceal / :RocqUnconceal commands are
" in after/ftplugin/coq.lua; docs/keymappings/lsp/rocq.md has the full table
" and the reasoning behind what is in it and what is deliberately not.
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
"   s:pre   not preceded by a dot. A LEADING dot can only be a qualifier
"           separator, so this alone kills `a.True.b` and `Nat.True`.
"   s:post  after the name allow apostrophes, then refuse an identifier
"           character or a dot that starts one. That draws three lines at
"           once: `beta'` is drawn and `beta'x` is not; `beta_conv` and
"           `betax` are not; and a TRAILING dot stays ambiguous as it is in
"           Rocq, where `.` before whitespace ends a sentence - so
"           `Lemma l : True.` is drawn - while `.` before an identifier
"           character separates a qualifier and is not.
"
" s:post needs a lookahead rather than a plain \>, because an apostrophe is in
" 'iskeyword' here and `beta'` is therefore ONE word to Vim. Note the doubled
" apostrophe: in a single-quoted Vim string `''` is one literal apostrophe.
let s:pre = '\%(\.\)\@<!\<'
let s:post = '\%(''*\%(\k\|\.\k\)\@!\)\@='

" Operators and guarded words.
"
" '\\/' is the three characters \ \ / - an escaped backslash then a slash,
" matching Rocq's \/ - and '/\\' the same the other way round. '\~' is escaped
" because a bare ~ in a Vim pattern means the previous substitute string.
" '<>' needs no escaping: it is \< and \> that are the word boundaries.
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
" The cardinals use U+2135-U+2138, the four Hebrew LETTERLIKE SYMBOLS, not the
" Hebrew letters at U+05D0 onward. Those are bidi class R and would reorder the
" line around them, and STIX carries none of them. The block holds exactly four
" - there is no samekh.
let s:ops = [
      \ ['_\\/_', 0x22BB],
      \ ['\%(_\)\@<!\\/', 0x2228],
      \ ['/\\', 0x2227],
      \ ['\~', 0x00AC],
      \ ['<>', 0x2260],
      \ ['||-', 0x22A9],
      \ ['\%(|\)\@<!|-\%(>\)\@!', 0x22A2],
      \ ['|=', 0x22A8],
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
" Bool is the one supplementary-plane codepoint. The double-struck alphabet
" starts at U+1D538 except for C H N P Q R Z, which were encoded earlier in
" Letterlike Symbols and are the holes the other rows fill; B is not one of
" them. nr2char() returns a four-byte single character and cchar accepts it.
"
"          word, cut into pieces            one codepoint per piece
let s:sets = [
      \ [['Bool'],                         [0x1D539]],
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
