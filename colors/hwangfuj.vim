" File  : simplicity-blue-refined.vim
" Based on: simplicity-blue.vim by Matthieu Petiteau
" Modified: A refined minimalist colorscheme with subtle syntax highlighting
"
" Palette (minimalist - 3 tones + bold):
"   - Background: deep blue #00005f
"   - Normal:     white #eeeeee
"   - Keywords:   yellow #ffd700 (bold)
"   - Constants:  grey #8a8a8a (bold) - strings, numbers, booleans
"   - Comments:   grey #8a8a8a (normal)
"

hi clear

if exists("syntax on")
  syntax reset
endif

let g:colors_name="simplicity-blue-refined"
set background=dark

" ==============================================================================
" Core
" ==============================================================================
hi Normal              ctermfg=255  ctermbg=17   cterm=NONE       guifg=#eeeeee  guibg=#00005f  gui=NONE
" ctermfg=250 guifg=#bcbcbc

" ==============================================================================
" Comments - no effects
" ==============================================================================
hi Comment             ctermfg=172  ctermbg=NONE cterm=NONE       guifg=#cc8c3c  guibg=NONE     gui=NONE
" ctermfg=172 guifg=#cc8c3c

" ==============================================================================
" UI Elements
" ==============================================================================
hi LineNr              ctermfg=240  ctermbg=NONE cterm=NONE       guifg=#585858  guibg=NONE     gui=NONE
hi CursorLineNR        ctermfg=251  ctermbg=NONE cterm=bold       guifg=#c6c6c6  guibg=NONE     gui=bold
hi NonText             ctermfg=238  ctermbg=NONE cterm=NONE       guifg=#444444  guibg=NONE     gui=NONE

hi Statusline          ctermfg=17   ctermbg=251  cterm=bold       guifg=#00005f  guibg=#c6c6c6  gui=bold
hi StatuslineNC        ctermfg=17   ctermbg=240  cterm=NONE       guifg=#00005f  guibg=#585858  gui=NONE
hi Visual              ctermfg=NONE ctermbg=24   cterm=NONE       guifg=NONE     guibg=#005f87  gui=NONE

hi Cursor              ctermfg=17   ctermbg=255  cterm=NONE       guifg=#00005f  guibg=#eeeeee  gui=NONE
hi CursorColumn        ctermfg=NONE ctermbg=18   cterm=NONE       guifg=NONE     guibg=#000087  gui=NONE
hi CursorLine          ctermfg=NONE ctermbg=18   cterm=NONE       guifg=NONE     guibg=#000087  gui=NONE

hi VertSplit           ctermfg=240  ctermbg=NONE cterm=NONE       guifg=#585858  guibg=NONE     gui=NONE
hi SignColumn          ctermfg=245  ctermbg=NONE cterm=NONE       guifg=#8a8a8a  guibg=NONE     gui=NONE
hi ColorColumn         ctermfg=NONE ctermbg=18   cterm=NONE       guifg=NONE     guibg=#000087  gui=NONE

" ==============================================================================
" Search & Match
" ==============================================================================
hi MatchParen          ctermfg=222  ctermbg=NONE cterm=bold,underline  guifg=#ffd787  guibg=NONE  gui=bold,underline
hi Search              ctermfg=17   ctermbg=222  cterm=NONE       guifg=#00005f  guibg=#ffd787  gui=NONE
hi IncSearch           ctermfg=17   ctermbg=117  cterm=bold       guifg=#00005f  guibg=#87d7ff  gui=bold

" ==============================================================================
" Diff
" ==============================================================================
hi DiffAdd             ctermfg=255  ctermbg=22   cterm=NONE       guifg=#eeeeee  guibg=#005f00  gui=NONE
hi DiffChange          ctermfg=222  ctermbg=NONE cterm=NONE       guifg=#ffd787  guibg=NONE     gui=NONE
hi DiffText            ctermfg=17   ctermbg=222  cterm=NONE       guifg=#00005f  guibg=#ffd787  gui=NONE
hi DiffDelete          ctermfg=255  ctermbg=88   cterm=NONE       guifg=#eeeeee  guibg=#870000  gui=NONE

