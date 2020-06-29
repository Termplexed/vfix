let s:cpo_bak = &cpo
set cpo&vim
fun! s:gen_quickfix_list(reflist, ignore_lost)
	let e = []
	for entry in a:reflist
		let main = entry.stack[0]
		if a:ignore_lost && main.fun == 'N/A'
			continue
		endif
		" Add reported errors for this entry
		for err in entry.err_list
			"main.fline + main.eline + main.offs,
			let e += [{
				\ 'filename'  : main.file,
				\ 'lnum'      : err.line + main.fline,
				\ 'nr'        : err.nr,
				\ 'col'       : 0,
				\ 'vcol'      : 0,
				\ 'text'      : main.fun . ': ' . err.txt,
				\ 'type'      : 'E',
				\ 'valid'     : main.fun != 'N/A'
			\}]
		endfor
		" Add stack trace as Info entries
		for se in entry.stack[1:]
			let e += [{
				\ 'filename'  : se.file,
				\ 'lnum'      : se.fline + se.offs,
				\ 'nr'        : 0,
				\ 'col'       : 0,
				\ 'vcol'      : 0,
				\ 'text'      : 'Called by: ' . se.fun,
				\ 'type'      : 'I',
				\ 'valid'     : 0
			\}]
		endfor
	endfor
	return e
endfun
fun! vfix#quickfix#update(reflist, cnf)
	let e = s:gen_quickfix_list(a:reflist, a:cnf.ignore_lost)
	call setqflist(e, a:cnf.append ? 'a' : 'r')
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
