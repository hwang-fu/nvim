" Symbol concealing for Rocq (2026-09-12, user request).
"
" Renders `forall` as the quantifier glyph and `exists` as its partner, so a
" statement reads closer to how it would be written on paper. Display only:
" 'conceallevel' is a WINDOW option, so the bytes on disk, the buffer, the git
" diff and what Rocq itself reads are all untouched - open the same file in two
" windows with different levels and the text is identical in both.
"
" The replacement characters are built with nr2char() from their codepoints
" rather than typed in literally. That keeps this file pure ASCII, the same way
" the Nerd Font icons elsewhere in this config and the prompt glyphs in
" ~/.bashrc are written as escapes: a codepoint survives an encoding mishap, a
" pasted glyph does not, and grep for U+2200 finds this line.
"
" 'cchar' accepts exactly ONE character, which bounds what can ever go in this
" table: forall -> a single glyph works, and any substitution needing two or
" more characters is not expressible here at all.
"
" Deliberately short. Two entries is enough to find out whether concealing
" suits you before a screenful of symbols has to be unlearned; the cost it
" carries - a concealed word occupies one cell instead of six, so the cursor's
" real column stops matching where it appears - is easiest to judge on a small
" set. Add rows as they earn their place.
"
" The options and the :RocqConceal / :RocqUnconceal commands live in
" after/ftplugin/coq.lua, which is where window options and buffer commands
" belong; this file only defines what a symbol looks like.

" [pattern, codepoint]
let s:symbols = [
      \ ['\<forall\>', 0x2200],
      \ ['\<exists\>', 0x2203],
      \ ]

let s:n = 0
for [s:pattern, s:code] in s:symbols
  let s:n += 1
  execute 'syntax match rocqConcealed' . s:n . ' "' . s:pattern . '" conceal cchar=' . nr2char(s:code)
endfor

unlet! s:symbols s:n s:pattern s:code
