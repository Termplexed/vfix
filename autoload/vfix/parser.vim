let s:cpo_bak = &cpo
set cpo&vim
" ref:  Function number, name or <SID>NR_name
" type: edict = dictionary function, typically number
"       elfun = other
fun! s:resolve_fun(ref, type) abort
	let fn = ''
	let buf = []
	let fun = 'N/A'
	let fline = 0

	let pat = a:type == 'edict' ? '{'.a:ref.'}' : ' ' . a:ref

	try
		let fun = execute('verbose function' . pat)
	catch /^Vim\%((\a\+)\)\=:E123:/
		let fun = 'N/A'
	endtry
	if fun == '' | let fun = 'N/A' | endif

	if fun != 'N/A'
		let fun = split(fun, "\n")
		let m = matchlist(
			\ fun[1], 'Last set from \(\f\+\) line \([0-9]\+\)')
		if len(m)
			let fn = expand(m[1])
			let fline = m[2]
			let buf = vfix#file#read(fn)
			if len(buf)
				let fun = buf[fline - 1]
			endif
		endif
	endif
	return { 'file': fn, 'fline': fline, 'fun': fun, 'buf': buf }
endfun
" entry:    dict entry. See .create_entry
" type:     edict = dictionary function
fun! s:resolve_ref_verbose(entry, type) abort
	let res = s:resolve_fun(a:entry.ref, a:type)
	let a:entry.file = res.file
	let a:entry.fline = res.fline
	let a:entry.fun = res.fun

	if len(res.buf)
		let ce = res.fline + a:entry.offs
		let a:entry.ctx = res.file . ":" . ce
		call vfix#file#ctx_add(a:entry.ctx, res.buf, ce - 1)
	endif
endfun
" 'messages' line typically is:
" Some error fun[3]...fun[8]...fun:
" where numbers in brackets are offset within funciton.
let s:ml_trace = {
	\ 'edict': '^\([0-9]\+\)\[\([0-9]\+\)\]$',
	\ 'elfun': '^\([^[]\+\)\[\([0-9]\+\)\]$'
\}
" Processing single entry from a trace: EEE[offs]...EEE[offs]...EEE
"
" type: edict = dictionary ref. as in NNNN
"       elfun = others as in SomeFun, or <SID>NN_SomeFun, ...
" ref:  the function reference. If NNN[offset] or FunName[offset]
"       the NNN or FunName part is extracted
" ln:   Line. If entry does not have a offset, typically [offset]
"       it is the 'main error' and this parameter is used instad
"       of the one matched in 'm' ... or not matched as it does
"       not exist :P
fun! s:create_entry(type, ref, ln)
	let m = matchlist(a:ref, s:ml_trace[a:type])
	let entry = {
		\ 'file'  : '',
		\ 'ref'   : get(m, 1, a:ref),
		\ 'fun'   : 'N/A',
		\ 'fline' : 0,
		\ 'offs'  : a:ln + get(m, 2, ''),
		\ 'ctx'   : ''
	\}
	call s:resolve_ref_verbose(entry, a:type)
	return entry
endfun
" Entry, local to a function scope, dictionary or function reference error stack.
"
" type: edict or elfun
" fr:   Function Referrence(s). Typically:
"   edict:
"       623[5]..612[3]..622
"   elfun:
"       SomeFun[5]..AnotherFun[3]..FunWithError
"   Extracted from 'messages'
" Can be mix of Fun...<SID>N_Fun...NNN:
fun! s:detect_etype(ref)
	return a:ref =~ '^[0-9]\+\[\?' ? 'edict' : 'elfun'
endfun
fun! s:push_err_local(fr) abort
	let reflist = reverse(split(a:fr, '\.\.'))
	let type = s:detect_etype(reflist[0])
	let errors = s:get_errors(type)
	let linen = errors.main_eline

	for ref in reflist
		let type = s:detect_etype(ref)
		let errors.stack += [s:create_entry(type, ref, linen)]
		let linen = 0
	endfor
	if len(errors.stack)
		let fn_main = errors.stack[0].file
		let offs = errors.stack[0].fline
		let buf = vfix#file#read(fn_main)
		for err in errors.err_list
			let err.ctx = fn_main . ":" . (err.line + offs)
			call vfix#file#ctx_add(err.ctx, buf, (err.line + offs - 1))
		endfor
	endif

	let s:reflist += [errors]

	let s:ix += errors.log_len ? errors.log_len : 1
	return 0
endfun
" Add a global scope (inline / outside of function) error stack
fun! s:push_err_global(fn) abort
	let fn = expand(a:fn)
	let errors = s:get_errors('efile')
	let buf = vfix#file#read(fn)

	if len(buf)
		let errors.stack += [{
			\ 'file'  : fn,
			\ 'ref'   : '',
			\ 'fun'   : '<inline>',
			\ 'fline' : ''
		\}]
		for err in errors.err_list
			let err.ctx = fn . ":" . err.line
			call vfix#file#ctx_add(err.ctx, buf, err.line - 1)
		endfor
		let s:reflist += [errors]
	endif
	let s:ix += errors.log_len ? errors.log_len : 1
	return 0
endfun
" type: eref
fun! s:push_err_unscoped(type) abort
	let errors = s:get_errors(a:type, s:ix)
	let errors.stack += [{
		\ 'file'  : '',
		\ 'ref'   : 'N/A',
		\ 'fun'   : '<unscoped>',
		\ 'fline' : 1
	\}]
	let s:reflist += [errors]
	let s:ix += errors.log_len ? errors.log_len : 1
	return 0
