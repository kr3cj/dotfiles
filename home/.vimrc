filetype plugin indent on
syntax on
set hlsearch
" set cursorline
set confirm
set history=1000
"give three lines of context when moving the cursor around
set scrolloff=3
"allow delete and backspace keys in insert mode"
set backspace=indent,eol,start
nnoremap <BS> X
set ruler

au BufReadPost Jenkinsfile setlocal filetype=groovy

"Clipboard settings{{{
  "Ensure vim uses system clipboard (tested on macos)
  "Note that linux needs +xterm_clipboard feature compiled in
  "Should also work on Windows
  if has('nvim')
    set clipboard=unnamedplus
  else
    set clipboard=unnamedplus,unnamed,autoselect
  endif
"}}}

" Map trailing whitespace deleting to F6 key
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()
" Press F6 to remove all trailing whitespace.
nnoremap <silent> <F6> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar>:nohl<CR>

" Automatic indenting and tab key uses spaces
set smartindent  "Automatic indenting
set autoindent
set expandtab   "Enable for tabs to become spaces
set tabstop=2    "Number of spaces a tab mimics
set softtabstop=2 "Ensure spaces can be easily deleted
set shiftwidth=2 "?
" Highlight tabs so that we may destroy them
set list listchars=tab:»·
" To replace tabs, type ':retab' inside the file
" nnoremap <silent> <F2> :<C-U>setlocal lcs=tab:>-,trail:-,eol:$ list! list? <CR>

" For sorting visual blocks, see https://github.com/yaroot/vissort

" Automatic paste mode (https://coderwall.com/p/if9mda/automatically-set-paste-mode-in-vim-when-pasting-in-insert-mode)
let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  return ""
endfunction
