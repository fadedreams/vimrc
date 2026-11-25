" ══════════════════════════════════════════════════════════════
" .vimrc (save as ~/.vimrc)
" ══════════════════════════════════════════════════════════════
set encoding=utf-8
scriptencoding utf-8
let mapleader = " "
let maplocalleader = "\\"

command! Farsi silent %y | vnew | setlocal buftype=nofile bufhidden=wipe | silent put | silent 1d | silent %!fribidi --nobreak

" No swap files (set early so it always applies)
set noswapfile
set nobackup
set nowritebackup

" ── Fast scrolling (Ctrl-d / Ctrl-u / j / k) ─────────────────
set lazyredraw
set ttyfast
set regexpengine=1
set synmaxcol=200
set updatetime=300
set ttimeout
set ttimeoutlen=10
set timeoutlen=500
set nocursorline
set nocursorcolumn
set norelativenumber
set number
set signcolumn=yes          " no layout shift when mark signs appear
if exists('+smoothscroll') | set nosmoothscroll | endif
syntax sync minlines=64 maxlines=200

" ── Auto-install vim-plug (only when git exists) ──────────────
" :PlugInstall manually if auto install did not work
let s:plug_file = expand('~/.vim/autoload/plug.vim')
let s:plug_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
let s:plug_ok = 0
if executable('git')
  if empty(glob(s:plug_file)) && executable('curl')
    call system('curl -fsLo ' . s:plug_file . ' --create-dirs ' . s:plug_url)
  endif
  if filereadable(s:plug_file)
    execute 'source ' . s:plug_file
    let s:plug_ok = exists('*plug#begin')
  endif
endif

" ── Install fzf / ripgrep / bat / fd (only on :InstallFzfDeps) ─
function! s:InstallFzfDeps()
  let l:missing = []
  if !executable('fzf') | call add(l:missing, 'fzf') | endif
  if !executable('rg')  | call add(l:missing, 'rg')  | endif
  if !executable('bat') && !executable('batcat') | call add(l:missing, 'bat') | endif
  if !executable('fd')  && !executable('fdfind') | call add(l:missing, 'fd')  | endif
  if empty(l:missing) | echo '[deps] all present' | return | endif
  echo '[deps] Missing: ' . join(l:missing, ', ') . ' — installing...'

  let l:pkgs = {'fzf': 'fzf', 'rg': 'ripgrep', 'bat': 'bat', 'fd': 'fd'}
  if executable('apt-get')
    let l:pkgs.fd = 'fd-find'
    let l:cmd = 'sudo apt-get install -y '
  elseif executable('dnf')
    let l:cmd = 'sudo dnf install -y '
  elseif executable('pacman')
    let l:cmd = 'sudo pacman -S --needed --noconfirm '
  elseif executable('apk')
    let l:cmd = 'sudo apk add '
  elseif executable('zypper')
    let l:cmd = 'sudo zypper install -y '
  elseif executable('brew')
    let l:cmd = 'brew install '
  else
    echo '[deps] No supported package manager found' | return
  endif

  let l:names = map(copy(l:missing), 'l:pkgs[v:val]')
  " '!' runs in a real terminal so a sudo password prompt works
  execute '!' . l:cmd . join(l:names, ' ')
endfunction
command! InstallFzfDeps call s:InstallFzfDeps()

" ── Plugins ───────────────────────────────────────────────────
if s:plug_ok
  call plug#begin('~/.vim/plugged')
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'christoomey/vim-tmux-navigator'
  Plug 'tpope/vim-fugitive'
  Plug 'mbbill/undotree'
  call plug#end()
endif

" ── General ───────────────────────────────────────────────────
syntax on
filetype plugin indent on
set background=dark
if has('termguicolors') | set termguicolors | endif
silent! colorscheme habamax

set hidden
set mouse=a
set clipboard=unnamedplus
set ignorecase smartcase
set incsearch hlsearch
set expandtab shiftwidth=2 tabstop=2 softtabstop=2
set scrolloff=8
set splitright splitbelow
set undofile
set undodir=~/.vim/undo
if !isdirectory(expand('~/.vim/undo')) | call mkdir(expand('~/.vim/undo'), 'p') | endif
set laststatus=2

nnoremap <silent> <leader>h :nohlsearch<CR>
nnoremap <leader>u :UndotreeToggle<CR>
nnoremap <leader>e :Explore<CR>

