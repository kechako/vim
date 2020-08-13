" vim-lsp
let g:lsp_text_edit_enabled = 0
let g:lsp_async_completion = 1
let g:lsp_signs_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_signs_error = {'text': '!!'}
let g:lsp_signs_warning = {'text': '! '}
let g:lsp_signs_information = {'text': 'i '}
let g:lsp_signs_hint = {'text': '? '}

let g:lsp_preview_keep_focus = 1

function s:find_root_uri(filename)
  return lsp#utils#path_to_uri(
        \   lsp#utils#find_nearest_parent_file_directory(
        \     lsp#utils#get_buffer_path(),
        \     a:filename
        \   )
        \)
endfunction

function s:on_lsp_buffer_enabled()
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes

  nmap <buffer><silent> gd        <plug>(lsp-definition)
  nmap <buffer><silent> <C-]>     <plug>(lsp-definition)
  nmap <buffer><silent> gD        <plug>(lsp-references)
  nmap <buffer><silent> <leader>s <plug>(lsp-document-symbol)
  nmap <buffer><silent> <leader>y <plug>(lsp-workspace-symbol)
  nmap <buffer><silent> <leader>f <plug>(lsp-document-format)
  nmap <buffer><silent> <leader>k <plug>(lsp-hover)
  nmap <buffer><silent> <leader>i <plug>(lsp-implementation)
  nmap <buffer><silent> <leader>n <plug>(lsp-rename)
  nmap <buffer><silent> <leader>a <plug>(lsp-code-action)
  nmap <buffer><silent> <leader>e <plug>(lsp-next-error)
  nmap <buffer><silent> <leader>m :make<CR>
endfunction

" Go
if executable('gopls')
  autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'golang',
        \ 'cmd': {server_info->['gopls', 'serve']},
        \ 'root_uri': {server_info->s:find_root_uri(['go.mod', '.git/'])},
        \ 'initialization_options': {
        \   'buildFlags': '',
        \   'env': '',
        \   'hoverKind': 'FullDocumentation',
        \   'usePlaceholders': v:true,
        \   'staticcheck': v:true,
        \   'completionDocumentation': v:true,
        \   'completeUnimported': v:true,
        \   'matcher': 'caseSensitive',
        \ },
        \ 'whitelist': ['go'],
        \ })

  autocmd FileType go autocmd BufWritePre <buffer> LspDocumentFormatSync
  autocmd FileType go autocmd BufWritePre <buffer> 
        \ call execute('LspCodeActionSync source.organizeImports')
endif

" Rust
if executable('rls')
  autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'stable', 'rls']},
        \ 'root_uri': {server_info->s:find_root_uri(['Cargo.toml', '.git/'])},
        \ 'workspace_config': {'rust': {'clippy_preference': 'on'}},
        \ 'whitelist': ['rust'],
        \ })

  autocmd FileType rust autocmd BufWritePre <buffer> LspDocumentFormatSync
endif

" Python
if executable('pyls')
  autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'pyls',
        \ 'cmd': ['pyls'],
        \ 'whitelist': ['python'],
        \ })

  autocmd FileType python autocmd BufWritePre <buffer> LspDocumentFormatSync
endif

" TypeScript & JavaScript
if executable('javascript-typescript-stdio')
  autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'tsjs',
        \ 'cmd': ['javascript-typescript-stdio'],
        \ 'root_uri': {server_info->s:find_root_uri(['tsconfig.json', 'package.json', '.git/'])},
        \ 'whitelist': [
        \   'typescript',
        \   'javascript',
        \   'typescriptreact',
        \   'javascriptreact',
        \ ],
        \ })
endif

" C#
function s:find_file_upwards(exp, path) abort
  let l:files = glob(a:path . '/' . a:exp, 0, 1)

  if empty(l:files)
    let l:parent = fnamemodify(a:path . '/../', ':p:h')
    if l:parent == a:path
      return ''
    endif
    return s:find_file_upwards(a:exp, l:parent)
  else
    return fnamemodify(l:files[0], ':p')
  endif
endfunction

function s:find_csharp_projct_file() abort
  let l:projfile = s:find_file_upwards('*.sln', fnamemodify(lsp#utils#get_buffer_path(), ':p:h'))

  if empty(l:projfile)
    let l:projfile =  s:find_file_upwards('*.csproj', fnamemodify(lsp#utils#get_buffer_path(), ':p:h'))
  endif

  if empty(l:projfile)
    return lsp#utils#get_buffer_path()
  endif

  return l:projfile
endfunction

function s:find_csharp_projct_root_uri() abort
  return lsp#utils#path_to_uri(fnamemodify(s:find_csharp_projct_file(), ':p:h'))
endfunction

if executable('omnisharp')
  autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'csharp',
        \ 'cmd': {server_info-> ['omnisharp', '-s', s:find_csharp_projct_file(), '-lsp'] },
        \ 'root_uri': {server_info->s:find_csharp_projct_root_uri()},
        \ 'whitelist': [
        \   'cs',
        \ ],
        \ })

  autocmd FileType cs autocmd BufWritePre <buffer> LspDocumentFormatSync
endif

" swift
let s:swift_mode = 0 " 0: none, 1: sourcekit-lsp with xcrun, 2: sourcekit-lsp
if executable('xcrun')
  silent call system('xcrun --find sourcekit-lsp')
  if v:shell_error == 0
    let s:swift_mode = 1
  endif
endif
if s:swift_mode == 0 && executable('sourcekit-lsp')
  let s:swift_mode = 2
endif

if s:swift_mode == 1
  autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'swift',
        \ 'cmd': ['xcrun', 'sourcekit-lsp'],
        \ 'whitelist': ['swift'],
        \ })

  autocmd FileType swift autocmd BufWritePre <buffer> LspDocumentFormatSync

elseif s:swift_mode == 2
  autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'swift',
        \ 'cmd': ['sourcekit-lsp'],
        \ 'whitelist': ['swift'],
        \ })

  autocmd FileType swift autocmd BufWritePre <buffer> LspDocumentFormatSync
endif

augroup LspInstall
  autocmd!
  autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END
