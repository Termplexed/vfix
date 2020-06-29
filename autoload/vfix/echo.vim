let s:cpo_bak = &cpo
set cpo&vim

fun! s:echo(hi, s, persistent)
	exe "echohl " . a:hi
	if a:persistent
		echom a:s
	else
		echo a:s
	endif
	echohl None
endfun
fun! vfix#echo#error(s, persistent)
	call s:echo('ErrorMsg', a:s, a:persistent)
endfun
fun! vfix#echo#warn(s, persistent)
	call s:echo('WarningMsg', a:s, a:persistent)
endfun
fun! vfix#echo#info(s, persistent)
	call s:echo('Debug', a:s, a:persistent)
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
