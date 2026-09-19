" The Info panel draws the same symbols as the source buffer; see
" after/syntax/coq-goals.vim for why this sources by path.
execute 'source' fnameescape(expand('<sfile>:p:h') . '/coq.vim')
