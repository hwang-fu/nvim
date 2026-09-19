" The Goal panel draws the same symbols as the source buffer. Coqtail's panel
" syntaxes are files of their own, so the rules have to be brought in here.
" Sourced by path rather than with :runtime, which would also pull in
" Coqtail's syntax/coq.vim - the whole source-file grammar - on top of the
" panel's own. Window options are set by lua/jwa/rocq_panels.lua.
execute 'source' fnameescape(expand('<sfile>:p:h') . '/coq.vim')