" ==============================================================================
" Popup Menu
" ==============================================================================
hi Pmenu               ctermfg=255  ctermbg=18   cterm=NONE       guifg=#eeeeee  guibg=#000087  gui=NONE
hi PmenuSel            ctermfg=17   ctermbg=117  cterm=bold       guifg=#00005f  guibg=#87d7ff  gui=bold
hi PmenuSbar           ctermfg=NONE ctermbg=19   cterm=NONE       guifg=NONE     guibg=#0000af  gui=NONE
hi PmenuThumb          ctermfg=NONE ctermbg=117  cterm=NONE       guifg=NONE     guibg=#87d7ff  gui=NONE

" ==============================================================================
" Fold & Spell
" ==============================================================================
hi Folded              ctermfg=245  ctermbg=18   cterm=NONE       guifg=#8a8a8a  guibg=#000087  gui=NONE
hi FoldColumn          ctermfg=245  ctermbg=NONE cterm=NONE       guifg=#8a8a8a  guibg=NONE     gui=NONE

hi SpellBad            ctermfg=203  ctermbg=NONE cterm=underline  guifg=#ff5f5f  guibg=NONE     gui=undercurl
hi SpellCap            ctermfg=117  ctermbg=NONE cterm=underline  guifg=#87d7ff  guibg=NONE     gui=undercurl
hi SpellRare           ctermfg=222  ctermbg=NONE cterm=underline  guifg=#ffd787  guibg=NONE     gui=undercurl
hi SpellLocal          ctermfg=117  ctermbg=NONE cterm=underline  guifg=#87d7ff  guibg=NONE     gui=undercurl

" ==============================================================================
" Messages
" ==============================================================================
hi TODO                ctermfg=220  ctermbg=NONE cterm=bold       guifg=#ffd700  guibg=NONE     gui=bold
hi Error               ctermfg=203  ctermbg=NONE cterm=bold       guifg=#ff5f5f  guibg=NONE     gui=bold
hi ErrorMsg            ctermfg=203  ctermbg=NONE cterm=bold       guifg=#ff5f5f  guibg=NONE     gui=bold
hi WarningMsg          ctermfg=220  ctermbg=NONE cterm=NONE       guifg=#ffd700  guibg=NONE     gui=NONE
hi MoreMsg             ctermfg=117  ctermbg=NONE cterm=NONE       guifg=#87d7ff  guibg=NONE     gui=NONE
hi ModeMsg             ctermfg=255  ctermbg=NONE cterm=bold       guifg=#eeeeee  guibg=NONE     gui=bold
hi Question            ctermfg=117  ctermbg=NONE cterm=NONE       guifg=#87d7ff  guibg=NONE     gui=NONE

" ==============================================================================
" Directory & netrw
" ==============================================================================
hi Directory           ctermfg=117  ctermbg=NONE cterm=NONE       guifg=#87d7ff  guibg=NONE     gui=NONE
hi netrwDir            ctermfg=117  ctermbg=NONE cterm=NONE       guifg=#87d7ff  guibg=NONE     gui=NONE

" ==============================================================================
" Git Gutter
" ==============================================================================
hi GitGutterAdd        ctermfg=114  ctermbg=NONE cterm=NONE       guifg=#87d787  guibg=NONE     gui=NONE
hi GitGutterChange     ctermfg=222  ctermbg=NONE cterm=NONE       guifg=#ffd787  guibg=NONE     gui=NONE
hi GitGutterDelete     ctermfg=203  ctermbg=NONE cterm=NONE       guifg=#ff5f5f  guibg=NONE     gui=NONE

" ==============================================================================
" Syntax Highlighting - Minimalist Approach
" ==============================================================================