endfun
" Some messages can be:
" E123: blah blah function: 1234
"
" This function resolves 1324 to actual function name and return
" error line with 1234 substituted with function declaration.
fun! s:resolve_msg(t) abort
	let m = matchstr(a:t, 'function:\? \zs[0-9]\+$')
	if m != ''
		let res = s:resolve_fun(m, 'edict')
		let m = substitute(a:t, m .'$', res.fun, '')
	else
		let m = a:t
	endif
	" Fix tabs
	let m = substitute(m, '\^I', ' ', 'g')
	return m
endfun
" Starting from current index, read all messages starting with
"    ENNN, (E32, E123 ...)
" OR
"    line  : NNN
" OR
"    Interrupted
"
" ARG:  None or line number in s:messages to start with
"       Most errors have a ref. to a line number and caller.
"       In this case s:ix is used.
"       But some can be 'stand alone' errors where one typically
"       have passed wrong number of arguments etc.
"
" Returns a error dict that typically is pushed to reflist stack from
" caller function.
fun! s:get_errors(type, ...) abort
	let err = []
	let i = a:0 > 1 ? a:2 : s:ix + 1
	let n = len(s:messages)
	let line = 0
	while i < n
		let m = s:messages[i]
		if m == s:messages[i - 1]
			" Ignore dupe
			let i += 1
			continue
		endif
		let e = matchlist(m, '^\%(' .
			\ '\%(line\s\+\([0-9]\+\):\)\|' .
			\ '\(Interrupted\)\|' .
			\ '\%(E\([0-9]\+\): \(.*\)\)' .
		\ '\)$')
		if ! len(e)
			break
		elseif e[1] != ''
			let line = e[1] + 0
		elseif e[2] != ''
			let err += [{
				\ 'line': line,
				\ 'nr': 0,
				\ 'txt': "Interrupted",
				\ 'ctx': 'N/A'}]
		elseif e[3] != ''
			let txt = s:resolve_msg(e[4])
			let err += [{
				\ 'line': line,
				\ 'nr': e[3],
				\ 'txt': txt,
				\ 'ctx': 'N/A'}]
		endif
		let i += 1
	endwhile
	return {
		\ 'type'      : a:type,
		\ 'trigger'   : s:messages[s:ix],
		\ 'err_list'  : err,
		\ 'main_eline': line,
		\ 'log_start' : s:ix,
		\ 'log_end'   : i,
		\ 'log_len'   : i - s:ix,
		\ 'stack'     : []
	\}
endfun
" Typically
" E000: *Something wrong with call to* function: 123
" If this error is not part of a call stack and does not have a
" reference as in ^Error detected while ..., we try to catch it
" here and at least resolve numeric references.
fun! s:check_eref(msg) abort
	let err_found = 1
	let xm = matchlist(a:msg,
		\ '^E' .
		\ '\([0-9]\+\): .*arguments for function:\? \([0-9]\+\)' .
	\ '$')
	if len(xm)
		call s:push_err_unscoped('eref')
	else
		let err_found = 0
	endif
	return err_found
endfun
" Check if current line from 'messages' is a *normal* Error detected
" message. If so try to find if it is a dict error or other and call
" appropriate functions to push it onto reflist.
fun! s:check_detected(messages) abort
	let err_found = 1
	let xm = matchlist(s:messages[s:ix],
		\ "^Error detected while processing " .
		\ '\%(' .
		\ '\%(function \([0-9.\]\[]\+\)\)\|' .
		\ '\%(function \([][.<>#A-Za-z0-9_]\+\)\)\|' .
		\ '\%(function \(<SNR>[][.<>#A-Za-z0-9_]\+\)\)\|' .
		\ '\%(function \(<lambda>[][.<>#A-Za-z0-9_]\+\)\)\|' .
		\ '\(\f\+\.vi\%[mrc]\)\|' .
	\ '\):$')
	if len(xm)
		" Could merge 1, 2 and 3
		if xm[1] != ''
			" NNN type function references
			call s:push_err_local(xm[1])
		elseif xm[2] != ''
			" FunName type function references
			call s:push_err_local(xm[2])
		elseif xm[3] != ''
			" XXX REMOVE
			" <SNR>NN_FunNAme type function references
			call s:push_err_local(xm[3])
		elseif xm[4] != ''
			" <lambda>NNN type function references
			" TODO: This rarely works
			call s:push_err_local(xm[4])
		elseif xm[5] != ''
			call s:push_err_global(xm[5])
		else
			let err_found = 0
		endif
	else
		let err_found = 0
	endif
	return err_found
endfun
" Main Loop s:ix are updated by parser functions.
" Loop messages and try to detect and resolve errors.
" Detections are pushed onto s:reflist.
fun! vfix#parser#parse(messages) abort
	let n = len(a:messages)
	let s:reflist = []
	let s:messages = a:messages
	let s:ix = 0
	while s:ix < n
		" 1. Errors that is not preceded by a func ref.
		let r = s:check_eref(s:messages[s:ix])
		" 2. Errors with func ref or inline (file scope)
		if r == 0 | let r = s:check_detected(a:messages) | endif
		" 3. Make sure we increment if nothing found
		if r == 0 | let s:ix += 1 | endif
	endwhile
	call vfix#file#cache_clear()
	return s:reflist
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
