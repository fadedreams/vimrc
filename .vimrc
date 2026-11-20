" ══════════════════════════════════════════════════════════════
"  .vimrc   (save as ~/.vimrc)
" ══════════════════════════════════════════════════════════════
" encoding must be set before scriptencoding so the multibyte
" characters below (box drawing, icons, bullets) parse correctly.
set encoding=utf-8
scriptencoding utf-8

let mapleader = " "
let maplocalleader = "\\"      " was implicit; make it explicit

" No swap files (set early so it always applies)
set noswapfile
set nobackup
set nowritebackup

" ── Auto-install vim-plug (only when git exists) ──────────────
" vim-plug prints "`git` executable not found" (plus a Press-ENTER
" prompt) from plug#begin() when git is missing, and it cannot install
" any plugin without git anyway. So without git we skip vim-plug
" completely: no message, no plugins. Install git and restart Vim and
" everything bootstraps itself.
" :PlugInstall manually if auto install did not work
let s:plug_file = expand('~/.vim/autoload/plug.vim')
let s:plug_url  = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
let s:plug_ok   = 0

if executable('git')
  if empty(glob(s:plug_file)) && executable('curl')
    call system('curl -fsLo ' . s:plug_file . ' --create-dirs ' . s:plug_url)
  endif
  if filereadable(s:plug_file)
    execute 'source ' . s:plug_file
    let s:plug_ok = exists('*plug#begin')
  endif
endif

" ── Install fzf / ripgrep / fd (cross-distro) ────────────────
" NOTE: this only *installs* things when you explicitly run
" :InstallFzfDeps. It used to run automatically on every startup,
" which meant a missing dep silently triggered `sudo apt-get/...`
" and Vim would hang waiting on a password prompt.
function! s:InstallFzfDeps()
  let l:missing = []

  if !executable('fzf')      | call add(l:missing, 'fzf')      | endif
  if !executable('rg')       | call add(l:missing, 'rg')        | endif
  if !executable('bat') && !executable('batcat') | call add(l:missing, 'bat') | endif
  if !executable('fd') && !executable('fdfind')
    call add(l:missing, 'fd')
  endif

  if empty(l:missing) | return | endif

  echo '[deps] Missing: ' . join(l:missing, ', ') . ' — installing...'

  " [executable, install command, package name for fd]
  " (ripgrep is always 'ripgrep'; fzf and bat keep their names)
  let l:managers = [
        \ ['apt-get', '!sudo apt-get install -y ',     'fd-find'],
        \ ['pacman',  '!sudo pacman -S --noconfirm ',  'fd'],
        \ ['dnf',     '!sudo dnf install -y ',         'fd-find'],
        \ ['yum',     '!sudo yum install -y ',         'fd-find'],
        \ ['zypper',  '!sudo zypper install -y ',      'fd'],
        \ ['apk',     '!sudo apk add ',                'fd'],
        \ ['brew',    '!brew install ',                'fd'],
        \ ]

  for [exe, cmd, fdname] in l:managers
    if executable(exe)
      let l:pkgs = map(copy(l:missing),
            \ 'v:val ==# "fd" ? fdname : v:val ==# "rg" ? "ripgrep" : v:val')
      execute cmd . join(l:pkgs, ' ')
      echo '[deps] Done. Restart Vim if fzf keymaps seem broken.'
      return
    endif
  endfor

  echohl WarningMsg
  echo '[deps] No supported package manager found. Install manually: ' . join(l:missing, ' ')
  echohl None
endfunction

" Lightweight startup check — only warns, never shells out to sudo.
function! s:CheckFzfDeps()
  let l:missing = []
  if !executable('fzf')                            | call add(l:missing, 'fzf') | endif
  if !executable('rg')                             | call add(l:missing, 'rg')  | endif
  if !executable('bat') && !executable('batcat')   | call add(l:missing, 'bat') | endif
  if !executable('fd') && !executable('fdfind')    | call add(l:missing, 'fd')  | endif
  if !empty(l:missing)
    echohl WarningMsg
    echo '[deps] Missing: ' . join(l:missing, ', ') . ' — run :InstallFzfDeps to install'
    echohl None
  endif
endfunction

command! -bar InstallFzfDeps call s:InstallFzfDeps()

" fd compat: Debian/Ubuntu install it as fdfind
if !executable('fd') && executable('fdfind')
  let $FD = 'fdfind'
else
  let $FD = 'fd'
endif

" Run the check after startup so the message isn't swallowed or
" followed by a "Press ENTER" prompt. (The guard avoids a duplicate
" run when the vimrc is re-sourced from the auto PlugInstall below.)
" Only relevant when plugins (fzf) are in play, so it stays silent
" on a bare box without git.
augroup FzfDepsCheck
  autocmd!
  if s:plug_ok && !v:vim_did_enter
    autocmd VimEnter * ++once call s:CheckFzfDeps()
  endif
augroup END


" ══════════════════════════════════════════════════════════════
"  Main config
" ══════════════════════════════════════════════════════════════

" ── Plugins (vim-plug) ────────────────────────────────────────
" No `else` branch on purpose: if vim-plug isn't loaded (no git /
" no curl) we silently carry on with the plain-Vim config below.
if s:plug_ok
  call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-eunuch'          " :Delete :Rename :Mkdir :Chmod ...
    Plug 'tpope/vim-fugitive'
    Plug 'jiangmiao/auto-pairs'
    Plug 'mbbill/undotree'
    Plug 'luochen1990/rainbow'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'christoomey/vim-tmux-navigator'
  call plug#end()

  " Auto-install any plugins that are listed but not on disk
  augroup AutoPlugInstall
    autocmd!
    autocmd VimEnter * ++once
          \ if !empty(filter(copy(g:plugs), '!isdirectory(v:val.dir)'))
          \ |   PlugInstall --sync | q | source $MYVIMRC
          \ | endif
  augroup END
endif

" ── Colorscheme ───────────────────────────────────────────────
if has('termguicolors')
  set termguicolors
endif
set background=dark
silent! colorscheme habamax
if get(g:, 'colors_name', '') !=# 'habamax'
  colorscheme desert
endif

" ── Rainbow Parentheses ───────────────────────────────────────
let g:rainbow_active = 1              " 1 = always on  |  :RainbowToggle to flip
let g:rainbow_conf = {
  \   'guifgs': ['#e06c75', '#e5c07b', '#98c379', '#56b6c2', '#61afef', '#c678dd'],
  \   'ctermfgs': ['lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'],
  \ }


" ── Clipboard ─────────────────────────────────────────────────
" unnamedplus needs a Vim built with +clipboard
" (check with: vim --version | grep clipboard)
if has('clipboard')
  set clipboard=unnamedplus
endif

