" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if exists('g:loaded_splitmove') && g:loaded_splitmove
    finish
endif
let g:loaded_splitmove = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


nnoremap <Plug>(splitmove-start)  :<C-u>call <SID>start()
command! -bar SplitMoveStart      call s:start()

function! s:start() abort
  if winnr('$') ==# 1
    echo 'No windows to select.'
    return
  endif

  let l:CloseIndicator = s:show_winnr_indicator()
  let l:target = s:select_target_winid()
  if l:target ==# 0
    echo 'Cancelled.'
    return
  endif
  call win_splitmove(winnr(), l:target)
  call l:CloseIndicator()
  redraw

  while 1
    let l:CloseIndicator = s:show_direction_indicator()
    redraw
    let l:dir = s:select_direction()
    if empty(l:dir)
      " TODO: <esc> to revert window layout
      break
    endif
    call win_splitmove(winnr(), l:target, l:dir)
    call l:CloseIndicator()
  endwhile
  redraw
endfunction


function! s:show_winnr_indicator() abort
  " TODO
  return {-> 42}
endfunction

function! s:show_direction_indicator() abort
  return {-> 42}
endfunction

function! s:select_target_winid() abort
  let l:curwin = winnr()
  let cands = range(1, winnr('$'))->filter('v:val !=# l:curwin')
  let l:nr = confirm(
  \ 'Select Window:',
  \ cands->join("\n"))
  if l:nr ==# 0
    return 0
  endif
  return win_getid(cands[l:nr - 1])
endfunction

function! s:select_direction() abort
  let l:nr = confirm(
  \   'Select Direction:',
  \   ['h: left', 'j: down', 'k: up', 'l: right', "e: exit"]->join("\n"),
  \   5)
  if l:nr ==# 0 || l:nr ==# 5
    return {}
  endif
  return [
  "\ 'h'
  \ {'vertical': 1, 'rightbelow': 0},
  "\ 'j'
  \ {'vertical': 0, 'rightbelow': 1},
  "\ 'k'
  \ {'vertical': 0, 'rightbelow': 0},
  "\ 'l'
  \ {'vertical': 1, 'rightbelow': 1},
  \][l:nr - 1]
endfunction


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
