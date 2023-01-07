scriptencoding utf-8

function! s:get_channel() abort
  if !exists('s:job') || job_status(s:job) !=# 'run'
    if has('nvim')
      let s:ch = jobstart(['chatgpt', '-json'], {'in_mode': 'json', 'out_mode': 'nl', 'noblock': 1, 'on_stdout': function('s:nvim_chatgpt_cb_out'), 'on_stderr': function('s:nvim_chatgpt_cb_err')})
    else
      let s:job = job_start(['chatgpt', '-json'], {'in_mode': 'json', 'out_mode': 'nl', 'noblock': 1})
      let s:ch = job_getchannel(s:job)
    endif
  endif
  return s:ch
endfunction

function! s:chatgpt_cb_out(ch, msg) abort
  let l:msg = json_decode(a:msg)
  let l:winid = bufwinid('__CHATGPT__')
  if l:winid ==# -1
    silent noautocmd split __CHATGPT__
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal wrap nonumber signcolumn=no filetype=markdown
    wincmd p
    let l:winid = bufwinid('__CHATGPT__')
  endif
  call win_execute(l:winid, 'setlocal modifiable', 1)
  call win_execute(l:winid, 'silent normal! GA' .. l:msg['text'], 1)
  if l:msg['error'] != ''
    call win_execute(l:winid, 'silent normal! Go' .. l:msg['error'], 1)
  elseif l:msg['eof']
    call win_execute(l:winid, 'silent normal! Go', 1)
  endif
  call win_execute(l:winid, 'setlocal nomodifiable nomodified', 1)
endfunction

function! s:chatgpt_cb_err(ch, msg) abort
  echohl ErrorMsg | echom '[chatgpt ch err] ' .. a:msg | echohl None
endfunction

function! s:nvim_chatgpt_cb_out(job_id, data, event) abort
  let l:data = json_decode(a:data)
  let l:winid = bufwinid('__CHATGPT__')
  if l:winid ==# -1
    silent noautocmd split __CHATGPT__
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal wrap nonumber signcolumn=no filetype=markdown
    wincmd p
    let l:winid = bufwinid('__CHATGPT__')
  endif
  call win_execute(l:winid, 'setlocal modifiable', 1)
  call win_execute(l:winid, 'silent normal! GA' .. l:data['text'], 1)
  if l:data['error'] != ''
    call win_execute(l:winid, 'silent normal! Go' .. l:data['error'], 1)
  elseif l:data['eof']
    call win_execute(l:winid, 'silent normal! Go', 1)
  endif
  call win_execute(l:winid, 'setlocal nomodifiable nomodified', 1)
endfunction

function! s:nvim_chatgpt_cb_err(job_id, data, event) abort
  echohl ErrorMsg | echom '[chatgpt ch err] ' .. a:data | echohl None
endfunction

function! chatgpt#send(text) abort
  let l:ch = s:get_channel()
  if has('nvim')
    call chansend(l:ch, json_encode({'text': a:text}))
  else
    call ch_setoptions(l:ch, {'out_cb': function('s:chatgpt_cb_out'), 'err_cb': function('s:chatgpt_cb_err')})
    call ch_sendraw(l:ch, json_encode({'text': a:text}))
  endif
endfunction

function! chatgpt#code_review_please() abort
  let l:lang = get(g:, 'chatgpt_lang', $LANG)
  let l:question = l:lang =~# '^ja' ? 'このプログラムをレビューして下さい。' : 'please code review'
  let l:lines = [
  \  l:question,
  \  '',
  \] + getline(1, '$')
  call chatgpt#send(join(l:lines, "\n"))
endfunction