" ── netrw ─────────────────────────────────────────────────────
let g:netrw_banner = 0
let g:netrw_liststyle = 3

" ── fzf ───────────────────────────────────────────────────────
if s:plug_ok
  nnoremap <leader>f :Files<CR>
  nnoremap <leader>b :Buffers<CR>
  nnoremap <leader>g :Rg<CR>
endif

" ── Statusline (cheap: no system() calls, nothing on CursorMoved) ──
set statusline=%f\ %m%r%h%w
set statusline+=\ %{exists('*FugitiveHead')?FugitiveHead():''}
set statusline+=%=%y\ %l:%c\ %p%%

" ══════════════════════════════════════════════════════════════
" Marks plugin: signs, panel, persistence
"   m{a-zA-Z}      set mark (refreshes signs/panel, autosaves)
"   <localleader>` toggle panel   (\`)
"   <leader>sm / <leader>lm   save / load marks
"   <leader>d`     delete all marks
" ══════════════════════════════════════════════════════════════
let s:marks_file = expand('~/.vim/marks.txt')
let s:globals    = {}     " letter -> [path, lnum, col]
let s:store      = {}     " path -> {letter -> [lnum, col]}  (lowercase marks)
let s:panel_buf  = -1
let s:src_buf    = -1

" ── Signs ─────────────────────────────────────────────────────
if exists('*sign_define')
  for s:c in range(char2nr('A'), char2nr('Z')) + range(char2nr('a'), char2nr('z'))
    call sign_define('Mark' . nr2char(s:c),
          \ {'text': nr2char(s:c), 'texthl': 'WarningMsg'})
  endfor
endif

" ── Helpers ───────────────────────────────────────────────────
" Lowercase marks of buffer a:b -> {letter: [lnum, col]}
function! s:BufMarks(b)
  let l:res = {}
  if exists('*getmarklist')
    for l:m in getmarklist(a:b)
      if l:m.mark =~# "^'[a-z]$"
        let l:res[l:m.mark[1]] = [l:m.pos[1], l:m.pos[2]]
      endif
    endfor
  elseif a:b == bufnr('%')
    for l:c in range(char2nr('a'), char2nr('z'))
      let l:p = getpos("'" . nr2char(l:c))
      if l:p[1] > 0 | let l:res[nr2char(l:c)] = [l:p[1], l:p[2]] | endif
    endfor
  endif
  return l:res
endfunction

" Uppercase marks -> {letter: [path, lnum, col, bufnr]}
function! s:GlobalMarks()
  let l:res = {}
  for l:c in range(char2nr('A'), char2nr('Z'))
    let l:n = nr2char(l:c)
    let l:p = getpos("'" . l:n)
    if l:p[1] > 0 && l:p[0] > 0
      let l:res[l:n] = [fnamemodify(bufname(l:p[0]), ':p'), l:p[1], l:p[2], l:p[0]]
    endif
  endfor
  return l:res
endfunction

function! s:MarksUpdateSigns()
  if !exists('*sign_place') || &buftype !=# '' | return | endif
  let l:b = bufnr('%')
  let l:entries = []
  for [l:m, l:p] in items(s:BufMarks(l:b))
    call add(l:entries, [l:m, l:p[0]])
  endfor
  for [l:m, l:g] in items(s:GlobalMarks())
    if l:g[3] == l:b | call add(l:entries, [l:m, l:g[1]]) | endif
  endfor
  " Skip all work when nothing changed (keeps CursorHold/BufEnter cheap)
  let l:key = join(map(copy(l:entries), 'v:val[0] . v:val[1]'), ',')
  if get(b:, 'marks_key', 'x') ==# l:key | return | endif
  let b:marks_key = l:key
  call sign_unplace('marks', {'buffer': l:b})
  for [l:m, l:ln] in l:entries
    call sign_place(0, 'marks', 'Mark' . l:m, l:b, {'lnum': l:ln, 'priority': 10})
  endfor
endfunction

