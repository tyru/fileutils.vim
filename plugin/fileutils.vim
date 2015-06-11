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


let g:fileutils_commands = get(g:, 'fileutils_commands', {})


" Define commands {{{

" s:EX_COMMANDS {{{

let s:EX_COMMANDS = {
\   'FuOpen': {
\       'opt': '-bar -nargs=1 -complete=file',
\       'def': 'call s:cmd_open(<f-args>)',
\   },
\   'FuDelete': {
\       'opt': '-bar -bang -nargs=+ -complete=file',
\       'def': 'call s:cmd_delete([<f-args>], <bang>0)',
\   },
\   'FuCopy': {
\       'opt': '-bar -nargs=+ -complete=file',
\       'def': 'call s:cmd_copy(<f-args>)',
\   },
\   'FuRename': {
\       'opt': '-bar -nargs=+ -complete=file',
\       'def': 'call s:cmd_rename(<f-args>)',
\   },
\   'FuMkdir': {
\       'opt': '-bar -nargs=+ -complete=dir',
\       'def': 'call s:cmd_mkdir(<f-args>)',
\   },
\   'FuMkcd': {
\       'opt': '-bar -nargs=1 -complete=dir',
\       'def': 'silent! Mkdir <args> | cd <args>',
\   },
\   'FuFile': {
\       'opt': '-bar -nargs=1 -complete=file',
\       'def': 'call s:cmd_file(<f-args>)',
\   },
\   'FuChmod': {
\       'opt': '-bar -nargs=+ -complete=customlist,s:complete_chmod',
\       'def': 'call s:cmd_chmod(<f-args>)',
\   },
\}

" }}}

function! s:define(arg) " {{{
    if type(a:arg) == type({})
        let def_names = a:arg
    elseif type(a:arg) == type("") && a:arg ==# 'noprefix'
        let def_names = map(
        \   copy(s:EX_COMMANDS),
        \   'substitute(v:key, "^Fu", "", "")'
        \)
    else
        call s:error("invalid arguments for fileutils#load().")
        return
    endif

    for [name, info] in items(s:EX_COMMANDS)
        let def =
        \   substitute(
        \       info.def,
        \       '<cmdname>\C',
        \       string(name),
        \       ''
        \   )
        execute
        \   'command!'
        \   info.opt
        \   get(def_names, name, name)
        \   def
    endfor
endfunction " }}}

call s:define(g:fileutils_commands)

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
