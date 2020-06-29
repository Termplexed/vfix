let s:cpo_bak = &cpo
set cpo&vim

let s:ctx_cache = { }
let s:file_cache = { }

fun! vfix#file#ctx_clear()
	let s:ctx_cache = { }
endfun
fun! vfix#file#cache_clear()
	let s:file_cache = { }
endfun
fun! vfix#file#read(fn)
	let buf = []
	if a:fn == ''
		return buf
	endif
	if has_key(s:file_cache, a:fn)
		let buf = s:file_cache[a:fn]
	else
		try
			let buf = readfile(a:fn)
			let s:file_cache[a:fn] = buf
		catch
			call vfix#echo#warn('Vfix: Unable to read ' . a:fn, 0)
			let buf = []
		endtry
	endif
	return buf
endfun
fun! vfix#file#ctx_get(id)
	return copy(get(s:ctx_cache, a:id, []))
endfun
fun! vfix#file#ctx_add(id, buf, line)
	if ! has_key(s:ctx_cache, a:id)
		let n = len(a:buf)
		let ctx = a:buf[(a:line < 2 ? 0 : a:line - 2) : (a:line + 2)]
		let i = a:line + 3
		" Expand to include multiline statements
		if i < n && ctx[-2] =~ '^\s*\\' && ctx[-1] =~ '^\s*\\'
			while i < n && a:buf[i] =~ '^\s*\\'
				let ctx +=[a:buf[i]]
				let i += 1
			endwhile
			let ctx += a:buf[i : i + 2]
		endif
		let s:ctx_cache[a:id] = ctx
	endif
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
