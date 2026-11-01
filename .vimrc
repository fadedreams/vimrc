" ~/.vim/colors/claude.vim
"
" Vim port of the "claude" Neovim colorscheme.
" Dark only. Forces 'background' to dark.
"
" Requires: set termguicolors   (true-colour terminal)

hi clear
if exists('syntax_on')
  syntax reset
endif
set termguicolors
set background=dark
let g:colors_name = 'claude'

" ── Palettes ──────────────────────────────────────────────────
let s:dark = {
  \ 'bg': '#262624', 'bg_alt': '#30302E', 'bg_float': '#1E1E1C',
  \ 'bg_select': '#3D3B36', 'bg_cursor': '#40403C',
  \ 'fg': '#E8E6DC', 'fg_dim': '#B5B3A8', 'fg_dimmer': '#8A8778',
  \ 'border': '#4A4844',
  \ 'orange': '#D97757', 'orange_dim': '#ec7e7e',
  \ 'kraft': '#D4A27F', 'sage': '#87A08A', 'clay': '#C1654A',
  \ 'gold': '#FBAD60', 'slate_blue': '#70B8FF', 'lavender': '#CC7BF4',
  \ 'rose': '#F47B85', 'comment_gray': '#818898',
  \ 'red': '#C1654A', 'green': '#98C379', 'yellow': '#FBAD60',
  \ 'blue': '#70B8FF', 'purple': '#CC7BF4', 'cyan': '#7FB0AC',
  \ }

let s:p = s:dark

" Expose the palette so the rest of your vimrc (statusline, marks,
" rainbow, fzf) can reuse it:  let c = g:claude_palette
let g:claude_palette = s:p

" ── Helper ────────────────────────────────────────────────────
" s:h(group, fg, bg [, gui-attrs [, sp-colour]])
function! s:h(group, fg, bg, ...) abort
  let l:attr = a:0 >= 1 ? a:1 : 'NONE'
  let l:sp   = a:0 >= 2 ? a:2 : 'NONE'
  execute 'hi ' . a:group
        \ . ' guifg=' . a:fg . ' guibg=' . a:bg
        \ . ' gui=' . l:attr . ' cterm=NONE guisp=' . l:sp
endfunction

let s:N = 'NONE'
let p   = s:p

" ── Editor UI ─────────────────────────────────────────────────
call s:h('Normal',       p.fg,        p.bg)
call s:h('NormalNC',     p.fg,        p.bg)
call s:h('NormalFloat',  p.fg,        p.bg_float)
call s:h('Cursor',       p.bg,        p.fg_dim)
call s:h('lCursor',      p.bg,        p.fg_dim)
call s:h('CursorLine',   s:N,         p.bg_alt)
call s:h('CursorColumn', s:N,         p.bg_alt)
call s:h('ColorColumn',  s:N,         p.bg_alt)
call s:h('CursorLineNr', p.fg_dim,    p.bg_alt, 'bold')
call s:h('LineNr',       p.fg_dimmer, p.bg)
call s:h('SignColumn',   p.fg_dimmer, p.bg)
call s:h('FoldColumn',   p.fg_dimmer, p.bg)
call s:h('Folded',       p.fg_dim,    p.bg_alt, 'italic')

call s:h('VertSplit',    p.border,    p.bg)
call s:h('StatusLine',   p.fg,        p.bg, 'bold')
call s:h('StatusLineNC', p.fg_dimmer, p.bg)
call s:h('StatusLineTerm',   p.fg,        p.bg, 'bold')
call s:h('StatusLineTermNC', p.fg_dimmer, p.bg)
call s:h('TabLine',      p.fg_dim,    p.bg_alt)
call s:h('TabLineSel',   p.blue,      p.bg, 'bold')
call s:h('TabLineFill',  s:N,         p.bg_alt)

call s:h('Pmenu',        p.fg,        p.bg_float)
call s:h('PmenuSel',     p.bg,        p.blue, 'bold')
call s:h('PmenuSbar',    s:N,         p.bg_alt)
call s:h('PmenuThumb',   s:N,         p.fg_dimmer)
call s:h('PopupNotification', p.fg,   p.bg_float)