" <leader>y / <leader>Y removed: clipboard=unnamedplus already yanks to the
" system clipboard, and <leader>y was a prefix of <leader>yy/yn/yp, which
" made Vim wait for timeoutlen after pressing it.
" Visual-mode only (a plain `noremap` also hit operator-pending mode, and
" its normal-mode half was overridden later by the :put mapping anyway).
xnoremap <Leader>p "+p
nnoremap <silent> <localleader>' :registers<cr>
" Search for visually selected text (Ctrl+f); newlines are escaped so
" multi-line selections work too.
vnoremap <silent> <C-f> y/\V<C-r>=substitute(escape(@", '/\'), '\n', '\\n', 'g')<CR><CR>

" ── Appearance ────────────────────────────────────────────────
set number
set relativenumber
set cursorline
set laststatus=2
set noshowmode            " the custom statusline already shows the mode
set showcmd
set signcolumn=yes
" StatusLine and StatusLineNC are highlighted identically below, which makes
" Vim fall back to '^' / '=' fill characters. Force plain spaces.
set fillchars+=stl:\ ,stlnc:\ 


" ── Editing ───────────────────────────────────────────────────
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
" (smartindent removed: `filetype plugin indent on` handles indenting)
set breakindent
set backspace=indent,eol,start
set nojoinspaces
set virtualedit=block

" ── Comment continuation ──────────────────────────────────────
augroup no_comment_continuation
  autocmd!
  autocmd FileType * setlocal formatoptions-=r formatoptions-=o
augroup END


" ── Search ────────────────────────────────────────────────────
set incsearch
set hlsearch
set ignorecase
set smartcase
set wrapscan
nnoremap <Esc><Esc> :nohlsearch<CR>


" ── Files ─────────────────────────────────────────────────────
set hidden
set autoread
set undofile
set undodir=~/.vim/undo//

" autoread only takes effect when Vim checks timestamps
augroup AutoReadCheck
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold *
        \ if mode() !=# 'c' && getcmdwintype() ==# '' | checktime | endif
augroup END

set fileformats=unix,dos
" ── Auto-create missing directories (on save) ─────────────────
function! s:AutoMkdir(dir)
  " skip empty names and URL-style buffers (fugitive://, netrw scp://, ...)
  if a:dir ==# '' || a:dir =~# '^\w\+://'
    return
  endif
  if !isdirectory(a:dir)
    call mkdir(a:dir, 'p', 0755)
  endif
endfunction

augroup AutoMkdir
  autocmd!
  autocmd BufWritePre * call s:AutoMkdir(expand('<afile>:p:h'))
augroup END

" Make sure undo dir exists
if !isdirectory(expand('~/.vim/undo'))
  call mkdir(expand('~/.vim/undo'), 'p', 0700)
endif


" ── Splits ────────────────────────────────────────────────────
nnoremap <C-w>% :vsplit<CR>
nnoremap <C-w>" :split<CR>

nnoremap <leader>b% :vsplit<CR>
nnoremap <leader>b" :split<CR>

set splitright
set splitbelow
" <C-h/j/k/l> window navigation is provided by vim-tmux-navigator (it also
" moves between tmux panes). Manual nnoremap lines here used to override the
" plugin's mappings and break tmux navigation, so they were removed.


" ── Window Swap ───────────────────────────────────────────────
function! s:SwapWindow(dir)
  let l:win = win_getid()
  let l:buf = bufnr('%')
  execute 'wincmd ' . a:dir
  let l:other_win = win_getid()
  if l:other_win == l:win | return | endif
  let l:other_buf = bufnr('%')
  call win_gotoid(l:win)
  execute 'buffer ' . l:other_buf
  call win_gotoid(l:other_win)
  execute 'buffer ' . l:buf
endfunction

nnoremap <silent> <C-w><Left>  :call <SID>SwapWindow('h')<CR>
nnoremap <silent> <C-w><Right> :call <SID>SwapWindow('l')<CR>
nnoremap <silent> <C-w><Up>    :call <SID>SwapWindow('k')<CR>
nnoremap <silent> <C-w><Down>  :call <SID>SwapWindow('j')<CR>


" ══════════════════════════════════════════════════════════════
"  Mappings
" ══════════════════════════════════════════════════════════════


" ── Files ─────────────────────────────────────────────────────
nnoremap <A-w> :w<CR>
inoremap <A-w> <Esc>:w<CR>gi
nnoremap <A-q> :q<CR>
inoremap <A-q> <Esc>:q<CR>

nnoremap <leader>q  :q<CR>
nnoremap <leader>e  :Explore<CR>
nnoremap <C-BS>     :bd<CR>
" Buffer next/prev/new/delete mappings live in the "Buffer
" management" section below — that used to redefine <leader>bn,
" <leader>bd, <C-\> etc. a second time, silently overriding the
" versions that were here, and left <leader>bp orphaned pointing
" at the old (pre-override) meaning of <leader>bn. Keeping one
" definition per key avoids that mismatch.

" ── Whitespace cleanup ────────────────────────────────────────
" Strips CRs and trailing whitespace only. Blank lines are kept,
" and the cursor/scroll position is restored afterwards.
function! s:CleanWhitespace()
  let l:view = winsaveview()
  keeppatterns silent! %s/\r$//e
  keeppatterns silent! %s/\s\+$//e
  call winrestview(l:view)
endfunction
nnoremap <silent> <leader>ww :call <SID>CleanWhitespace()<CR>
nnoremap <leader>wc :set ff=unix<CR>

" Edit and run an awk filter on the whole buffer (press Enter to run)
nnoremap <leader>wa :%!awk '{print $1, $2, $3, $4, $5, $6}'

" ── Pasting ───────────────────────────────────────────────────
" Visual $ goes to last non-blank char (like g_)
vnoremap $ g_

" Paste in visual mode without overwriting the register with the
" replaced text. `P` does this natively on Vim 8.2.4242+; older
" versions fall back to the yank-it-back trick.
if has('patch-8.2.4242')
  xnoremap p P
else
  xnoremap p pgvy
endif

" Paste below / above in normal mode
nnoremap <silent> <leader>p :put<CR>
" (was <S-p>, which is just `P` and silently turned it into a linewise paste)
nnoremap <silent> <leader>P :put!<CR>

" System clipboard paste in insert mode
inoremap <A-p> <C-r>+

" ── Deleting ──────────────────────────────────────────────────
" x: delete char without yanking
nnoremap x "_x

" D in visual: delete to black hole
xnoremap D "_d

" Alt-d in visual: delete selection to black hole
vnoremap <A-d> "_d

" Smart dd: blank lines go to black hole, others yank normally
function! s:SmartDD()
  let l:line = getline('.')
  if l:line =~# '^\s*$'
    return '"_dd'
  else
    return 'dd'
  endif
endfunction
nnoremap <expr> dd <SID>SmartDD()

" Change to EOL without yanking
nnoremap c$ "_c$

" ── Navigation ────────────────────────────────────────────────
" Keep cursor centred when jumping pages
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" Keep search terms centred
nnoremap n nzzzv
nnoremap N Nzzzv

" Move lines in visual mode
vnoremap K :m '<-2<CR>gv=gv
vnoremap J :m '>+1<CR>gv=gv

" Move lines in normal/visual mode (Ctrl+Alt+j/k)
nnoremap <silent> <C-A-j> :m .+1<CR>==
nnoremap <silent> <C-A-k> :m .-2<CR>==
vnoremap <silent> <C-A-j> :m '>+1<CR>gv=gv
vnoremap <silent> <C-A-k> :m '<-2<CR>gv=gv

" Stay in indent mode
vnoremap < <gv
vnoremap > >gv

" Move cursor to middle of buffer
function! s:GotoMiddle()
  let l:mid = line('$') / 2
  execute 'normal! ' . l:mid . 'G'
endfunction
nnoremap <silent> M :call <SID>GotoMiddle()<CR>

" j/k move by screen line on wrapped text, but keep real-line
" motion when a count is given (so 5j / 5k still work with relativenumber)
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'

" Escape insert mode
inoremap jk <Esc>

" Arrow-key navigation in insert mode (Alt+hjkl)
inoremap <A-h> <Left>
inoremap <A-j> <Down>
inoremap <A-k> <Up>
inoremap <A-l> <Right>

" Home / End in insert and command mode
inoremap <C-a> <Home>
inoremap <C-e> <End>
cnoremap <C-a> <Home>
cnoremap <C-e> <End>

" Delete operations in insert mode
inoremap <A-u> <C-u>
inoremap <A-d> <C-o>db
inoremap <A-x> <Del>

" Arrow-key window navigation
nnoremap <C-Left>  <C-w>h
nnoremap <C-Right> <C-w>l
nnoremap <C-Up>    <C-w>k
nnoremap <C-Down>  <C-w>j

" git
function! s:JumpConflict(direction)
  let pattern = '^\(<<<<<<\|=======\|>>>>>>>\)'
  let flags = a:direction ==# 'next' ? 'W' : 'bW'
  let ok = search(pattern, flags)
  if ok == 0
    echo "No more conflict markers"
  endif
endfunction

" <Cmd> needs Vim 8.2.1978+
nnoremap ]g <Cmd>call <SID>JumpConflict('next')<CR>
nnoremap [g <Cmd>call <SID>JumpConflict('prev')<CR>

" ── Buffer management ─────────────────────────────────────────
nnoremap <silent> <C-\>      :bdelete!<CR>
inoremap <silent> <C-\>      <Esc>:bdelete!<CR>
" <C-c> is intentionally left at its default behaviour (acts like
" <Esc> in insert/visual/etc). It used to be remapped here to
" close/delete the buffer, which meant a reflexive Ctrl-C (e.g. to
" bail out of insert mode) could wipe out your buffer.

nnoremap <silent> <leader>bd :bd<CR>
nnoremap <silent> <leader>bn :enew<CR>
nnoremap <silent> <leader>bv :vnew<CR>
nnoremap <silent> <leader>bs :new<CR>
nnoremap <silent> <leader>b[ :bprevious<CR>
nnoremap <silent> <leader>b] :bnext<CR>
nnoremap <silent> <leader>br :edit!<CR>
nnoremap <silent> <localleader>[ :bprevious<CR>
nnoremap <silent> <localleader>] :bnext<CR>

" Cycle buffers from insert mode (h = left/previous, l = right/next)
inoremap <silent> <C-h> <Esc>:bprevious<CR>
inoremap <silent> <C-l> <Esc>:bnext<CR>

" chmod +x / delete file from disk / rename: use vim-eunuch
"   :Chmod +x   :Delete   :Rename {name}   :Mkdir

" ── Reopen last closed buffer ─────────────────────────────────
let g:last_closed_buffer = ''

augroup TrackClosedBuffers
  autocmd!
  autocmd BufDelete * call s:TrackLastClosed(expand('<abuf>'))
augroup END

" Stores an absolute path (relative paths break after :cd) and ignores
" special buffers such as netrw directory listings.
function! s:TrackLastClosed(bufnr)
  let l:nr = str2nr(a:bufnr)
  let l:name = bufname(l:nr)
  if l:name !=# '' && getbufvar(l:nr, '&buftype') ==# '' && !isdirectory(l:name)
    let g:last_closed_buffer = fnamemodify(l:name, ':p')
  endif
endfunction

" :edit instead of :b — `:b name` does partial matching and can open the
" wrong buffer.
function! ReopenLastBuffer()
  if g:last_closed_buffer !=# '' && filereadable(g:last_closed_buffer)
    execute 'edit ' . fnameescape(g:last_closed_buffer)
  else
    echohl WarningMsg | echo "No recently closed buffer or file does not exist" | echohl None
  endif
endfunction

nnoremap <silent> <leader>bl :call ReopenLastBuffer()<CR>
nnoremap <silent> <C-;>      :call ReopenLastBuffer()<CR>

" ── Delete other buffers (spare pinned ones) ──────────────────
let g:pinned_buffers = {}

" Toggle pin on the current buffer (pinned buffers survive <leader>bo)
function! s:TogglePinBuffer()
  let l:nr = bufnr('%')
  if get(g:pinned_buffers, l:nr, 0)
    call remove(g:pinned_buffers, l:nr)
    echo '[buf] unpinned ' . bufname(l:nr)
  else
    let g:pinned_buffers[l:nr] = 1
    echo '[buf] pinned ' . bufname(l:nr)
  endif
endfunction

function! s:DeleteOtherBuffers()
  let l:current = bufnr('%')
  for l:buf in filter(range(1, bufnr('$')),
        \ 'buflisted(v:val) && v:val != l:current && !get(g:pinned_buffers, v:val, 0)')
    silent! execute 'bdelete ' . l:buf
  endfor
endfunction

nnoremap <silent> <leader>bo :call <SID>DeleteOtherBuffers()<CR>
nnoremap <silent> <leader>bp :call <SID>TogglePinBuffer()<CR>

" ── Buffer info float ─────────────────────────────────────────
function! s:BufferInfo()
  let l:file  = expand('%:p')
  let l:name  = l:file !=# '' ? fnamemodify(l:file, ':~:.')  : '[No Name]'

  let l:size = '---'
  if l:file !=# '' && filereadable(l:file)
    let l:bytes = getfsize(l:file)
    if l:bytes >= 1048576
      let l:size = printf('%.1f MB', l:bytes / 1048576.0)
    elseif l:bytes >= 1024
      let l:size = printf('%.1f KB', l:bytes / 1024.0)
    else
      let l:size = l:bytes . ' B'
    endif
  endif

  " NOTE: GNU `stat -c`; on macOS perms/owner show '---'.
  let l:perms = '---'
  if l:file !=# ''
    let l:raw = system('stat -c %a ' . shellescape(l:file))
    if v:shell_error == 0
      let l:perms = substitute(l:raw, '\s\+', '', 'g')
    endif
  endif

  let l:owner = '---'
  if l:file !=# ''
    let l:raw = system('stat -c %U:%G ' . shellescape(l:file))
    if v:shell_error == 0
      let l:owner = substitute(l:raw, '\s\+', '', 'g')
    endif
  endif

  let l:enc = &fileencoding !=# '' ? &fileencoding : &encoding
  let l:lines = [
        \ '  ' . l:name,
        \ '  owner    ' . l:owner,
        \ '',
        \ '  ft       ' . (&filetype !=# '' ? &filetype : '-'),
        \ '  enc      ' . l:enc,
        \ '  fmt      ' . &fileformat,
        \ '  perms    ' . l:perms,
        \ '  size     ' . l:size,
        \ '  modified ' . (&modified ? 'true' : 'false'),
        \ '  readonly ' . (&readonly ? 'true' : 'false'),
        \ '',
        \ '  q / <Esc>  close',
        \ ]

  if !has('popupwin')
    echo join(l:lines, "\n")
    return
  endif

  let l:width = 48
  call popup_create(l:lines, {
        \ 'pos':      'topleft',
        \ 'line':     3,
        \ 'col':      (&columns - l:width) / 2,
        \ 'minwidth': l:width,
        \ 'maxwidth': l:width,
        \ 'border':   [],
        \ 'padding':  [0, 1, 0, 1],
        \ 'mapping':  1,
        \ 'filter':   function('s:BufferInfoFilter'),
        \ })
endfunction

function! s:BufferInfoFilter(winid, key)
  if a:key ==# 'q' || a:key ==# "\<Esc>"
    call popup_close(a:winid)
    return 1
  endif
  return 0
endfunction

nnoremap <silent> <leader>bi :call <SID>BufferInfo()<CR>

" Misc
nnoremap <C-/> :nohlsearch<CR>:diffupdate<CR>:redraw!<CR>
nnoremap <C-_> :nohlsearch<CR>:diffupdate<CR>:redraw!<CR>

nnoremap <leader>rr :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

" ── UI Toggles ────────────────────────────────────────────────
nnoremap <silent> <leader>ir :set relativenumber!<CR>

function! s:ToggleColorcolumn()
  if &colorcolumn == '120'
    set colorcolumn=
  else
    set colorcolumn=120
  endif
endfunction
nnoremap <silent> <leader>ic :call <SID>ToggleColorcolumn()<CR>

function! s:ToggleBackground()
  if &background ==# 'dark'
    set background=light
  else
    set background=dark
  endif
endfunction
nnoremap <silent> <leader>uc :call <SID>ToggleBackground()<CR>

function! s:ToggleFoldcolumn()
  if &foldcolumn == 0
    set foldcolumn=1
  else
    set foldcolumn=0
  endif
endfunction
nnoremap <silent> <leader>if :call <SID>ToggleFoldcolumn()<CR>

function! s:ToggleListcharsFull()
  if &list
    set nolist
  else
    set listchars=tab:»\ ,trail:·,nbsp:␣,eol:¬
    set list
  endif
endfunction
nnoremap <silent> <leader>iL :call <SID>ToggleListcharsFull()<CR>

nnoremap <silent> <leader>il :set list!<CR>

nnoremap <silent> <leader>uhm :messages<CR>

function! s:CheckKey()
  let l:key = input("Check key: ")
  if l:key ==# '' | return | endif
  execute 'verbose nmap ' . l:key
  execute 'verbose vmap ' . l:key
  execute 'verbose omap ' . l:key
endfunction
nnoremap <leader>fK :call <SID>CheckKey()<CR>


" ── Performance ───────────────────────────────────────────────
" (lazyredraw removed: it causes stale redraws with popups/statuslines)
" Alt (<A-x>/<M-x>) mappings arrive as <Esc>x in most terminals; a short
" ttimeoutlen makes them reliable and makes <Esc> feel instant.
set ttimeout
set ttimeoutlen=50
set updatetime=300
set timeoutlen=500
set history=1000
set scrolloff=8
set sidescrolloff=8
set wildmenu
set wildmode=list:longest
" `syntax enable` (not `syntax on`): `on` can reset the colorscheme
" highlights that were applied above.
syntax enable
filetype plugin indent on


" ══════════════════════════════════════════════════════════════
"  File Browser  (mirrors telescope-file-browser)
" ══════════════════════════════════════════════════════════════

let g:netrw_liststyle = 0
let g:netrw_localcopycmd       = 'cp'
let g:netrw_localcopycmdopt    = ''
let g:netrw_localcopydircmd    = 'cp'
let g:netrw_localcopydircmdopt = '-r'

let g:netrw_banner    = 1
let g:netrw_winsize   = 30
let g:netrw_hide      = 0
let g:netrw_preview   = 1
augroup NetrwMaps
  autocmd!
  autocmd FileType netrw nnoremap <buffer> <A-q> :bdelete<CR>
  autocmd FileType netrw nnoremap <buffer> <C-v> :vnew<CR>
  autocmd FileType netrw nnoremap <buffer> <C-s> :new<CR>
augroup END

nnoremap <leader>v :Explore %:p:h<CR>

" ── Netrw: p previews the file under the cursor ───────────────
" Replaces netrw's built-in `p`. Resolves the full path of the
" entry on the current line and shows it in a popup on the right.
" Press p on a directory to get a message (directories aren't previewed).
function! s:NetrwEntryUnderCursor()
  " Ask netrw itself first (handles thin/long/wide/tree listings)
  let l:word = ''
  try
    let l:word = netrw#Call('NetrwGetWord')
  catch
    let l:word = ''
  endtry

  " Fallback: first whitespace-delimited token on the line
  if empty(l:word)
    let l:word = matchstr(getline('.'), '^\S\+')
  endif
  if empty(l:word) || l:word ==# '../' || l:word ==# './'
    return ''
  endif

  if l:word =~# '^/'
    let l:path = l:word
  else
    let l:dir  = get(b:, 'netrw_curdir', getcwd())
    let l:path = l:dir . '/' . l:word
  endif

  " Drop trailing marker characters netrw may leave on names (e.g. '@' symlink, '*' exec)
  if !filereadable(l:path) && !isdirectory(l:path)
    let l:path = substitute(l:path, '[@*=|]$', '', '')
  endif
  return simplify(l:path)
endfunction

" Popup-based preview: nothing about the window layout changes, so the
" netrw cursor can't jump. `p` toggles it; while it's open it follows
" the cursor as you move between files. Leaving netrw closes it.
let s:np_popup = 0

function! s:NetrwPopupClose()
  if s:np_popup
    silent! call popup_close(s:np_popup)
    let s:np_popup = 0
  endif
  augroup NetrwPopupLive
    autocmd!
  augroup END
endfunction

function! s:NetrwPopupShow(path)
  if !filereadable(a:path) || isdirectory(a:path)
    return
  endif
  if getfsize(a:path) > 2*1024*1024
    echo '[netrw] file too large to preview'
    return
  endif
  silent! call popup_close(s:np_popup)

  let l:width  = get(g:, 'netrw_preview_width', float2nr(&columns * get(g:, 'netrw_preview_ratio', 0.6)))
  let l:width  = min([l:width, &columns - 4])
  let l:height = &lines - 6
  let l:buf    = bufadd(a:path)
  silent call bufload(l:buf)

  let s:np_popup = popup_create(l:buf, {
        \ 'pos':       'topleft',
        \ 'line':      2,
        \ 'col':       &columns - l:width - 1,
        \ 'minwidth':  l:width,
        \ 'maxwidth':  l:width,
        \ 'minheight': l:height,
        \ 'maxheight': l:height,
        \ 'border':    [],
        \ 'padding':   [0, 1, 0, 1],
        \ 'highlight':       'Normal',
        \ 'borderhighlight': ['Comment'],
        \ 'title':     ' ' . fnamemodify(a:path, ':t') . ' ',
        \ 'scrollbar': 0,
        \ 'borderchars': ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
        \ 'wrap':      0,
        \ })
  " Syntax highlighting inside the popup
  silent! call win_execute(s:np_popup, 'filetype detect | syntax enable')
endfunction

function! s:NetrwPopupFollow()
  if !s:np_popup
    return
  endif
  let l:path = s:NetrwEntryUnderCursor()
  if !empty(l:path) && filereadable(l:path) && !isdirectory(l:path)
    call s:NetrwPopupShow(l:path)
  endif
endfunction

function! s:NetrwPreview()
  if !has('popupwin')
    echo '[netrw] this Vim has no popup support'
    return
  endif
  " p again = close
  if s:np_popup
    call s:NetrwPopupClose()
    return
  endif
  let l:path = s:NetrwEntryUnderCursor()
  if empty(l:path)
    echo '[netrw] nothing to preview here'
    return
  endif
  if isdirectory(l:path)
    echo '[netrw] directory — nothing to preview'
    return
  endif
  if !filereadable(l:path)
    echohl WarningMsg | echo '[netrw] cannot read: ' . l:path | echohl None
    return
  endif
  call s:NetrwPopupShow(l:path)
  augroup NetrwPopupLive
    autocmd!
    autocmd CursorMoved <buffer> call s:NetrwPopupFollow()
    autocmd BufLeave,WinLeave <buffer> call s:NetrwPopupClose()
  augroup END
endfunction

" Netrw installs its own buffer-local `p` mapping *after* FileType fires,
" which silently overrides ours. So we (re)apply the mapping a tick later,
" on both FileType and BufEnter (netrw rebuilds its maps on refresh too).
" The buffer number is captured when the autocmd fires (via a partial) and
" passed to the timer callback, so the check below really tests the buffer
" that triggered it. (The old lambda evaluated bufnr('%') at timer time,
" which made the check meaningless.)
function! s:MapNetrwPreview(buf, ...)
  if bufnr('%') == a:buf && &filetype ==# 'netrw'
    nnoremap <buffer> <silent> <nowait> p :call <SID>NetrwPreview()<CR>
  endif
endfunction

augroup NetrwPreviewMap
  autocmd!
  autocmd FileType netrw call timer_start(0, function('s:MapNetrwPreview', [bufnr('%')]))
  autocmd BufEnter * if &filetype ==# 'netrw'
        \ | call timer_start(0, function('s:MapNetrwPreview', [bufnr('%')]))
        \ | endif
augroup END


" ── Copy Path Helpers ─────────────────────────────────────────
" Falls back to the unnamed register when Vim has no +clipboard.
function! s:CopyPath(mod, label)
  let l:val = expand(a:mod)
  call setreg(has('clipboard') ? '+' : '"', l:val)
  echo 'Copied ' . a:label . ': ' . l:val
endfunction

nnoremap <silent> <leader>yy :call <SID>CopyPath('%:.', 'relative')<CR>
nnoremap <silent> <leader>yn :call <SID>CopyPath('%:t', 'name')<CR>
nnoremap <silent> <leader>yp :call <SID>CopyPath('%:p', 'absolute')<CR>


" ── Diff Split Picker ─────────────────────────────────────────
" Fixes: the old FileType autocmd was registered after :Explore had
" already fired FileType (so <CR>/q were never mapped), and
" filereadable() got a bare filename relative to cwd instead of the
" netrw directory.
let s:diff_origin = -1

function! s:MapDiffPicker(buf, ...)
  if bufnr('%') == a:buf && &filetype ==# 'netrw'
    nnoremap <buffer> <silent> <nowait> <CR> :call <SID>NetrwDiffOpen()<CR>
    nnoremap <buffer> <silent> <nowait> q    :call <SID>DiffPickerClose()<CR>
  endif
endfunction

function! s:DiffPickerClose()
  let l:nb = bufnr('%')
  silent! nunmap <buffer> <CR>
  silent! nunmap <buffer> q
  if s:diff_origin > 0 && bufexists(s:diff_origin)
    execute 'buffer ' . s:diff_origin
  endif
  silent! execute 'bdelete ' . l:nb
endfunction

function! OpenDiffPicker()
  let s:diff_origin = bufnr('%')
  execute 'Explore ' . fnameescape(expand('%:p:h'))
  let l:nb = bufnr('%')
  call s:MapDiffPicker(l:nb)
  call timer_start(0, function('s:MapDiffPicker', [l:nb]))   " netrw re-applies its maps
endfunction

function! s:NetrwDiffOpen()
  let l:target = s:NetrwEntryUnderCursor()
  if empty(l:target) | return | endif
  if isdirectory(l:target)
    execute 'edit ' . fnameescape(l:target)
    call timer_start(0, function('s:MapDiffPicker', [bufnr('%')]))
    return
  endif
  if filereadable(l:target)
    call s:DiffPickerClose()
    execute 'vert diffsplit ' . fnameescape(l:target)
  endif
endfunction

nnoremap <leader>dt :call OpenDiffPicker()<CR>


" ── Undotree ──────────────────────────────────────────────────
nnoremap <leader>ut :UndotreeToggle<CR>
let g:undotree_WindowLayout       = 2
let g:undotree_ShortIndicators    = 1
let g:undotree_SetFocusWhenToggle = 1
let g:undotree_SplitWidth         = 30


" ── Auto-pairs ────────────────────────────────────────────────
let g:AutoPairsShortcutToggle   = ''
let g:AutoPairsShortcutFastWrap = '<M-e>'


" ── Markdown Preview (pure Vim, no external tools) ────────────
" <leader>um toggles "preview mode" for the current markdown buffer:
"   - hides the markup (#, **, *, `, fences, [text](url)), bullets -> •
"   - word-wraps, hides line numbers, makes the buffer read-only
" Press <leader>um again to go back to editing. One buffer, one window,
" no splits, no browser, nothing to install. Live: edits show instantly.

function! s:MdHighlights()
  hi mdpvBold     gui=bold      cterm=bold
  hi mdpvItalic   gui=italic    cterm=italic
  hi mdpvCode     guifg=#e5c07b ctermfg=180
  hi mdpvFence    guifg=#e5c07b ctermfg=180
  hi mdpvLinkText guifg=#61afef ctermfg=75 gui=underline cterm=underline
  hi link mdpvMark Conceal
endfunction

function! s:MdSyntax()
  " Order matters: later rules win, so bold is defined after italic.
  syntax region mdpvItalic matchgroup=mdpvMark start=/\*\ze[^* \t]/ end=/[^* \t]\zs\*/ oneline concealends
  syntax region mdpvBold   matchgroup=mdpvMark start=/\*\*\ze\S/   end=/\S\zs\*\*/   oneline concealends
  syntax region mdpvCode   matchgroup=mdpvMark start=/`/ end=/`/ oneline concealends

  " Fenced code blocks: hide the ``` lines, colour the body
  syntax region mdpvFence matchgroup=mdpvMark start=/^\s*```.*$/ end=/^\s*```\s*$/ concealends

  " [text](url): show only the underlined text
  syntax region mdpvLinkText matchgroup=mdpvMark start=/\[/ end=/\]\ze(/ oneline concealends
  syntax match  mdpvLinkUrl  /\]\@<=([^)]*)/ conceal

  " Heading markers and bullets
  syntax match mdpvHeadMark /^#\+\s\+/ conceal containedin=markdownH1,markdownH2,markdownH3,markdownH4,markdownH5,markdownH6
  syntax match mdpvBullet   /^\s*\zs[-*+]\ze\s\+\S/ conceal cchar=• containedin=markdownListMarker
endfunction

function! s:MdPreviewOn()
  let w:md_saved = {
        \ 'cole': &l:conceallevel, 'cocu': &l:concealcursor,
        \ 'wrap': &l:wrap,         'lbr':  &l:linebreak,
        \ 'nu':   &l:number,       'rnu':  &l:relativenumber,
        \ 'sc':   &l:signcolumn }
  let b:md_saved_ma = &l:modifiable
  setlocal conceallevel=2 concealcursor=nvic
  setlocal wrap linebreak nonumber norelativenumber signcolumn=no
  setlocal nomodifiable
  let b:md_preview = 1
  echo '[md] preview ON  (<leader>um to edit)'
endfunction

function! s:MdPreviewOff()
  if exists('w:md_saved')
    let &l:conceallevel    = w:md_saved.cole
    let &l:concealcursor   = w:md_saved.cocu
    let &l:wrap            = w:md_saved.wrap
    let &l:linebreak       = w:md_saved.lbr
    let &l:number          = w:md_saved.nu
    let &l:relativenumber  = w:md_saved.rnu
    let &l:signcolumn      = w:md_saved.sc
    unlet w:md_saved
  else
    setlocal conceallevel=0
  endif
  let &l:modifiable = get(b:, 'md_saved_ma', 1)
  let b:md_preview = 0
  echo '[md] preview OFF'
endfunction

function! s:MdPreviewToggle()
  if &filetype !=# 'markdown'
    echo '[md] not a markdown buffer'
    return
  endif
  if get(b:, 'md_preview', 0)
    call s:MdPreviewOff()
  else
    call s:MdPreviewOn()
  endif
endfunction

call s:MdHighlights()
augroup MarkdownPreview
  autocmd!
  autocmd ColorScheme * call s:MdHighlights()
  autocmd Syntax markdown call s:MdSyntax()
  autocmd FileType markdown nnoremap <buffer> <silent> <leader>um :call <SID>MdPreviewToggle()<CR>
augroup END


" ── FZF ───────────────────────────────────────────────────────
" Make fzf popups inherit the active colorscheme
let g:fzf_colors = {
  \ 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Search'],
  \ 'fg+':     ['fg', 'CursorLine', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine'],
  \ 'hl+':     ['fg', 'IncSearch'],
  \ 'info':    ['fg', 'Comment'],
  \ 'border':  ['fg', 'Comment'],
  \ 'prompt':  ['fg', 'Function'],
  \ 'pointer': ['fg', 'Function'],
  \ 'marker':  ['fg', 'Function'],
  \ 'spinner': ['fg', 'Function'],
  \ 'header':  ['fg', 'Comment'] }

" True only when fzf.vim is actually installed (needs git + :PlugInstall).
" Without it the fzf mappings below print one short line instead of
" throwing "Unknown function" errors.
function! s:HaveFzf()
  let l:p = get(g:, 'plugs', {})
  if has_key(l:p, 'fzf.vim') && isdirectory(l:p['fzf.vim'].dir)
    return 1
  endif
  echohl WarningMsg | echo '[fzf] plugin not installed (needs git, then :PlugInstall)' | echohl None
  return 0
endfunction

" bat is installed as `batcat` on Debian/Ubuntu; fall back to head if neither exists
if executable('bat')
  let s:bat = 'bat'
elseif executable('batcat')
  let s:bat = 'batcat'
else
  let s:bat = ''
endif
let s:preview_file = empty(s:bat) ? 'head -n 500 {}'  : s:bat . ' --color=always --style=numbers {}'
let s:preview_grep = empty(s:bat) ? 'head -n 500 {1}' : s:bat . ' --color=always {1} --highlight-line {2}'

" --no-ignore searches files that .gitignore would hide, so the heavy
" directories are excluded explicitly (same set as the fd excludes below).
" Drop --no-ignore if you'd rather just respect .gitignore.
let s:rg_globs = '--glob=!.git --glob=!node_modules --glob=!dist --glob=!build --glob=!target --glob=!.cache'
let s:rg_opts    = '--hidden --no-ignore ' . s:rg_globs . ' --ignore-case --column --line-number --no-heading --color=always'
let s:fd_excludes = '--exclude .git --exclude node_modules --exclude .cache --exclude dist --exclude build --exclude target'

function! FdFiles()
  if !s:HaveFzf() | return | endif
  let l:source = $FD . ' --type f --hidden ' . s:fd_excludes
  call fzf#vim#files(getcwd(), {
    \ 'source':  l:source,
    \ 'options': [
    \   '--prompt',  'Files> ',
    \   '--preview', s:preview_file,
    \   '--preview-window', 'right:50%:wrap'
    \ ]}, 0)
endfunction

nnoremap <silent> <leader><leader> :call FdFiles()<CR>

function! RipgrepFzf(query, fullscreen)
  if !s:HaveFzf() | return | endif
  let command_fmt     = 'rg ' . s:rg_opts . ' -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command  = printf(command_fmt, '{q}')
  let spec = {
    \ 'options': [
    \   '--disabled',
    \   '--query', a:query,
    \   '--bind', 'change:reload:' . reload_command,
    \   '--delimiter', ':',
    \   '--preview', s:preview_grep,
    \   '--preview-window', '+{2}-/2'
    \ ]}
  call fzf#vim#grep(initial_command, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
nnoremap <silent> <leader>n :RG<CR>

function! RipgrepWord(word, fullscreen)
  if !s:HaveFzf() | return | endif
  if a:word ==# '' | echo 'No word under cursor' | return | endif
  let command_fmt     = 'rg ' . s:rg_opts . ' -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:word))
  let reload_command  = printf(command_fmt, '{q}')
  let spec = {
    \ 'options': [
    \   '--disabled',
    \   '--query', a:word,
    \   '--prompt', 'Grep[' . a:word . ']> ',
    \   '--bind', 'change:reload:' . reload_command,
    \   '--delimiter', ':',
    \   '--preview', s:preview_grep,
    \   '--preview-window', '+{2}-/2'
    \ ]}
  call fzf#vim#grep(initial_command, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

nnoremap <silent> <leader>1 :call RipgrepWord(expand('<cword>'), 0)<CR>

" Grep the path segment (split on / and \) under the cursor
function! s:GrepUnderCursor2()
  let l:line = getline('.')
  let l:idx  = col('.') - 1
  if l:idx >= len(l:line) || l:line[l:idx] =~# '\s'
    echo "No token under cursor"
    return
  endif

  " Bounds of the whitespace-delimited token around the cursor
  let l:s = l:idx
  while l:s > 0 && l:line[l:s - 1] !~# '\s'
    let l:s -= 1
  endwhile
  let l:e = l:idx
  while l:e < len(l:line) - 1 && l:line[l:e + 1] !~# '\s'
    let l:e += 1
  endwhile

  " Cursor on a separator: use the neighbouring segment
  if l:line[l:idx] =~# '[/\\]'
    let l:idx += (l:idx < l:e) ? 1 : -1
  endif
  if l:idx < l:s || l:line[l:idx] =~# '[/\\]'
    echo "No token under cursor"
    return
  endif

  " Expand to the segment between separators
  let l:ss = l:idx
  while l:ss > l:s && l:line[l:ss - 1] !~# '[/\\]'
    let l:ss -= 1
  endwhile
  let l:se = l:idx
  while l:se < l:e && l:line[l:se + 1] !~# '[/\\]'
    let l:se += 1
  endwhile

  call RipgrepWord(l:line[l:ss : l:se], 0)
endfunction

nnoremap <silent> <leader>2 :call <SID>GrepUnderCursor2()<CR>

" Grep the whole whitespace-delimited WORD under the cursor
nnoremap <silent> <leader>3 :call RipgrepWord(expand('<cWORD>'), 0)<CR>


" ══════════════════════════════════════════════════════════════
"  Custom Statusline
" ══════════════════════════════════════════════════════════════

function! s:SetStatuslineHls()
    hi StatusLine   guifg=NONE guibg=NONE gui=NONE cterm=NONE
    hi StatusLineNC guifg=NONE guibg=NONE gui=NONE cterm=NONE
    hi SLAccent        guifg=#7aa2f7 guibg=NONE gui=NONE cterm=NONE
    hi SLInsertAccent  guifg=#0db9d7 guibg=NONE gui=NONE cterm=NONE
    hi SLVisualAccent  guifg=#a487d8 guibg=NONE gui=NONE cterm=NONE
    hi SLReplaceAccent guifg=#d94a4a guibg=NONE gui=NONE cterm=NONE
    hi SLCmdAccent     guifg=#e0af68 guibg=NONE gui=NONE cterm=NONE
    hi SLTermAccent    guifg=#565f89 guibg=NONE gui=NONE cterm=NONE
    hi SLText          guifg=#c0caf5 guibg=NONE gui=NONE cterm=NONE
    hi SLExtra         guifg=#a9b1d6 guibg=NONE gui=NONE cterm=NONE
    hi SLModified      guifg=#c0caf5 guibg=NONE gui=NONE cterm=NONE
    hi SLGitAdd        guifg=#1abc9c guibg=NONE gui=NONE cterm=NONE
    hi SLGitChange     guifg=#e0af68 guibg=NONE gui=NONE cterm=NONE
    hi SLGitDelete     guifg=#db4b4b guibg=NONE gui=NONE cterm=NONE
    hi SLError         guifg=#db4b4b guibg=NONE gui=NONE cterm=NONE
    hi SLWarn          guifg=#e0af68 guibg=NONE gui=NONE cterm=NONE
endfunction

call s:SetStatuslineHls()
augroup SLHighlights
    autocmd!
    autocmd ColorScheme * call s:SetStatuslineHls()
augroup END

let s:mode_map = {
    \ 'n':    ['NORMAL',    '%#SLAccent#'],
    \ 'no':   ['O-PEND',    '%#SLAccent#'],
    \ 'i':    ['INSERT',    '%#SLInsertAccent#'],
    \ 'ic':   ['INSERT',    '%#SLInsertAccent#'],
    \ 'v':    ['VISUAL',    '%#SLVisualAccent#'],
    \ 'V':    ['V-LINE',    '%#SLVisualAccent#'],
    \ "\<C-v>": ['V-BLOCK', '%#SLVisualAccent#'],
    \ 'R':    ['REPLACE',   '%#SLReplaceAccent#'],
    \ 'Rv':   ['V-REPLACE', '%#SLReplaceAccent#'],
    \ 'c':    ['COMMAND',   '%#SLCmdAccent#'],
    \ 't':    ['TERMINAL',  '%#SLTermAccent#'],
    \ 'nt':   ['TERMINAL',  '%#SLTermAccent#'],
    \ 's':    ['SELECT',    '%#SLVisualAccent#'],
    \ 'S':    ['S-LINE',    '%#SLVisualAccent#'],
    \ }

function! SLMode()
    let m    = mode()
    " mode() can return compound values (ix, Rc, nov, niI, cv, ...);
    " fall back to the first character so they still get a proper label.
    let info = get(s:mode_map, m, get(s:mode_map, m[0], [toupper(m), '%#SLAccent#']))
    return info[1] . ' ' . info[0] . ' %#SLText#'
endfunction

function! SLFilename()
    let fpath = expand('%:.')
    if fpath ==# '' || fpath ==# '.'
        return '%#SLText# [No Name] '
    endif
    let file   = fnamemodify(fpath, ':t')
    let parent = fnamemodify(fpath, ':h')
    let result = parent ==# '.' ? file : parent . '/' . file
    if winwidth(0) <= 80
        let result = pathshorten(result)
    endif
    " a literal % in a filename would otherwise be read as a statusline item
    let result = substitute(result, '%', '%%', 'g')
    return '%#SLText# ' . result . ' '
endfunction

function! SLModified()
    if &readonly  | return '%#SLError# 󰌾 %#SLText#' | endif
    if &modified  | return '%#SLModified# ~ %#SLText#' | endif
    return ''
endfunction

function! SLVCS()
    if exists('*FugitiveHead')
        let head = FugitiveHead()
        if head ==# '' | return '' | endif
        if len(head) > 20 | let head = head[:16] . '…' | endif
        return '%#SLExtra#  ' . substitute(head, '%', '%%', 'g') . ' '
    endif
    return ''
endfunction

function! SLSearch()
    if !v:hlsearch | return '' | endif
    try
        let s = searchcount({'maxcount': 999})
        if empty(s) || !has_key(s, 'total') || s.total == 0 | return '' | endif
        return '%#SLExtra# ' . s.current . '/' . s.total . ' '
    catch
        return ''
    endtry
endfunction

function! SLMacro()
    let reg = reg_recording()
    return reg !=# '' ? '%#SLError# 󰑋 @' . reg . ' ' : ''
endfunction

function! SLBigFile()
    return line('$') > 1000 ? '%#SLWarn# 󰋩 big ' : ''
endfunction

function! SLFiletype()
    return &filetype !=# '' ? '%#SLExtra#  ' . &filetype . ' ' : ''
endfunction

function! SLEncoding()
    let enc = &fileencoding !=# '' ? &fileencoding : &encoding
    return (enc !=# 'utf-8' && enc !=# '') ? '%#SLExtra#  ' . toupper(enc) . ' ' : ''
endfunction

function! SLFileFormat()
    let icons = {'unix': 'LF', 'dos': 'CRLF', 'mac': 'CR'}
    return '%#SLExtra#  ' . get(icons, &fileformat, &fileformat) . ' '
endfunction

function! SLLineInfo()
    if &filetype ==# 'alpha' | return '' | endif
    let pct = float2nr(floor(line('.') * 100.0 / line('$')))
    return '%#SLExtra# ' . line('.') . ':' . col('.') . ' ' . pct . '%% '
endfunction

let s:scrollbar_chars = ['󰪞', '󰪟', '󰪠', '󰪡', '󰪢', '󰪣', '󰪤', '󰪥']
function! SLScrollbar()
    let n   = len(s:scrollbar_chars)
    let idx = max([1, min([n, float2nr(ceil(line('.') * 1.0 / line('$') * n))])])
    return '%#SLExtra# ' . s:scrollbar_chars[idx - 1] . ' '
endfunction

function! SLCharcount()
    " wordcount() is slow on big files and the statusline redraws constantly
    if &filetype ==# 'alpha' || line('$') >= 5000 | return '' | endif
    return '%#SLExtra# ' . wordcount().chars . ' '
endfunction

function! SLLinecount()
    return &filetype ==# 'alpha' ? '' : '%#SLExtra# ' . line('$') . ' '
endfunction

function! SLVenv()
    if &filetype !=# 'python' | return '' | endif
    let env = !empty($VIRTUAL_ENV) ? $VIRTUAL_ENV : $CONDA_DEFAULT_ENV
    return env !=# '' ? '%#SLExtra# 󰆧 ' . fnamemodify(env, ':t') . ' ' : ''
endfunction

function! ActiveStatusline()
    let w = winwidth(0)
    let left =
        \ SLMode()     .
        \ SLFilename() .
        \ SLModified() .
        \ SLVCS()
    let right =
        \ SLMacro()                           .
        \ SLSearch()                          .
        \ SLBigFile()                         .
        \ (w > 100 ? SLVenv()      : '')      .
        \ (w > 100 ? SLFiletype()  : '')      .
        \ SLLineInfo()                        .
        \ SLScrollbar()                       .
        \ (w > 90  ? SLCharcount() : '')      .
        \ (w > 80  ? SLLinecount() : '')      .
        \ (w > 110 ? SLEncoding()  : '')      .
        \ (w > 110 ? SLFileFormat(): '')
    return left . '%=' . right
endfunction

function! InactiveStatusline()
    return '%#SLTermAccent#' . SLFilename() . SLModified()
endfunction

augroup CustomStatusline
    autocmd!
    autocmd WinEnter,BufEnter * setlocal statusline=%!ActiveStatusline()
    autocmd WinLeave,BufLeave * setlocal statusline=%!InactiveStatusline()
    autocmd FileType qf,help  setlocal statusline=%!ActiveStatusline()
augroup END

set statusline=%!ActiveStatusline()

" ══════════════════════════════════════════════════════════════
"  Marks Plugin
" ══════════════════════════════════════════════════════════════

" ── Config ────────────────────────────────────────────────────
let s:marks_save_path  = expand('~/.vim/marks.json')
let s:marks_buf        = -1
let s:marks_win        = -1
" Bright enough to read on habamax's dark background
let g:marks_colors     = { 'global': '#e5c07b', 'local': '#61afef' }

" ── Highlights ────────────────────────────────────────────────
function! s:InitMarksHighlights()
  execute 'hi markGlobal guifg=' . g:marks_colors.global . ' gui=bold'
  execute 'hi markLocal  guifg=' . g:marks_colors.local  . ' gui=bold'
endfunction
call s:InitMarksHighlights()
augroup MarksHighlights
  autocmd!
  autocmd ColorScheme * call s:InitMarksHighlights()
augroup END

" ── Signs ─────────────────────────────────────────────────────
function! s:InitMarksSigns()
  for c in range(char2nr('A'), char2nr('Z'))
    let mark = nr2char(c)
    call sign_define('mark_' . mark, { 'text': mark . ' ', 'texthl': 'markGlobal' })
  endfor
  for c in range(char2nr('a'), char2nr('z'))
    let mark = nr2char(c)
    call sign_define('mark_' . mark, { 'text': mark . ' ', 'texthl': 'markLocal' })
  endfor
endfunction
call s:InitMarksSigns()

" ── Snapshot ──────────────────────────────────────────────────
" Lowercase marks (a-z) are buffer-local, but getpos("'x") always
" resolves against the *current* buffer — its returned bufnum is
" only ever non-zero for numbered/uppercase marks. getmarklist({buf})
" queries a specific buffer's local marks directly, so it's used
" here (with a buffer-switching fallback for very old Vim).
function! s:GetLocalMarksForBuf(bnr)
  let result = {}

  if exists('*getmarklist')
    for m in getmarklist(a:bnr)
      let mark = m.mark[1:]
      if mark =~# '^[a-z]$'
        let result[mark] = { 'lnum': m.pos[1], 'col': m.pos[2] }
      endif
    endfor
    return result
  endif

  " Fallback for Vim builds without getmarklist(): briefly switch
  " into the buffer to read its marks, then switch back.
  let l:cur = bufnr('%')
  if a:bnr != l:cur
    noautocmd execute 'buffer ' . a:bnr
  endif
  for c in range(char2nr('a'), char2nr('z'))
    let mark = nr2char(c)
    let pos  = getpos("'" . mark)
    if pos[1] != 0
      let result[mark] = { 'lnum': pos[1], 'col': pos[2] }
    endif
  endfor
  if a:bnr != l:cur
    noautocmd execute 'buffer ' . l:cur
  endif

  return result
endfunction

function! s:MarksSnapshot()
  let data = { 'global': {}, 'local': {} }

  for c in range(char2nr('A'), char2nr('Z'))
    let mark = nr2char(c)
    let pos  = getpos("'" . mark)
    if pos[1] != 0
      let fname = fnamemodify(bufname(pos[0] != 0 ? pos[0] : bufnr('%')), ':p')
      if fname !=# ''
        let data.global[mark] = { 'file': fname, 'lnum': pos[1], 'col': pos[2] }
      endif
    endif
  endfor

  for bnr in range(1, bufnr('$'))
    if !buflisted(bnr) || !bufloaded(bnr) | continue | endif
    let fname = fnamemodify(bufname(bnr), ':p')
    if fname ==# '' | continue | endif
    let buf_marks = s:GetLocalMarksForBuf(bnr)
    if !empty(buf_marks)
      let data.local[fname] = buf_marks
    endif
  endfor

  return data
endfunction

" ── Persistence ───────────────────────────────────────────────
function! s:MarksReadFile()
  if !filereadable(s:marks_save_path) | return {} | endif
  try
    let l:d = json_decode(join(readfile(s:marks_save_path), ''))
  catch
    return {}
  endtry
  return type(l:d) == v:t_dict ? l:d : {}
endfunction

" Live marks merged over what is on disk, so files not opened this
" session keep their saved marks.
function! s:MarksMerged()
  let l:snap  = s:MarksSnapshot()
  let l:old   = s:MarksReadFile()
  let l:local = type(get(l:old, 'local', 0)) == v:t_dict ? l:old.local : {}
  for l:bnr in range(1, bufnr('$'))
    if buflisted(l:bnr) && bufloaded(l:bnr) && getbufvar(l:bnr, 'marks_loaded', 0)
      let l:f = fnamemodify(bufname(l:bnr), ':p')
      if has_key(l:local, l:f) | call remove(l:local, l:f) | endif
    endif
  endfor
  call extend(l:local, l:snap.local)
  let l:snap.local = l:local
  return l:snap
endfunction

function! s:MarksWrite(data)
  " ~/.vim may not exist yet (e.g. before vim-plug creates it)
  let l:dir = fnamemodify(s:marks_save_path, ':h')
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p', 0755)
  endif
  call writefile([json_encode(a:data)], s:marks_save_path)
endfunction

function! s:MarksSave(...)
  let l:quiet = a:0 ? a:1 : 0
  let data = s:MarksMerged()
  try
    call s:MarksWrite(data)
    if !l:quiet
      echo printf('[marks] saved %d global, %d file(s) with local marks',
            \ len(data.global), len(data.local))
    endif
  catch
    echohl ErrorMsg | echo '[marks] write error: ' . v:exception | echohl None
  endtry
endfunction

function! s:MarksLoad()
  let data = s:MarksReadFile()
  if empty(data) | return | endif
  if type(get(data, 'global', 0)) == v:t_dict
    for [mark, info] in items(data.global)
      if has_key(info, 'file') && has_key(info, 'lnum')
        let bnr = bufnr(info.file, 1)
        call setbufvar(bnr, '&buflisted', 1)
        silent! call setpos("'" . mark, [bnr, info.lnum, get(info, 'col', 0), 0])
      endif
    endfor
  endif
  " Lowercase marks can only be set in the *current* buffer
  call s:MarksLoadForBuf(bufnr('%'), 1)
  call s:MarksUpdateSigns()
endfunction

" Runs once per buffer (unless forced) so it never overwrites live marks.
function! s:MarksLoadForBuf(bufnr, ...)
  let l:force = a:0 ? a:1 : 0
  if a:bufnr <= 0 || bufname(a:bufnr) ==# '' || getbufvar(a:bufnr, '&buftype') !=# ''
    return
  endif
  if !l:force && getbufvar(a:bufnr, 'marks_loaded', 0) | return | endif
  call setbufvar(a:bufnr, 'marks_loaded', 1)
  let l:locals = get(get(s:MarksReadFile(), 'local', {}), fnamemodify(bufname(a:bufnr), ':p'), {})
  for [mark, info] in items(l:locals)
    silent! call setpos("'" . mark, [a:bufnr, info.lnum, get(info, 'col', 0), 0])
  endfor
endfunction

" ── Sign column refresh ───────────────────────────────────────
function! s:MarksUpdateSigns()
  let bnr   = bufnr('%')
  let fname = fnamemodify(bufname(bnr), ':p')
  call sign_unplace('marks', { 'buffer': bnr })
  if fname ==# '' | return | endif

  for c in range(char2nr('A'), char2nr('Z'))
    let mark = nr2char(c)
    let pos  = getpos("'" . mark)
    if pos[1] != 0
      let mark_fname = fnamemodify(bufname(pos[0] != 0 ? pos[0] : bnr), ':p')
      if mark_fname ==# fname
        call sign_place(0, 'marks', 'mark_' . mark, bnr, { 'lnum': pos[1] })
      endif
    endif
  endfor

  for c in range(char2nr('a'), char2nr('z'))
    let mark = nr2char(c)
    let pos  = getpos("'" . mark)
    if pos[1] != 0
      let mark_buf = pos[0] != 0 ? pos[0] : bnr
      if mark_buf == bnr
        call sign_place(0, 'marks', 'mark_' . mark, bnr, { 'lnum': pos[1] })
      endif
    endif
  endfor
endfunction

" ── Delete all marks ──────────────────────────────────────────
function! s:MarksDeleteAll()
  let l:cur = bufnr('%')
  delmarks A-Z
  " noautocmd: hopping through buffers must not trigger BufEnter/BufWinEnter
  " handlers (statusline, mark reloading, ...)
  for l:b in filter(range(1, bufnr('$')), 'buflisted(v:val) && bufloaded(v:val)')
    silent! noautocmd keepalt execute 'buffer ' . l:b
    delmarks a-z
  endfor
  silent! noautocmd keepalt execute 'buffer ' . l:cur
  try
    call s:MarksWrite({'global': {}, 'local': {}})
  catch
    echohl ErrorMsg | echo '[marks] write error: ' . v:exception | echohl None
  endtry
  call s:MarksUpdateSigns()
  call s:MarksRefreshPanel()
  echo '[marks] deleted all marks'
endfunction

" ── Panel: build lines ────────────────────────────────────────
" Each panel line remembers its own jump target, so jumping no longer
" reads the JSON or guesses the file.
let s:marks_targets = {}

function! s:MarksBuildLines(data)
  let s:marks_targets = {}
  let lines = [
        \ '╔════════════════════════════════════════╗',
        \ '║          📍 ALL MARKS                 ║',
        \ '╚════════════════════════════════════════╝',
        \ '',
        \ ]
  let has_marks = 0

  if !empty(a:data.global)
    call add(lines, '🌍 GLOBAL MARKS:')
    for c in range(char2nr('A'), char2nr('Z'))
      let mark = nr2char(c)
      if has_key(a:data.global, mark)
        let info = a:data.global[mark]
        call add(lines, printf("  '%s  %s:%d", mark, fnamemodify(info.file, ':~:.'), info.lnum))
        let s:marks_targets[len(lines)] = info
        let has_marks = 1
      endif
    endfor
    call add(lines, '')
  endif

  if !empty(a:data.local)
    call add(lines, '📄 LOCAL MARKS BY FILE:')
    for fname in sort(keys(a:data.local))
      call add(lines, '  ' . fnamemodify(fname, ':~:.'))
      for c in range(char2nr('a'), char2nr('z'))
        let mark = nr2char(c)
        if has_key(a:data.local[fname], mark)
          let info = a:data.local[fname][mark]
          call add(lines, printf("    '%s  line %d", mark, info.lnum))
          let s:marks_targets[len(lines)] = extend({'file': fname}, info, 'keep')
          let has_marks = 1
        endif
      endfor
    endfor
    call add(lines, '')
  endif

  if !has_marks
    call add(lines, '  (no marks set)')
  endif
  call add(lines, '')
  call add(lines, 'ENTER / l — jump   q / <M-q> — close')
  return lines
endfunction

" ── Panel: refresh in-place ───────────────────────────────────
function! s:MarksRefreshPanel()
  if s:marks_win == -1 || !win_id2win(s:marks_win) | return | endif
  if s:marks_buf == -1 || !bufexists(s:marks_buf)  | return | endif
  let lines = s:MarksBuildLines(s:MarksMerged())
  call setbufvar(s:marks_buf, '&modifiable', 1)
  call deletebufline(s:marks_buf, 1, '$')
  call setbufline(s:marks_buf, 1, lines)
  call setbufvar(s:marks_buf, '&modifiable', 0)
endfunction

" ── Panel: jump from panel line ───────────────────────────────
function! s:MarksJump()
  let info = get(s:marks_targets, line('.'), {})
  if empty(info) | return | endif
  call s:MarksClosePanel()
  execute 'edit ' . fnameescape(info.file)
  call cursor(info.lnum, max([get(info, 'col', 1), 1]))
endfunction

" ── Panel: close ──────────────────────────────────────────────
function! s:MarksClosePanel()
  if s:marks_win != -1 && win_id2win(s:marks_win)
    call win_gotoid(s:marks_win)
    close
  endif
  let s:marks_win = -1
endfunction

" ── Panel: show / toggle ──────────────────────────────────────
function! s:MarksShow()
  if s:marks_win != -1 && win_id2win(s:marks_win)
    call s:MarksClosePanel()
    return
  endif

  call s:MarksSave()

  if s:marks_buf == -1 || !bufexists(s:marks_buf)
    let s:marks_buf = bufadd('')
    call setbufvar(s:marks_buf, '&buftype',   'nofile')
    call setbufvar(s:marks_buf, '&bufhidden', 'hide')
    call setbufvar(s:marks_buf, '&swapfile',  0)
    call bufload(s:marks_buf)
  endif

  let lines = s:MarksBuildLines(s:MarksMerged())
  call setbufvar(s:marks_buf, '&modifiable', 1)
  call deletebufline(s:marks_buf, 1, '$')
  call setbufline(s:marks_buf, 1, lines)
  call setbufvar(s:marks_buf, '&modifiable', 0)

  vsplit
  let s:marks_win = win_getid()
  execute 'buffer ' . s:marks_buf
  vertical resize 50

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

