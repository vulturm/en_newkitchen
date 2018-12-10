set noet ci pi sts=0 sw=2 ts=2
colorscheme delek
:set copyindent
:set preserveindent
:set softtabstop=0
:set shiftwidth=2
:set tabstop=2
filetype plugin indent on
set expandtab
set hlsearch
set pastetoggle=<F2>
autocmd FileType ruby map <F9> :w<CR>:!ruby -c %<CR>
map <F8> :s/^#//<CR>
map <F7> :s/^/#/<CR>
color desert
syntax on