" ── Persistence ───────────────────────────────────────────────
function! s:MarksSave(...)
  let l:quiet = a:0 && a:1
  " Sync from live Vim state
  let s:globals = {}
  for [l:m, l:g] in items(s:GlobalMarks())
    let s:globals[l:m] = [l:g[0], l:g[1], l:g[2]]
  endfor
  for l:bi in getbufinfo({'bufloaded': 1})
    if empty(l:bi.name) || getbufvar(l:bi.bufnr, '&buftype') !=# '' | continue | endif
    let l:path = fnamemodify(l:bi.name, ':p')
    let l:bm = s:BufMarks(l:bi.bufnr)
    if empty(l:bm)
      silent! call remove(s:store, l:path)
    else
      let s:store[l:path] = l:bm
    endif
  endfor

  let l:lines = []
  for [l:m, l:g] in items(s:globals)
    call add(l:lines, join([l:m, l:g[0], l:g[1], l:g[2]], "\t"))
  endfor
  for [l:path, l:d] in items(s:store)
    for [l:m, l:p] in items(l:d)
      call add(l:lines, join([l:m, l:path, l:p[0], l:p[1]], "\t"))
    endfor
  endfor
  if !isdirectory(fnamemodify(s:marks_file, ':h'))
    call mkdir(fnamemodify(s:marks_file, ':h'), 'p')
  endif
  call writefile(l:lines, s:marks_file)
  if !l:quiet | echo '[marks] saved ' . len(l:lines) . ' marks' | endif
endfunction

function! s:MarksLoad()
  if !filereadable(s:marks_file) | return | endif
  let s:globals = {}
  let s:store = {}
  for l:line in readfile(s:marks_file)
    let l:f = split(l:line, "\t", 1)
    if len(l:f) < 4 | continue | endif
    let [l:m, l:path, l:ln, l:col] = [l:f[0], l:f[1], str2nr(l:f[2]), str2nr(l:f[3])]
    if !filereadable(l:path) | continue | endif
    if l:m =~# '^[A-Z]$'
      let s:globals[l:m] = [l:path, l:ln, l:col]
      let l:nr = bufadd(l:path)
      silent! call setpos("'" . l:m, [l:nr, l:ln, l:col, 0])
    elseif l:m =~# '^[a-z]$'
      if !has_key(s:store, l:path) | let s:store[l:path] = {} | endif
      let s:store[l:path][l:m] = [l:ln, l:col]
    endif
  endfor
  " Apply lowercase marks to buffers that are already open
  for l:bi in getbufinfo({'bufloaded': 1})
    call setbufvar(l:bi.bufnr, 'marks_loaded', 0)
    if l:bi.bufnr == bufnr('%') | call s:MarksLoadForBuf(l:bi.bufnr) | endif
  endfor
  call s:MarksUpdateSigns()
endfunction

function! s:MarksLoadForBuf(b)
  if a:b != bufnr('%') || empty(bufname(a:b)) | return | endif
  if getbufvar(a:b, 'marks_loaded', 0) | return | endif
  call setbufvar(a:b, 'marks_loaded', 1)
  let l:path = fnamemodify(bufname(a:b), ':p')
  if !has_key(s:store, l:path) | return | endif
  for [l:m, l:p] in items(s:store[l:path])
    silent! call setpos("'" . l:m, [0, min([l:p[0], line('$')]), l:p[1], 0])
  endfor
endfunction

function! s:MarksDeleteAll()
  silent! delmarks!
  silent! delmarks A-Z
  let s:globals = {}
  let s:store = {}
  call delete(s:marks_file)
  let b:marks_key = 'x'
  call s:MarksUpdateSigns()
  call s:MarksRefreshPanel()
  echo '[marks] all marks deleted'
endfunction