" Keywords & Statements - bold yellow for emphasis
hi Statement           ctermfg=227  ctermbg=NONE cterm=bold       guifg=#ffff60  guibg=NONE     gui=bold
hi Conditional         ctermfg=227  ctermbg=NONE cterm=bold       guifg=#ffff60  guibg=NONE     gui=bold
hi Repeat              ctermfg=227  ctermbg=NONE cterm=bold       guifg=#ffff60  guibg=NONE     gui=bold
hi Keyword             ctermfg=227  ctermbg=NONE cterm=bold       guifg=#ffff60  guibg=NONE     gui=bold
hi Exception           ctermfg=227  ctermbg=NONE cterm=bold       guifg=#ffff60  guibg=NONE     gui=bold
hi Label               ctermfg=227  ctermbg=NONE cterm=bold       guifg=#ffff60  guibg=NONE     gui=bold
" ctermfg=227 guifg=#ffff60

" Strings
hi String              ctermfg=70  ctermbg=NONE cterm=none       guifg=#73c936  guibg=NONE     gui=none
hi Character           ctermfg=70  ctermbg=NONE cterm=none       guifg=#73c936  guibg=NONE     gui=none
" ctermfg=70 guifg=#73c936

" Numbers & Constants
hi Number              ctermfg=217  ctermbg=NONE cterm=none       guifg=#ffa0a0  guibg=NONE     gui=none
hi Float               ctermfg=217  ctermbg=NONE cterm=none       guifg=#ffa0a0  guibg=NONE     gui=none
hi Boolean             ctermfg=217  ctermbg=NONE cterm=none       guifg=#ffa0a0  guibg=NONE     gui=none
hi Constant            ctermfg=217  ctermbg=NONE cterm=none       guifg=#ffa0a0  guibg=NONE     gui=none
" ctermfg=217 guifg=#ffa0a0

" Functions - slightly brighter, no bold to keep it calm
hi Function            ctermfg=250  ctermbg=NONE cterm=bold       guifg=#eeeeee  guibg=NONE     gui=bold

" Types
hi Type                ctermfg=220  ctermbg=NONE cterm=bold       guifg=#ffd700  guibg=NONE     gui=bold
hi StorageClass        ctermfg=220  ctermbg=NONE cterm=bold       guifg=#ffd700  guibg=NONE     gui=bold
hi Structure           ctermfg=220  ctermbg=NONE cterm=bold       guifg=#ffd700  guibg=NONE     gui=bold
hi Typedef             ctermfg=220  ctermbg=NONE cterm=bold       guifg=#ffd700  guibg=NONE     gui=bold
" ctermfg=220 guifg=#ffd700

" Identifiers - normal
hi Identifier          ctermfg=255  ctermbg=NONE cterm=NONE       guifg=#eeeeee  guibg=NONE     gui=NONE

" Preprocessor - subtle grey
hi PreProc             ctermfg=249  ctermbg=NONE cterm=NONE       guifg=#b2b2b2  guibg=NONE     gui=NONE
hi Include             ctermfg=249  ctermbg=NONE cterm=NONE       guifg=#b2b2b2  guibg=NONE     gui=NONE
hi Define              ctermfg=249  ctermbg=NONE cterm=NONE       guifg=#b2b2b2  guibg=NONE     gui=NONE
hi Macro               ctermfg=249  ctermbg=NONE cterm=NONE       guifg=#b2b2b2  guibg=NONE     gui=NONE
hi PreCondit           ctermfg=249  ctermbg=NONE cterm=NONE       guifg=#b2b2b2  guibg=NONE     gui=NONE

" Special
hi Special             ctermfg=217  ctermbg=NONE cterm=none       guifg=#ffa0a0  guibg=NONE     gui=none
hi SpecialChar         ctermfg=217  ctermbg=NONE cterm=none       guifg=#ffa0a0  guibg=NONE     gui=none
hi SpecialKey          ctermfg=240  ctermbg=NONE cterm=NONE       guifg=#585858  guibg=NONE     gui=NONE
hi SpecialComment      ctermfg=217  ctermbg=NONE cterm=NONE       guifg=#ffa0a0  guibg=NONE     gui=NONE