call s:h('Visual',       s:N,         p.bg_select)
call s:h('VisualNOS',    s:N,         p.bg_select)
call s:h('Search',       p.bg,        p.gold)
call s:h('IncSearch',    p.bg,        p.blue)
call s:h('CurSearch',    p.bg,        p.blue)
call s:h('MatchParen',   p.blue,      s:N, 'bold,underline')

call s:h('Directory',    p.slate_blue, s:N)
call s:h('Title',        p.blue,      s:N, 'bold')
call s:h('NonText',      p.border,    s:N)
call s:h('Whitespace',   p.border,    s:N)
call s:h('SpecialKey',   p.border,    s:N)
call s:h('EndOfBuffer',  p.bg,        s:N)
call s:h('Conceal',      p.fg_dimmer, s:N)
call s:h('Terminal',     p.fg,        p.bg)

" ── Messages ──────────────────────────────────────────────────
call s:h('ErrorMsg',     p.clay,      s:N, 'bold')
call s:h('WarningMsg',   p.gold,      s:N, 'bold')
call s:h('ModeMsg',      p.fg_dim,    s:N)
call s:h('MoreMsg',      p.sage,      s:N)
call s:h('Question',     p.blue,      s:N)

" ── Diff (also used by undotree) ──────────────────────────────
call s:h('DiffAdd',      p.sage,      p.bg_alt)
call s:h('DiffChange',   p.gold,      p.bg_alt)
call s:h('DiffDelete',   p.clay,      p.bg_alt)
call s:h('DiffText',     p.blue,      p.bg_select, 'bold')
call s:h('diffAdded',    p.sage,      s:N)
call s:h('diffRemoved',  p.clay,      s:N)
call s:h('diffChanged',  p.gold,      s:N)
call s:h('diffFile',     p.blue,      s:N, 'bold')
call s:h('diffLine',     p.slate_blue, s:N)

" ── Spell ─────────────────────────────────────────────────────
call s:h('SpellBad',     s:N, s:N, 'undercurl', p.clay)
call s:h('SpellCap',     s:N, s:N, 'undercurl', p.gold)
call s:h('SpellLocal',   s:N, s:N, 'undercurl', p.slate_blue)
call s:h('SpellRare',    s:N, s:N, 'undercurl', p.lavender)

" ── Syntax ────────────────────────────────────────────────────
call s:h('Comment',      p.comment_gray, s:N, 'italic')
call s:h('Constant',     p.gold,      s:N)
call s:h('String',       p.sage,      s:N)
call s:h('Character',    p.sage,      s:N)
call s:h('Number',       p.cyan,      s:N)
call s:h('Boolean',      p.cyan,      s:N)
call s:h('Float',        p.cyan,      s:N)
call s:h('Identifier',   p.fg,        s:N)
call s:h('Function',     p.slate_blue, s:N)
call s:h('Statement',    p.lavender,  s:N)
call s:h('Conditional',  p.lavender,  s:N)
call s:h('Repeat',       p.lavender,  s:N)
call s:h('Label',        p.orange,    s:N)
call s:h('Operator',     p.kraft,     s:N)
call s:h('Keyword',      p.lavender,  s:N)
call s:h('Exception',    p.clay,      s:N, 'bold')
call s:h('PreProc',      p.lavender,  s:N)
call s:h('Include',      p.lavender,  s:N)
call s:h('Define',       p.lavender,  s:N)
call s:h('Macro',        p.lavender,  s:N)
call s:h('PreCondit',    p.lavender,  s:N)
call s:h('Type',         p.kraft,     s:N, 'bold')
call s:h('StorageClass', p.kraft,     s:N)
call s:h('Structure',    p.kraft,     s:N)
call s:h('Typedef',      p.kraft,     s:N)
call s:h('Special',      p.orange,    s:N)
call s:h('SpecialChar',  p.orange,    s:N)
call s:h('Tag',          p.orange,    s:N)
call s:h('Delimiter',    p.fg_dim,    s:N)
call s:h('SpecialComment', p.comment_gray, s:N, 'italic')
call s:h('Debug',        p.clay,      s:N)
call s:h('Underlined',   s:N,         s:N, 'underline')
call s:h('Ignore',       p.fg_dimmer, s:N)
call s:h('Error',        p.clay,      s:N, 'bold')
call s:h('Todo',         p.bg,        p.gold, 'bold')

" ── Filetype extras (Vim has no treesitter; these approximate the
"    @-groups from the Lua theme using classic syntax groups) ──
" Markdown
call s:h('markdownH1',          p.orange,     s:N, 'bold')
call s:h('markdownH2',          p.orange,     s:N, 'bold')
call s:h('markdownH3',          p.orange,     s:N, 'bold')
call s:h('markdownH4',          p.orange,     s:N, 'bold')
call s:h('markdownH5',          p.orange,     s:N, 'bold')
call s:h('markdownH6',          p.orange,     s:N, 'bold')
call s:h('markdownHeadingDelimiter', p.orange, s:N, 'bold')
call s:h('markdownCode',        p.sage,       s:N)
call s:h('markdownCodeBlock',   p.sage,       s:N)
call s:h('markdownCodeDelimiter', p.fg_dimmer, s:N)
call s:h('markdownListMarker',  p.orange,     s:N)
call s:h('markdownLinkText',    p.slate_blue, s:N, 'underline')
call s:h('markdownUrl',         p.slate_blue, s:N, 'underline')
call s:h('markdownBold',        s:N,          s:N, 'bold')
call s:h('markdownItalic',      s:N,          s:N, 'italic')
" HTML / XML
call s:h('htmlTag',             p.fg_dim,     s:N)
call s:h('htmlEndTag',          p.fg_dim,     s:N)
call s:h('htmlTagName',         p.orange,     s:N)
call s:h('htmlArg',             p.kraft,      s:N, 'italic')
" Vimscript itself (you edit your vimrc a lot)
call s:h('vimOption',           p.rose,       s:N)
call s:h('vimHiGroup',          p.kraft,      s:N)
call s:h('vimUserFunc',         p.slate_blue, s:N)
call s:h('vimFunction',         p.slate_blue, s:N)
call s:h('vimNotation',         p.orange,     s:N)
call s:h('vimMapModKey',        p.orange,     s:N)
call s:h('vimBracket',          p.fg_dim,     s:N)
" Python-ish builtins
call s:h('pythonBuiltin',       p.slate_blue, s:N)
call s:h('pythonDecorator',     p.lavender,   s:N)
call s:h('pythonSelf',          p.orange,     s:N, 'italic')

" ── Plugins ───────────────────────────────────────────────────
" netrw
call s:h('netrwDir',            p.blue,       s:N, 'bold')
call s:h('netrwClassify',       p.fg_dim,     s:N)
call s:h('netrwExe',            p.sage,       s:N)
call s:h('netrwSymLink',        p.lavender,   s:N)
" undotree
call s:h('UndotreeSavedBig',    p.clay,       s:N, 'bold')
call s:h('UndotreeSavedSmall',  p.sage,       s:N)
call s:h('UndotreeCurrent',     p.blue,       s:N, 'bold')
call s:h('UndotreeNode',        p.gold,       s:N)
call s:h('UndotreeSeq',         p.fg_dimmer,  s:N)
call s:h('UndotreeBranch',      p.fg_dim,     s:N)
call s:h('UndotreeHead',        p.blue,       s:N, 'bold')
call s:h('UndotreeTimeStamp',   p.fg_dimmer,  s:N)

" ── Terminal ANSI palette (:terminal, fzf popups) ─────────────
let g:terminal_ansi_colors = [
  \ p.bg,        p.red,    p.green,  p.yellow,
  \ p.blue,      p.purple, p.cyan,   p.fg,
  \ p.fg_dimmer, p.red,    p.green,  p.yellow,
  \ p.blue,      p.purple, p.cyan,   p.fg,
  \ ]

unlet p
" vim: set ft=vim sw=2 et:
