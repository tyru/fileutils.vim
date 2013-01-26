" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Vital {{{
let s:V = vital#of('fileutils.vim')
let s:L = s:V.import('Data.List')
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


function! s:echomsg(hl, msg) "{{{
    execute 'echohl' a:hl
    try
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction "}}}
function! s:warn(msg) "{{{
    call s:echomsg('WarningMsg', a:msg)
endfunction "}}}
function! s:error(msg) "{{{
    call s:echomsg('Error', a:msg)
endfunction "}}}


" :FuOpen {{{1
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


" :FuCopy (TODO) {{{1


" :FuDelete {{{1

function! s:cmd_delete(args, delete_buffer) "{{{
    if empty(a:args)
        return
    endif

    for file in s:L.flatten(map(a:args, 's:V.glob(v:val)'))
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


" :FuRename {{{1

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
    if filereadable(to) && input("file '".to."' exists, overwrite? [y/n]:") !~? '^y\%[es]'
        redraw
        echo 'Canceled.'
        return
    endif

    try
        let from_winnr = bufwinnr(bufnr(from))
        if from_winnr isnot -1
            " Use :saveas for a visible buffer.
            let prev_winnr = winnr()
            if from_winnr isnot prev_winnr
                execute from_winnr.'wincmd w'
            endif
            try
                saveas! `=to`
            finally
                if from_winnr isnot prev_winnr
                    execute prev_winnr.'wincmd w'
                endif
            endtry
            call delete(from)
        else
            " Use rename() for an invisible or non-loaded buffer.
            call rename(from, to)
        endif

        if !filereadable(to)
            throw "fileutil: renamed file is not readable: ".to
        endif
        " Reload changed buffer. (for safety)
        checktime
    catch
        call s:warn("fileutil: Can't rename() ".from." to ".to.": ".v:exception)
    endtry
endfunction "}}}


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
    echom "'".a:file."' is '".(ftype !=# '' ? ftype : 'unknown')."'."
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
        let files = s:V.glob(a:arglead.'*')
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
