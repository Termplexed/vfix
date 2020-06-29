let s:cpo_bak = &cpo
set cpo&vim

" All values can be overridden globally by:
" 	g:Vfix_{config name} = {config setting}
let s:cnf_default = {
	\ 're_source_globals': 0,
	\ 'append': 0,
	\ 'copen': 0,
	\ 'silent': 0,
	\ 'reverse': 0,
	\ 'clr_once': 0,
	\ 'ignore_lost': 0,
	\ 'clr_always': 0,
	\ 'auto_run': 0,
	\ 'mark_filter': 1,
	\ 'mark_auto': 1,
	\ 'mark_show': 1,
	\ 'mark_hi': 'Comment'
\}
fun! vfix#options#cnf_init(cnf)
	return extend(a:cnf, s:cnf_default)
endfun
fun! vfix#options#apply_globals(cnf)
	for k in keys(s:cnf_default)
		let a:cnf[k] = s:val2bool(
			\ get(g:, 'Vfix_' . k, a:cnf[k]))
	endfor
	return a:cnf
endfun
fun! s:flip_option(cnf, k)
	let a:cnf[a:k] = !a:cnf[a:k]
	echo "State " . a:k . ": " . a:cnf[a:k]
endfun
fun! s:val2bool(v)
	if type(a:v) == type(1)
		return a:v ? 1 : 0
	endif
	let v = tolower(a:v)
	if index(['+', 'y', 'true'], v) > -1
		return 1
	elseif index(['-', 'n', 'false'], v) > -1
		return 0
	else
		return a:v ? 1 : 0
	endif
endfun
fun! s:set_option(cnf, k, v)
	if a:v == 0
		call s:flip_option(a:cnf, a:k)
	else
		let a:cnf[a:k] = a:v
		echo "State " . a:k . ": " . a:cnf[a:k]
	endif
endfun
fun! vfix#options#arg_parse(cnf, n, opts)
	let r = 0
	let i = 0
	let c = a:cnf
	for opt in a:opts
		let i += 1
		if opt =~ '[:=]'
			let v = split(opt, '[:=]')
			let opt = v[0]
			let val = s:val2bool(v[1])
		else
			let val = 0
		endif

		if     opt == 'cc'
			call s:set_option(c, 'clr_once', val)
		elseif opt == 'a'
			call s:set_option(c, 'append', val)
		elseif opt == 's'
			call s:set_option(c, 'silent', val)
		elseif opt == 'o'
			call s:set_option(c, 'copen', val)
		elseif opt == 'r'
			call s:set_option(c, 'reverse', val)
		elseif opt == 'fm'
			call s:set_option(c, 'mark_filter', val)
		elseif opt == 'm'
			call vfix#messages#set_filter_pattern(a:opts[i])
			break
		elseif opt == 'hm'
			" XXX: Hidden feature (for now)
			let c.mark_hi = a:opts[i]
			call vfix#messages#marks_set_highlight(a:opts[i])
		elseif opt == 'ig'
			call s:set_option(c, 'ignore_lost', val)
			let r = 1
		elseif opt == 'ac'
			call s:set_option(c, 'clr_always', val)
			let r = 1
		elseif opt == 'lm'
			call vfix#messages#list_markers()
			let r = 1
		elseif opt == 'am'
			call s:set_option('mark_auto', val)
			call vfix#autocmd#set(c)
			let r = 1
		elseif opt == 'au'
			call s:set_option(c, 'auto_run', val)
			call vfix#autocmd#set(c)
			let r = 1
		elseif opt == 'M'
			let txt = join(a:opts[i:], " ")
			call vfix#messages#mark_add(txt == "" ? "Manual" : txt)
			let r = 1
			break
		elseif opt == 'sf'
			call vfix#help#show_flags_state(c)
			let r = 1
		elseif opt == 'h' || opt == 'help'
			call vfix#help#show()
			let r = 1
		else
			call vfix#echo#warn("Unknown command '" . opt . "'", 0)
			let r = 1
			break
		endif
	endfor
	return r
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
