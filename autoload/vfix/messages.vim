let s:cpo_bak = &cpo
set cpo&vim

let s:mark = {
	\ 'counter': 0,
	\ 'hi': 'Comment'
\ }
let s:filter = {
	\ 'on': 0,
	\ 'pattern': ''
\}

fun! vfix#messages#init(cnf)
	let s:filter.on = a:cnf.mark_filter
	let s:filter.pattern = ''
	call s:set_mark_highlight(a:cnf.mark_hi)
endfun
fun! vfix#messages#set_mark_counter(c)
	let s:mark.counter = a:c + 0
endfun
fun! vfix#messages#get_mark_counter()
	return s:mark.counter
endfun
fun! vfix#messages#set_filter_pattern(s)
	let s:filter.pattern = a:s
endfun
fun! vfix#messages#set_filter_status(v)
	let s:filter.on = a:v + 0
endfun
fun! s:set_mark_highlight(hi)
	let s:mark.hi = a:hi
	exec 'highlight! link VfixMarksHighlight ' . a:hi
endfun
fun! vfix#messages#mark_add(...)
	let s:mark.counter += 1
	let m = a:0 ? a:1 : ('from ' . expand('<afile>'))
	echohl VfixMarksHighlight
	echomsg printf(";; VfixM %2d %s %s",
		\ s:mark.counter,
		\ strftime('%H:%M:%S'),
		\ m)
	redraw
	echohl None
endfun
fun! vfix#messages#list_markers()
	let mm = vfix#messages#get(1)
	call filter(mm, 'v:val =~ "^;; VfixM "')
	echo join(mm, "\n")
endfun
fun! s:hack_messages(m)
	let m = substitute(a:m,
		\ '\[deoplete]\( function.*\), \(line \d*\)',
		\ 'Error detected while processing\1:\n\2:\nE000: deoplete', 'g')
	return m
endfun
fun! s:filter_by_mark(ml)
	let i = 0
	if s:filter.pattern != '' && s:filter.pattern != '0'
		" Search for specified mark
		let i = match(a:ml, ';; VfixM \s*' . s:filter.pattern)
	elseif s:mark.counter > 0
		" Use last mark
		let i = match(a:ml, ';; VfixM \s*' . s:mark.counter . '\s')
		if i < 0
		" If messages have been cleared and there is new
		" errors without sourcing
			let i = 0
		endif
	endif
	return i > -1 ? a:ml[i:] : []
endfun
fun! vfix#messages#get(all)
	let ml = execute('messages')
	let ml = s:hack_messages(ml)
	let ml = split(ml, "\n")
	if s:filter.on && !a:all
		let ml = s:filter_by_mark(ml)
		let s:filter.pattern = ''
	endif
	return ml
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