" Operators - normal, keep it clean
hi Operator            ctermfg=255  ctermbg=NONE cterm=NONE       guifg=#eeeeee  guibg=NONE     gui=NONE
hi Delimiter           ctermfg=255  ctermbg=NONE cterm=NONE       guifg=#eeeeee  guibg=NONE     gui=NONE

" Titles - bold
hi Title               ctermfg=255  ctermbg=NONE cterm=bold       guifg=#eeeeee  guibg=NONE     gui=bold

" Others - keep minimal
hi Conceal             ctermfg=240  ctermbg=NONE cterm=NONE       guifg=#585858  guibg=NONE     gui=NONE
hi Debug               ctermfg=203  ctermbg=NONE cterm=NONE       guifg=#ff5f5f  guibg=NONE     gui=NONE
hi Ignore              ctermfg=238  ctermbg=NONE cterm=NONE       guifg=#444444  guibg=NONE     gui=NONE
hi Underlined          ctermfg=117  ctermbg=NONE cterm=underline  guifg=#87d7ff  guibg=NONE     gui=underline
hi Tag                 ctermfg=117  ctermbg=NONE cterm=NONE       guifg=#87d7ff  guibg=NONE     gui=NONE
hi Directive           ctermfg=249  ctermbg=NONE cterm=NONE       guifg=#b2b2b2  guibg=NONE     gui=NONE
hi Format              ctermfg=245  ctermbg=NONE cterm=bold       guifg=#8a8a8a  guibg=NONE     gui=bold
hi Tooltip             ctermfg=255  ctermbg=18   cterm=NONE       guifg=#eeeeee  guibg=#000087  gui=NONE
hi Menu                ctermfg=255  ctermbg=18   cterm=NONE       guifg=#eeeeee  guibg=#000087  gui=NONE

" ==============================================================================
" Language-specific tweaks (optional)
" ==============================================================================

" HTML/XML
hi htmlTag             ctermfg=245  ctermbg=NONE cterm=NONE       guifg=#8a8a8a  guibg=NONE     gui=NONE
hi htmlEndTag          ctermfg=245  ctermbg=NONE cterm=NONE       guifg=#8a8a8a  guibg=NONE     gui=NONE
hi htmlTagName         ctermfg=255  ctermbg=NONE cterm=bold       guifg=#eeeeee  guibg=NONE     gui=bold
hi htmlArg             ctermfg=249  ctermbg=NONE cterm=NONE       guifg=#b2b2b2  guibg=NONE     gui=NONE
hi htmlString          ctermfg=245  ctermbg=NONE cterm=bold       guifg=#8a8a8a  guibg=NONE     gui=bold

" Markdown
hi markdownH1          ctermfg=255  ctermbg=NONE cterm=bold       guifg=#eeeeee  guibg=NONE     gui=bold
hi markdownH2          ctermfg=255  ctermbg=NONE cterm=bold       guifg=#eeeeee  guibg=NONE     gui=bold
hi markdownH3          ctermfg=255  ctermbg=NONE cterm=bold       guifg=#eeeeee  guibg=NONE     gui=bold
hi markdownCode        ctermfg=245  ctermbg=18   cterm=bold       guifg=#8a8a8a  guibg=#000087  gui=bold
hi markdownCodeBlock   ctermfg=245  ctermbg=18   cterm=bold       guifg=#8a8a8a  guibg=#000087  gui=bold
hi markdownUrl         ctermfg=117  ctermbg=NONE cterm=underline  guifg=#87d7ff  guibg=NONE     gui=underline
hi markdownLink        ctermfg=117  ctermbg=NONE cterm=NONE       guifg=#87d7ff  guibg=NONE     gui=NONE
hi markdownLinkText    ctermfg=255  ctermbg=NONE cterm=NONE       guifg=#eeeeee  guibg=NONE     gui=NONE

" vim: set sw=2 ts=2 sts=2 et tw=80:
