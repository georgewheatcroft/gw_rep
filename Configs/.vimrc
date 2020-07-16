set encoding=utf-8
let using_neovim = has('nvim')
let using_vim = !using_neovim
"ensure that this plug vim is installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" Specify a directory for plugins
call plug#begin('~/.vim/plugged')
 Plug 'scrooloose/nerdtree'
 " Class/module browser
 Plug 'majutsushi/tagbar'
 " Search results counter
 Plug 'vim-scripts/IndexedSearch'

Plug 'crusoexia/vim-monokai' 
"Plug 'lsdr/monokai'
"Plug 'ErichDonGubler/vim-sublime-monokai'
syntax on
"Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'} --made
"things slow
 " Airline
 Plug 'vim-airline/vim-airline'
 Plug 'vim-airline/vim-airline-themes'
"indent line shows the lines for parantheses and general scope
Plug 'Yggdroot/indentLine'
 " Code and files fuzzy finder
 Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
 Plug 'junegunn/fzf.vim'
 Plug 'roxma/nvim-yarp'
 Plug 'roxma/vim-hug-neovim-rpc'
" Automatically close parenthesis, etc
 Plug 'Townk/vim-autoclose'
" language packs
Plug 'fatih/vim-go', { 'for': 'go', 'do': ':GoInstallBinaries' } 
Plug 'itchyny/lightline.vim'
Plug 'tpope/vim-eunuch'
" Initialize plugin system
call plug#end()

set term=screen-256color
set t_ut=

"lightline
let g:lightline = {
      \'colorscheme': 'wombat',
      \'component_function': {
      \'readonly': 'LightlineReadonly',
      \ },
      \	}

function! LightlineReadonly()
	  return &readonly && &filetype !=# 'help' ? 'RO' : ''
  endfunction

"set line numbers
set nu
"editor colourscheme
set laststatus=2
set background=dark
syntax on
" use 256 colors when possible

 if has('gui_running') || using_neovim || (&term =~? 'mlterm\|xterm\|xterm-256\|screen-256')
"     if !has('gui_running')
"           let &t_Co = 256
"                 endif
"                    "silent! colorscheme monokai 
                    colorscheme monokai
"                     else
"                         colorscheme delek
		      
                         endif
"se bg=dark
" needed so deoplete can auto select the first suggestion


autocmd BufEnter *.sh colorscheme slate
 set completeopt+=noinsert
" " comment this line to enable autocompletion preview window
" (displays documentation related to the selected completion option)
" " disabled by default because preview makes the window flicker
 set completeopt-=preview
"
" " autocompletion of files and commands behaves like shell
" " (complete only the common part, list the options that match)
 set wildmode=list:longest

" NERDTree -----------------------------
"
" " toggle nerdtree display
 map <F3> :NERDTreeToggle<CR>
" " open nerdtree with the current file selected
 nmap ,t :NERDTreeFind<CR>
" Remove expandable arrow
 let g:WebDevIconsNerdTreeBeforeGlyphPadding = ""
 let g:WebDevIconsUnicodeDecorateFolderNodes = v:true
 let NERDTreeDirArrowExpandable = "\u00a0"
 let NERDTreeDirArrowCollapsible = "\u00a0"
 let NERDTreeNodeDelimiter = "\x07"
 
" Autorefresh on tree focus
 function! NERDTreeRefresh()
     if &filetype == "nerdtree"
             silent exe substitute(mapcheck("R"), "<CR>", "", "")
    endif
    endfunction

    autocmd BufEnter * call NERDTreeRefresh()

" Deoplete -----------------------------
"
 " Use deoplete.
 let g:deoplete#enable_at_startup = 1
 let g:deoplete#enable_ignore_case = 1
 let g:deoplete#enable_smart_case = 1
 " complete with words from any opened file
 let g:context_filetype#same_filetypes = {}
 let g:context_filetype#same_filetypes._ = '_'

" Jedi-vim ------------------------------

 " Disable autocompletion (using deoplete instead)
 let g:jedi#completions_enabled = 0
" Disable vim-go :GoDef shortcut (gd)
let g:go_def_mapping_enabled = 0
"
"indentLine --------------------
let g:indentLine_char_list = ['|', '¦', '┆', '┊']
let g:indentLine_color_term = 239
set expandtab
"get rid of now redundant insert text
set noshowmode

" -------------------------------------------------------------------------------------------------
"  " coc.nvim default settings
"  "
"  -------------------------------------------------------------------------------------------------
"
  " if hidden is not set, TextEdit might fail.
  set hidden
  " Better display for messages
  set cmdheight=2
  " Smaller updatetime for CursorHold & CursorHoldI
  set updatetime=300
  " don't give |ins-completion-menu| messages.
  set shortmess+=c
  " always show signcolumns
  set signcolumn=yes

  " Use tab for trigger completion with characters ahead and navigate.
  " Use command ':verbose imap <tab>' to make sure tab is not mapped by other
"plugin.
inoremap <silent><expr> <TAB>
\ pumvisible() ? "\<C-n>" :
\ <SID>check_back_space() ? "\<TAB>" :
    \ coc#refresh()
    inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
let col = col('.') - 1
return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use U to show documentation in preview window
nnoremap <silent> U :call<SID>show_documentation()<CR>
  " Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)
 " Remap for format selected region
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocListdiagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocListextensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocListcommands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -Isymbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR> "
" disable vim-go :GoDef short cut (gd)
" " this is handled by LanguageClient [LC]
 let g:go_def_mapping_enabled = 0
