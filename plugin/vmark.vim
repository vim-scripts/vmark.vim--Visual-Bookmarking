" File: vmark.vim
" Author: Michael Zhou <michael.zhou@gmail.com>
" Version: 1.2
" Last Modified: Wed Jun 13 17:07:08 EDT 2012
" Description: Toggle visual bookmarks and jump through bookmarks
" Uasge:
"   Normal Mode
"     mm     Toggle visual bookmark current line
"     ma     Remove all bookmarks
"     mn     Move to next bookmark below current line.
"            Will wrap around at end.
"     <F2>   Same as above (mn)
"     mp     Move to previous bookmark above current line.
"            Will wrap around at top.
"     <F3>   Same as above (mp)
"
" Installation:
"   Copy vmark.vim to .vim/plugin directory
"
" Configuration:
"     b:vm_maxmarks - Max number of bookmarks allowed in a buffer
"     b:vm_guifg    - Foreground color for bookmarked line in GVIM
"     b:vm_guibg    - Background color for bookmarked line in GVIM
"     b:vm_ctermfg  - Foreground color for bookmarked line in VIM
"     b:vm_ctermbg  - Background color for bookmarked line in VIM
"
" Limitation:
"   If syntax highlighting based on keywords is turned on and the line being
"   bookmarked starts with a keyword, the keyword may not be highlighted
"   but the rest of the line after the keyword should be highlighted normally.
"
" Acknowledgement:
"   Took cues from Amit Sethi's highlight.vim
"   http://www.vim.org/scripts/script.php?script_id=1599
"

" Toggle bookmark on current line
function! <SID>VMarkToggle()
    call s:InitVMarkVariables()
    let lineno = line(".")
    if count(b:vm_markedlines, lineno) > 0
        call s:VMarkClear(lineno)
    else
        call s:VMarkSet(lineno)
    endif
endfunction

" Set bookmark on current line
function! s:VMarkSet(lineno)
    if count(b:vm_markedlines, a:lineno) > 0
        echo "Line ".line(".")." already bookmarked."
    else
        if empty(b:vm_availablemarks)
            echo "Max number of bookmarks reached. ".
                \"Increase b:vm_maxmarks in plugin/vmark.vim"
        else
            call add(b:vm_markedlines, a:lineno)
            call sort(b:vm_markedlines, "s:NumComparator")
            let c = remove(b:vm_availablemarks, 0)
            let b:vm_linecolormapping[a:lineno] = c
            exec 'syn match '.c.' ".*\%'.line(".").'l.*" containedin=ALL'
        endif
    endif
endfunction

" Clear bookmark on current line
function! s:VMarkClear(lineno)
    if count(b:vm_markedlines, a:lineno) == 0
        echo "Line ".line(".")." not bookmarked."
    else
        let c = remove(b:vm_linecolormapping, a:lineno)
        call add(b:vm_availablemarks, c)
        let idx = 0
        let cnt = len(b:vm_markedlines)
        while idx < cnt
            if a:lineno == get(b:vm_markedlines, idx)
                call remove(b:vm_markedlines, idx)
                break
            endif
            let idx = idx + 1
        endwhile
        echo "Cleared bookmark on line: ".a:lineno
        exec 'syn clear '.c.' ".*\%'.a:lineno.'l.*" containedin=ALL'
    endif
endfunction

" Clear all bookmarks
function! <SID>VMarkClearAll()
    call s:InitVMarkVariables()
    if len(b:vm_markedlines) == 0
        echo "No bookmarks found."
    else
        let idx = 0
        let cnt = len(b:vm_markedlines)
        while idx < cnt
            let lineno = get(b:vm_markedlines, idx)
            let c = remove(b:vm_linecolormapping, lineno)
            call add(b:vm_availablemarks, c)
            exec 'syn clear '.c.' ".*\%'.lineno.'l.*" containedin=ALL'
            let idx = idx + 1
        endwhile
        let b:vm_markedlines = []
        let b:vm_linecolormapping = {}
    endif
endfunction

" Move to next bookmark below current line.
" Will wrap around at last bookmark.
function! <SID>VMarkNext()
    call s:InitVMarkVariables()
    if empty(b:vm_markedlines)
        echo "No bookmarks found."
        return
    endif
    let cnt = len(b:vm_markedlines)
    let idx = 0
    let line1 = 0
    let line2 = 0
    let curline = line(".")
    if curline >= get(b:vm_markedlines, -1) ||
        \ curline < get(b:vm_markedlines, 0)
        let curline = get(b:vm_markedlines, 0)
    else
        while idx < cnt - 1
            let line1 = get(b:vm_markedlines, idx)
            let line2 = get(b:vm_markedlines, idx + 1)
            if line1 <= curline && curline < line2
                let curline = line2
                break
            endif
            let idx = idx + 1
        endwhile
    endif
    echo "Moving to line: ".curline
    call cursor(curline, 1)
