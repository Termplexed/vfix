let s:cpo_bak = &cpo
set cpo&vim

let s:pop_map = ''
let s:vfix_help = [
\ ['append',        'a', 'append    - Append to QuickFix List. Default OFF:replace'],
\ ['reverse',       'r', 'reverse   - Reverse messages.        Default OFF:FIFO'],
\ ['copen',         'o', 'copen     - Open using copen.        Default OFF:cw'],
\ ['silent',        's', 'silent    - Do not open window.      Default OFF'],
\ ['ignore_lost',  'ig', 'nolost    - Ignore lost functions.   Default OFF'],
\ ['auto_run',     'au', 'autorun   - Vfix on sourcing a file. Default OFF'],
\ ['clr_always',   'ac', 'clear     - Alway clear ":messages". Default OFF'],
\ ['mark_filter',  'fm', 'use-mark  - Only from last mark.     Default ON'],
\ ['0',             'm', 'use-mark  - Search mark once.'],
\ ['mark_auto',    'am', 'mark-auto - Add marks in :messages.  Default ON'],
\ ['0',             'M', 'mark-now  - Add a mark in :messages.'],
\ ['0',            'lm', 'list-m    - List marks' ],
\ ['0',            'cc', 'clear     - Clear messages once.'],
\ ['0',            'sf', 'Print Status for flags.'],
\ ['0',             'h', 'This help']
\ ]
fun! s:echo_flag(cnf, h)
	let f = a:cnf[a:h[0]]
	exe 'echohl ' .  (f ? 'Statement' : 'Comment')
	echo printf("%3s= %s,  %s", a:h[1], f, a:h[2])
	echohl None
endfun
fun! vfix#help#set_popmap(m)
	let s:pop_map = a:m
endfun
fun! vfix#help#cmd_comp(A, L, P)
	if a:L =~# 'M\s\+$'
		return ['YourMark']
	elseif a:L =~#  'm\s\+$'
		return [string(s:Vfix.mark.counter)]
	elseif a:A =~ '=$'
		return map(['0', '1'], 'a:A . v:val')
	endif
	let base = ['a ', 'r ', 'o ', 's ', 'ig ', 'au', 'ac',
		\ 'fm ', 'm ', 'am ', 'M ', 'lm', 'cc', 'sf ', 'h ', 'help ']
	let pri = filter(base, 'v:val =~# "^".a:A')
	return pri
endfun
fun! vfix#help#show()
	echohl Constant
	echo "Options:"
	for op in s:vfix_help
		echo printf("%3s  : %s", op[1], op[2])
	endfor
	if ! empty(s:pop_map)
		echo "Popup mapped to " . s:pop_map
	endif
	echohl None
	return 1
endfun
fun! vfix#help#show_flags_state(cnf)
	echo
	for h in s:vfix_help
		if h[0] != '0'
			call s:echo_flag(a:cnf, h)
		endif
	endfor
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
