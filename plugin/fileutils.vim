" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if (exists('g:loaded_fileutils') && g:loaded_fileutils) || &cp
    finish
endif
let g:loaded_fileutils = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

function! s:loaded(script)
    redir => lines
    silent scriptnames
    redir END

    for l in split(lines, '\n')
        let m = matchlist(l, '^\s*\(\d\+\): \(.\+\)$')
        if get(m, 2, '') =~# a:script
            return 1
        endif
    endfor
    return 0
endfunction

if !s:loaded('autoload/fileutils.vim')
    echomsg "fileutils: 'call fileutils#load(\"noprefix\")' to use this script in vimrc."
    " TODO: doc/fileutils.txt
    " echomsg "fileutils: see :help fileutils for more details..."
endif


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
