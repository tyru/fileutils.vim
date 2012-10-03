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


" s:EX_COMMANDS {{{

let s:EX_COMMANDS = {
\   'FuOpen': {
\       'opt': '-bar -nargs=? -complete=dir',
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
\}

" }}}

function! fileutils#load(...) "{{{
    " Define Ex commands.
    " This can change those names like:
    "   call fileutils#load({
    "   \   'FuMap': 'Map',
    "   \   'FuDefMacroMap': 'DefMacroMap',
    "   \   'FuDefMap': 'DefMap',
    "   \   'FuSetPragmas': 'SetPragmas',
    "   \})
    "   call fileutils#load('noprefix')    " same as above

    let PREFIX = 'Fu'
    if a:0
        if type(a:1) == type({})
            let def_names = a:1
        elseif type(a:1) == type("") && a:1 ==# 'noprefix'
            let def_names = map(
            \   copy(s:EX_COMMANDS),
            \   'substitute(v:key, "^".PREFIX, "", "")'
            \)
        else
            call s:error("invalid arguments for fileutils#load().")
            return
        endif
    else
        let def_names = {}
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
endfunction "}}}


" :Open {{{1 
function! s:cmd_open(...) "{{{
    let dir =   a:0 == 1 ? a:1 : '.'

    if !isdirectory(dir)
        call s:warn(dir .': No such a directory')
        return
    endif

    if has('win32')
        " if dir =~ '[&()\[\]{}\^=;!+,`~ '. "']" && dir !~ '^".*"$'
        "     let dir = '"'. dir .'"'
        " endif
        call tyru#util#system('explorer', dir)
    else
        call tyru#util#system('gnome-open', dir)
    endif
endfunction "}}}


" :Copy (TODO) {{{1


" :Delete {{{1

function! s:cmd_delete(args, delete_buffer) "{{{
    if empty(a:args)
        return
    endif

    for file in a:args
        let file = expand(file)
        " let file = resolve(file)
        let bufnr = bufnr(file)

        " Delete the file.
        let type = getftype(file)
        if type ==# 'file'
            let success = 0
            if delete(file) !=# success
                call s:warn("Can't delete '" . file . "'")
                continue
            endif
        elseif type ==# 'dir'
            " TODO
        else
            redraw
            call s:warn(file . ": Unknown file type '" . type . "'.")
        endif

        " Delete the buffer.
        if a:delete_buffer && bufnr != -1
            if bufnr == bufnr('%')
                enew
            endif
            execute bufnr 'bwipeout'
        endif
    endfor

"     augroup vimrc-cmd-delete
"         autocmd FileChangedShell
"         \   let v:fcs_choice = ''
" 
"         checktime
" 
"         autocmd!
"     augroup END
    checktime
endfunction "}}}


" :Rename {{{1

function! s:cmd_rename(...) "{{{
    if a:0 == 1
        let [from, to] = [expand('%'), expand(a:1)]
    elseif a:0 == 2
        let [from, to] = [expand(a:1), expand(a:2)]
    else
        return
    endif
    if isdirectory(to)
        let to = to . '/' . fnamemodify(from, ':t')
    endif

    try
        call rename(from, to)
        if from ==# expand('%') && filereadable(to)
            edit `=to`
        endif
    catch
        call s:warn("Can't rename():" from "=>" to)
    endtry
endfunction "}}}


" :Mkdir {{{1
function! s:cmd_mkdir(...)
    for i in a:000
        call mkdir(expand(i), 'p')
    endfor
endfunction



" :Mkcd {{{1


" :Rmdir (TODO) {{{1

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
