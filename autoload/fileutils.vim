" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Vital {{{
let s:Vital = {}
let s:Prelude = {}
let s:List = {}
let s:File = {}
let s:Filepath = {}

function! s:Vital()
    if !empty(s:Vital)
        return s:Vital
    endif
    let s:Vital = vital#of('fileutils')
    return s:Vital
endfunction

function! s:Prelude()
    if !empty(s:Prelude)
        return s:Prelude
    endif
    let s:Prelude = s:Vital().import('Prelude')
    return s:Prelude
endfunction

function! s:List()
    if !empty(s:List)
        return s:List
    endif
    let s:List = s:Vital().import('Data.List')
    return s:List
endfunction

function! s:File()
    if !empty(s:File)
        return s:File
    endif
    let s:File = s:Vital().import('System.File')
    return s:File
endfunction

function! s:Filepath()
    if !empty(s:Filepath)
        return s:Filepath
    endif
    let s:Filepath = s:Vital().import('System.Filepath')
    return s:Filepath
endfunction

" }}}

if !exists('g:fileutils_debug')
    let g:fileutils_debug = 0
endif

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


function! s:echomsg(msg, ...) "{{{
    if a:0 > 0
        execute 'echohl' a:1
    endif
    try
        echomsg a:msg
    finally
        if a:0 > 0
            echohl None
        endif
    endtry
endfunction "}}}
function! s:warn(msg) "{{{
    call s:echomsg(a:msg, 'WarningMsg')
endfunction "}}}
function! s:error(msg) "{{{
    call s:echomsg(a:msg, 'Error')
endfunction "}}}
function! s:debug(...) "{{{
    if g:fileutils_debug
        call call('s:echomsg', a:000 + (a:0 == 1 ? ['Debug'] : []))
    endif
endfunction "}}}


" :FuOpen {{{1
function! s:cmd_open(path) "{{{
    let path = resolve(a:path)
    let ftype = getftype(path)
    if ftype !=# 'dir' && ftype !=# 'file'
        call s:warn("'" . path ."' is neither dir nor file.")
        return
    endif

    if s:Prelude().is_windows()
        " explorer.exe does not correctly handle a path with slashes!
        " (opens %USERPROFILE% if invalid path was given)
        let path = substitute(path, '/', '\', 'g')
        " cp932 is Japanese cmd.exe encoding
        " TODO: i18n
        let path = iconv(path, &encoding, 'cp932')
        if ftype ==# 'dir'
            silent execute '!start explorer' path
        else
            silent execute '! start' path
        endif
    else
        silent execute '!gnome-open' dir
    endif
endfunction "}}}


" :FuCopy {{{1

function! s:cmd_copy(...)
    call call('s:do_rename_or_copy', [0] + a:000)
endfunction

" :FuDelete {{{1

function! s:cmd_delete(args, delete_buffer) "{{{
    if empty(a:args)
        return
    endif

    for file in s:List().flatten(map(a:args, 's:Prelude().glob(v:val)'))
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
            continue
        else
            redraw
            call s:warn(file . ": Unknown file type '" . type . "'.")
            continue
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


" :FuRename {{{1

" Usage:
" * FuRename SOURCE
" * FuRename SOURCE DESTINATION
" * FuRename [SOURCES ...] DESTINATION
function! s:cmd_rename(...)
    call call('s:do_rename_or_copy', [1] + a:000)
endfunction

function! s:do_rename_or_copy(rename, ...)
    let files = s:get_files_list(a:000)
    if empty(files)
        throw 'len(files) must not be zero!'
    endif
    if len(files) == 1
        call insert(files, expand('%'))
    endif
    let to = remove(files, -1)
    let from_files = files

    for from in from_files
        call s:do_rename_or_copy_one(a:rename, from, to)
    endfor
    " Reload changed buffer.
    " (for safety, maybe Vim automatically do this)
    checktime
endfunction

function! s:get_files_list(files)
    let newline = '\n'
    return s:List().flatten(map(copy(a:files), 'split(expand(v:val), newline)'))
endfunction

function! s:do_rename_or_copy_one(rename, from, to)
    let [from, to] = [a:from, a:to]

    if getftype(from) ==# ''
        echoerr "fileutils: No such a file: '" . from . "'"
        continue
    endif
    if isdirectory(to)
        let to = to . '/' . fnamemodify(from, ':t')
    endif

    if filereadable(to) && input("file '".to."' exists, overwrite? [y/n]:") !~? '^y\%[es]'
        redraw
        echo 'Canceled.'
        return
    endif

    let from = s:Filepath().unify_separator(from)
    let to   = s:Filepath().unify_separator(to)
    let op   = (a:rename ? 'move' : 'copy')
    let ret  = s:File()[op](from, to)
    let dest_doesnt_exist = getftype(to) ==# ''
    if !ret || dest_doesnt_exist
        call s:echomsg('Could not ' . op . ' a file or directory.')
        if !ret
            call s:debug('File.' . op . '() returned zero value.')
        endif
        if dest_doesnt_exist
            call s:debug('Destination path does not exist: ' . to)
        endif
    else
        call s:echomsg(printf((a:rename ? 'Renamed' : 'Copied') . ': %s -> %s', from, to))
    endif
endfunction


" :FuMkdir {{{1
function! s:cmd_mkdir(...)
    for i in a:000
        call mkdir(expand(i), 'p')
    endfor
endfunction



" :FuMkcd {{{1

" See s:EX_COMMANDS .


" :FuRmdir (TODO) {{{1


" :FuFile {{{1

function! s:cmd_file(file)
    let ftype = getftype(a:file)
    call s:echomsg("'".a:file."' is '".(ftype !=# '' ? ftype : 'unknown')."'.")
endfunction


" :FuChmod {{{1

function! s:cmd_chmod(opt, ...)
    if !executable('chmod')
        echoerr 'fileutils: chmod is not in the PATH.'
        return
    endif
    let file = a:0 ? a:1 : expand('%')
    if !filereadable(file)
        echoerr "fileutils: '".file."' is not readable."
        return
    endif
    if !s:check_chmod_opt(a:opt)
        echoerr "fileutils: '".a:opt."' is not valid mode."
        return
    endif

    silent execute '!chmod '.a:opt.' '.file
endfunction

let s:MODE_REGEX = '[ugoa]*\%([-+=]\%([rwxXst]*\|[ugo]\)\)\+'
function! s:check_chmod_opt(opt)
    " from manpage of chmod(1)
    return a:opt =~# '^'.s:MODE_REGEX.'$'
endfunction

function! s:complete_chmod(arglead, cmdline, cursorpos)
    let cmdline = substitute(a:cmdline, '^[A-Z][A-Za-z0-9]*\s*', '', '')
    if cmdline =~# '^\s*$'
        " Return most frequently used MODE arguments.
        return ['+r', '+w', '+x', '-r', '-w', '-x']
    elseif cmdline =~# '^\s*'.s:MODE_REGEX.'\s\+'
        " Return files.
        let files = s:Prelude().glob(a:arglead.'*')
        if len(files) is 1
        \  && isdirectory(a:arglead)
        \  && a:arglead !~# '/$'
            return [a:arglead.'/']
        endif
        return files
    elseif cmdline =~# '^\s*'.s:MODE_REGEX
        " A complete MODE argument.
        return [a:arglead.' ']
    elseif cmdline =~# '^\s*[ugoa]$'
        " Incomplete MODE argument.
        return map(['+r', '+w', '+x', '-r', '-w', '-x'],
        \          'a:arglead.v:val')
    elseif cmdline =~# '^\s*[+-]'
        " Incomplete MODE argument.
        return map(['r', 'w', 'x'],
        \          'a:arglead.v:val')
    endif
endfunction


" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