" ── Panel ─────────────────────────────────────────────────────
function! s:MarksRender()
  if s:panel_buf < 1 || !bufexists(s:panel_buf) | return | endif
  let l:lines = ['Marks   <CR>/l jump   q close']
  let l:rows = []
  for [l:m, l:g] in items(s:GlobalMarks())
    call add(l:rows, [l:m, fnamemodify(l:g[0], ':~:.'), l:g[1],
          \ get(getbufline(l:g[3], l:g[1]), 0, '')])
  endfor
  for [l:m, l:p] in items(s:BufMarks(s:src_buf))
    call add(l:rows, [l:m, fnamemodify(bufname(s:src_buf), ':~:.'), l:p[0],
          \ get(getbufline(s:src_buf, l:p[0]), 0, '')])
  endfor
  call sort(l:rows, {a, b -> a[0] ==# b[0] ? 0 : (a[0] <# b[0] ? -1 : 1)})
  for l:r in l:rows
    call add(l:lines, printf('%s  %s:%d  %s', l:r[0], l:r[1], l:r[2], substitute(l:r[3], '^\s\+', '', '')))
  endfor
  if empty(l:rows) | call add(l:lines, '(no marks)') | endif
  call setbufvar(s:panel_buf, '&modifiable', 1)
  call setbufline(s:panel_buf, 1, l:lines)
  silent! call deletebufline(s:panel_buf, len(l:lines) + 1, '$')
  call setbufvar(s:panel_buf, '&modifiable', 0)
endfunction

function! s:MarksRefreshPanel()
  if s:panel_buf < 1 || bufwinnr(s:panel_buf) < 0 | return | endif
  if bufnr('%') != s:panel_buf | let s:src_buf = bufnr('%') | endif
  call s:MarksRender()
endfunction

function! s:MarksShow()
  if s:panel_buf > 0 && bufwinnr(s:panel_buf) > 0
    call s:MarksClosePanel()
    return
  endif
  let s:src_buf = bufnr('%')
  botright 10new
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  setlocal nonumber norelativenumber nocursorline winfixheight signcolumn=no
  setlocal filetype=marks
  let s:panel_buf = bufnr('%')
  file [Marks]
  call s:MarksPanelMaps()
  call s:MarksRender()
  normal! 2G
endfunction

function! s:MarksClosePanel()
  let l:w = bufwinnr(s:panel_buf)
  if l:w > 0
    execute l:w . 'wincmd w'
    close
  endif
  let s:panel_buf = -1
endfunction

function! s:MarksJump()
  let l:m = matchlist(getline('.'), '^\([A-Za-z]\)  ')
  if empty(l:m) | return | endif
  call s:MarksClosePanel()
  try
    execute 'normal! `' . l:m[1]
  catch
    echo '[marks] mark ' . l:m[1] . ' is not set'
  endtry
endfunction

function! s:MarksPanelMaps()
  nnoremap <buffer> <silent> q     :call <SID>MarksClosePanel()<CR>
  nnoremap <buffer> <silent> <M-q> :call <SID>MarksClosePanel()<CR>
  nnoremap <buffer> <silent> <CR>  :call <SID>MarksJump()<CR>
  nnoremap <buffer> <silent> l     :call <SID>MarksJump()<CR>
endfunction

" ── Intercept m{x} to refresh signs + panel ───────────────────
" Saves quietly after every mark so a crash doesn't lose them.
function! s:SetMarkAndRefresh(mark)
  execute 'normal! m' . a:mark
  call s:MarksUpdateSigns()
  call s:MarksSave(1)
  call s:MarksRefreshPanel()
endfunction

for s:c in range(char2nr('A'), char2nr('Z'))
  execute printf("nnoremap <silent> m%s :call <SID>SetMarkAndRefresh('%s')<CR>",
        \ nr2char(s:c), nr2char(s:c))
endfor
for s:c in range(char2nr('a'), char2nr('z'))
  execute printf("nnoremap <silent> m%s :call <SID>SetMarkAndRefresh('%s')<CR>",
        \ nr2char(s:c), nr2char(s:c))
endfor

" ── Keymaps ───────────────────────────────────────────────────
nnoremap <silent> <leader>sm  :call <SID>MarksSave()<CR>
nnoremap <silent> <leader>lm  :call <SID>MarksLoad()<CR>
nnoremap <silent> <leader>d`  :call <SID>MarksDeleteAll()<CR>
nnoremap <silent> <localleader>` :call <SID>MarksShow()<CR>

" ── Autocmds ──────────────────────────────────────────────────
augroup MarksPlugin
  autocmd!
  autocmd BufWinEnter * call s:MarksLoadForBuf(expand('<abuf>') + 0)
        \ | call s:MarksUpdateSigns()
  autocmd VimLeavePre * call s:MarksSave(1)
  autocmd BufEnter,BufWrite,DirChanged,CursorHold * call s:MarksUpdateSigns()
augroup END

" ── Initial load ──────────────────────────────────────────────
" Wait for VimEnter so argument files exist; the v:vim_did_enter branch
" covers the auto-PlugInstall re-source of this vimrc mid-startup.
augroup MarksInitialLoad
  autocmd!
  if v:vim_did_enter
    call s:MarksLoad()
  else
    autocmd VimEnter * call s:MarksLoad()
  endif
augroup END
