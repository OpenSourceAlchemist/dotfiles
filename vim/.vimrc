syntax on
set et
set ts=2
set sw=2
set bg=dark

" command W !git diff-index --quiet HEAD || git commit -am auto
" autocmd BufWritePost * call AutoCommit()
command W call AutoCommit()
function! AutoCommit()
  execute ':w'
  call system('git rev-parse --git-dir > /dev/null 2>&1')
  if v:shell_error
    return
  endif
  let message = '__auto_update__:' . expand('%:.')
  call system('git add ' . expand('%:p'))
  call system('git commit -m ' . shellescape(message, 1))
endfun
command P call AutoPush()
function! AutoPush()
  execute ':W'
  call system('git push')
endfun

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
