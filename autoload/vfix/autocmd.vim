let s:cpo_bak = &cpo
set cpo&vim
" Only here for now. Add as option?
let s:ignore_autoload = 1

fun! s:on_SourcePre()
	" Ignore Vim startup
	if ! v:vim_did_enter
		return
	endif
	" Ignore /autoload/
	" TODO: Perhaps add mark if currently edited file is in a /autoload/
	" directory.
	if expand("<afile>") =~# '/autoload/' " Always && s:ignore_autoload
		return
	endif
	call vfix#messages#mark_add()
endfun
fun! s:on_SourcePost()
	" Autoload causes trigger
	" Less restrictive? Only on pattern like ['pathogen', ...]
	if ! v:vim_did_enter || (
			\ expand("<afile>") =~# '/autoload/' &&
			\ s:ignore_autoload)
		return
	endif
	call vfix#main#run()
endfun
fun! vfix#autocmd#set(cnf)
	augroup VfixAutocommands
		autocmd!
		if a:cnf.auto_run
			autocmd SourcePost *.vim call s:on_SourcePost()
		endif
		if a:cnf.mark_auto
			autocmd SourcePre *.vim call s:on_SourcePre()
		endif
	augroup END
endfun
fun! vfix#autocmd#clear()
	augroup VfixAutocommands
		autocmd!
	augroup END
	silent augroup! VfixAutocommands
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