endfunction

" Move to previous bookmark.
" Will wrap around at first bookmark.
function! <SID>VMarkPrevious()
    call s:InitVMarkVariables()
    if empty(b:vm_markedlines)
        echo "No bookmarks found."
        return
    endif
    let cnt = len(b:vm_markedlines)
    let idx = cnt - 2
    let line1 = 0
    let line2 = 0
    let curline = line(".")
    if curline > get(b:vm_markedlines, -1) ||
        \ curline <= get(b:vm_markedlines, 0)
        let curline = get(b:vm_markedlines, -1)
    else
        while idx >= 0
            let line1 = get(b:vm_markedlines, idx)
            let line2 = get(b:vm_markedlines, idx + 1)
            if line1 < curline && curline <= line2
                let curline = line1
                break
            endif
            let idx = idx - 1
        endwhile
    endif
    echo "Moving to line: ".curline
    call cursor(curline, 1)
endfunction

" Initialize variables
function! s:InitVMarkVariables()
    " Color name prefix
    if !exists("b:vm_colorprefix")
        let b:vm_colorprefix = 'VMarkColor'
    endif
    " Bookmarked line numbers
    if !exists("b:vm_markedlines")
        let b:vm_markedlines = []
    endif
    "
    " TODO
    " Could be improved to have just one data structure
    " which is the dictionary to store marked lines
    " as well as line number to color mappings.
    " Need to take care of sorting dictionary first.
    " Could not find a built-in function for the task.
    "
    " Bookmarked lines to color name mapping
    if !exists("b:vm_linecolormapping")
        let b:vm_linecolormapping = {}
    endif
    " Max number of bookmarks allowed in a buffer
    if !exists("b:vm_maxmarks")
        let b:vm_maxmarks = 50
    endif
    " Foreground color for the bookmarked line in GVIM
    if !exists("b:vm_guifg")
        let b:vm_guifg = 'white'
    endif
    " Background color for the bookmarked line in GVIM
    if !exists("b:vm_guibg")
        let b:vm_guibg = 'red'
    endif
    " Foreground color for the bookmarked line in VIM
    if !exists("b:vm_ctermfg")
        let b:vm_ctermfg = 'black'
    endif
    " Background color for the bookmarked line in VIM
    if !exists("b:vm_ctermbg")
        let b:vm_ctermbg = 'yellow'
    endif
    " Available bookmarks
    if !exists("b:vm_availablemarks")
        let b:vm_availablemarks = []
        let idx = 0
        while idx < b:vm_maxmarks
            call add(b:vm_availablemarks, b:vm_colorprefix.idx)
            exec 'hi '. b:vm_colorprefix . idx .
                \ ' guifg=' . b:vm_guifg . ' guibg=' . b:vm_guibg .
                \ ' ctermfg=' . b:vm_ctermfg . ' ctermbg=' . b:vm_ctermbg
            let idx = idx + 1
        endwhile
    endif
endfunction

" Highlight all marked lines
function! s:VMarkHighlightAll()
    call s:InitVMarkVariables()
    let cnt = len(b:vm_markedlines)
    if cnt != 0
        let idx = 0
        while idx < cnt
            let lineno = b:vm_markedlines[idx]
            let c = b:vm_linecolormapping[lineno]
            exec 'syn match '.c.' ".*\%'.lineno.'l.*" containedin=ALL'
            let idx = idx + 1
        endwhile
    endif
endfunction

" Numeric number comparison function
" Surprised that VIM does not have a built-in
function! s:NumComparator(i1, i2)
    return a:i1 - a:i2
endfunction

" Key mappings
nnoremap <silent> mm :call <sid>VMarkToggle()<cr>
nnoremap <silent> mn :call <sid>VMarkNext()<cr>
nnoremap <silent> <F2> :call <sid>VMarkNext()<cr>
nnoremap <silent> mp :call <sid>VMarkPrevious()<cr>
nnoremap <silent> <F3> :call <sid>VMarkPrevious()<cr>
nnoremap <silent> ma :call <sid>VMarkClearAll()<cr>

" Initialization
call s:InitVMarkVariables()

" Highlight all marked lines when a buffer is loaded
autocmd BufEnter * call s:VMarkHighlightAll()
