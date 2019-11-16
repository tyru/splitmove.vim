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
  call s:select_target_winid(function('s:cb_target_winid', [l:CloseIndicator]))
endfunction

function! s:cb_target_winid(CloseIndicator, target) abort
  call a:CloseIndicator()
  if a:target ==# 0
    echo 'Cancelled.'
    return
  endif
  call win_splitmove(winnr(), a:target)
  redraw

  call s:select_direction(a:target)
endfunction

function! s:show_winnr_indicator() abort
  for l:winnr in range(1, winnr('$'))
    call popup_create(['(' . winnr . ')'], s:get_winnr_pos(l:winnr))
  endfor
  return {->popup_clear()}
endfunction

function! s:show_direction_indicator() abort
  call popup_create(['(' . winnr() . ')'], s:get_winnr_pos(winnr()))
  return {->popup_clear()}
endfunction

function! s:get_winnr_pos(winnr) abort
  let l:pos = win_screenpos(a:winnr)
  return #{
  \ line: l:pos[0], col: l:pos[1],
  \}
endfunction

function! s:select_target_winid(callback) abort
  let l:curwin = winnr()
  let l:cands = range(1, winnr('$'))
              \->filter({-> v:val !=# l:curwin})
  let l:display_cands = l:cands
              \->copy()
              \->map({-> printf('(%d) %s', v:val, bufname(v:val) ==# '' ? '[No Name]' : bufname(v:val))})
  call s:popup_confirm('Select Target Window:', l:display_cands, 0, {winid, nr ->
  \ a:callback(win_getid(l:cands[l:nr - 1]))
  \})
endfunction

function! s:popup_confirm(prompt, cands, default_nr, callback) abort
  if empty(a:cands)
    throw 's:popup_confirm(): the 2nd arg must not be empty!'
  endif
  let l:prompt = a:prompt->split("\n", 1)
  let l:ctx = s:new_popup_context(
  \ #{selected: 0, prompt: l:prompt, cands: a:cands->copy()}
  \)
  let l:winid = popup_create(l:prompt + a:cands, #{
  \ pos: 'center',
  \ zindex: 200,
  \ drag: 1,
  \ wrap: 0,
  \ border: [],
  \ cursorline: 1,
  \ filter: function('s:popup_confirm_filter', [l:ctx]),
  \ filtermode: 'n',
  \ padding: [0,1,0,1],
  \ callback: a:callback,
  \})
  call win_execute(l:winid, 'normal! 2G')
endfunction

let s:PopupContext = {}

function! s:new_popup_context(ctx) abort
  return extend(s:PopupContext->deepcopy(), a:ctx->deepcopy())
endfunction

function! s:popup_context_down(winid) abort dict
  if self.cands->len() > self.selected + 1
    let self.selected += 1
    let l:lnum = self.prompt->len() + self.selected + 1
    call win_execute(a:winid, 'normal! ' . l:lnum . 'G')
  endif
endfunction
let s:PopupContext.down = function('s:popup_context_down')

function! s:popup_context_up(winid) abort dict
  if self.selected > 0
    let self.selected -= 1
    let l:lnum = self.prompt->len() + self.selected + 1
    call win_execute(a:winid, 'normal! ' . l:lnum . 'G')
  endif
endfunction
let s:PopupContext.up = function('s:popup_context_up')

function! s:popup_confirm_filter(ctx, winid, key) abort
  if a:key ==# 'j'
    call a:ctx.down(a:winid)
    return 1
  elseif a:key ==# 'k'
    call a:ctx.up(a:winid)
    return 1
  elseif a:key ==# "\<Esc>"
    call popup_close(a:winid, 0)
    return 1
  elseif a:key ==# "\<Enter>"
    call popup_close(a:winid, a:ctx.selected + 1)
    return 1
  endif
  return 0
endfunction

function! s:select_direction(target) abort
  let l:winid = popup_create(
  \ [
  \   'Select Direction:',
  \   '  h: left',
  \   '  j: down',
  \   '  k: up',
  \   '  l: right',
  \   '  e,<Enter>: exit',
  \ ],
  \ #{
  \   pos: 'center',
  \   zindex: 200,
  \   drag: 1,
  \   wrap: 0,
  \   border: [],
  \   filter: function('s:popup_direction_filter', [a:target]),
  \   filtermode: 'n',
  \   padding: [0,1,0,1],
  \})
  call win_execute(l:winid, 'normal! 2G')
endfunction

function! s:popup_direction_filter(target, winid, key) abort
  if a:key ==# 'j'
    call win_splitmove(winnr(), a:target, #{vertical: 0, rightbelow: 1})
    return 1
  elseif a:key ==# 'k'
    call win_splitmove(winnr(), a:target, #{vertical: 0, rightbelow: 0})
    return 1
  elseif a:key ==# 'h'
    call win_splitmove(winnr(), a:target, #{vertical: 1, rightbelow: 0})
    return 1
  elseif a:key ==# 'l'
    call win_splitmove(winnr(), a:target, #{vertical: 1, rightbelow: 1})
    return 1
  elseif a:key ==# "\<Esc>"
    " TODO: <esc> to revert window layout
    call popup_close(a:winid, 0)
    return 1
  elseif a:key ==# "\<Enter>" || a:key ==# 'e'
    call popup_close(a:winid, 0)
    return 1
  endif
  return 0
endfunction



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
