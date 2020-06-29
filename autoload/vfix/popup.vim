let s:cpo_bak = &cpo
set cpo&vim

let s:pop = {'wid': -1, 'last': -1, 'buf': 0}

fun! s:pop.on_close(id, res)
	let s:pop.wid = -1
	let s:pop.last = -1
endfun
fun! s:on_key(id, key)
	" DUMP [a:id, string(a:key)]
	if a:key =~ "\033" || a:key == 'x'
		call popup_close(a:id, 1)
		return 1
	endif
	return 1
	"return popup_filter_menu(a:id, a:key)
endfun
fun! s:pop_align_with_qf_window(qf_wid)
	call popup_move(s:pop.wid, {
		\ 'col' : 1,
		\ 'line': 1
	\ })
	let wif = getwininfo(a:qf_wid)
	let pif = popup_getpos(s:pop.wid)
	" DUMP wif
	" DUMP pif
	call popup_move(s:pop.wid, {
		\ 'col' : wif[0].width - pif.width,
		\ 'line': wif[0].winrow - pif.height - 2,
		\ 'maxwidth': wif[0].width - 4
	\ })
endfun
fun! s:nvim_pop_align_with_qf_window(qf_wid, ctx)
	let wif = getwininfo(a:qf_wid)
	call nvim_win_set_config(s:pop.wid, {
		\ 'relative': 'editor',
		\ 'width': 500,
		\ 'col' : 0,
		\ 'row' : wif[0].winrow - len(a:ctx) - 3,
		\ 'height' : len(a:ctx)
	\ })
	call nvim_set_current_win(a:qf_wid)
endfun
" ... todo:
fun! s:re_esc(s)
	let m = split(a:s, '\s\+')
	call map(m, "escape(v:val, '\')")
	return join(m, '\s*')
endfun
fun! s:pop_highlight(txt, ln, swp_taken)
	let m = matchlist(a:txt,
		\   '\%('
		\ . '\%(variable\|command\|expression\|function\): \%(\(\k*\)\|\(.*\)\)$\|'
		\ . 'for function \([^(]\+\)'
		\ .     '\((.*$\|$\)'
		\ . '\)')
	" DUMP m
	if len(m)
		if m[1] != ''
			let m = '\<'.s:re_esc(m[1]).'\>'
		elseif m[2] != ''
			let m = s:re_esc(m[2])
		elseif m[4] != ''
			let m = s:re_esc(m[3] . m[4])
		else
			let m = '\<'.s:re_esc(m[3]).'\>'
		endif
	else
		let m = ''
	endif
	call clearmatches(s:pop.wid)
	if m != ''
		" DUMP [a:ln.hi_start, m, a:ln.hi_end]
		let s:pop_em1 = matchadd('Error',
			\ '\%' . a:ln.hi_start .  'l\_.\{-}\zs' . m . '\ze\_.*\%' . a:ln.hi_end . 'l',
			\ 99, -1, {'window': s:pop.wid}
			\)
		let hl = a:ln.len - (a:swp_taken ? 2 : 1)
		"DUMP hl
		let s:pop_em2 = matchadd('Error',
			\ '\%' . hl . 'l.\{-}\zs' . m . '\ze',
			\ 99, -1, {'window': s:pop.wid}
			\)
	endif
endfun
fun! s:pop_new()
	let s:pop.wid = popup_create([], {
		\ 'zindex': 200,
		\ 'drag': 1,
		\ 'wrap': 1,
		\ 'borderchars': ['‾'],
		\ 'cursorline': 1,
		\ 'border' : [1, 0, 0, 0],
		\ 'padding': [0,3,1,1],
		\ 'close': 'button',
		\ 'mapping' : 0,
		\ 'callback': s:pop.on_close
		\})
	let s:pop.buf = winbufnr(s:pop.wid)
	" call setbufvar(winbufnr(s:pop.wid), '&filetype', 'vim')
endfun
fun! s:nvim_pop_new()
	if ! s:pop.buf
		let s:pop.buf = nvim_create_buf(0, 1)
	endif
	call nvim_buf_set_lines(s:pop.buf, 0, -1, 1, ["x"])
	let opts = {
		\ 'relative': 'cursor',
		\ 'width': 10,
		\ 'height': 10,
		\ 'col': 0,
		\ 'row': 1,
		\ 'anchor': 'NW',
		\ 'style': 'minimal'}
	let s:pop.wid = nvim_open_win(s:pop.buf, 0, opts)
endfun
fun! s:ctx_add_linenumbers(ctx, offs)
	let n = len(a:ctx)
	let i = 0
	while i < n
		let a:ctx[i] = printf("%3d ", a:offs + i) . a:ctx[i]
		let i += 1
	endwhile
endfun
fun! s:swap_taken(fn)
	let taken = 0
	let ft = fnamemodify(a:fn, ':t')
	let fh = fnamemodify(a:fn, ':h')
	let swp = glob(fh . '/.' . ft . '.sw?')
	if swp != ''
		let swp = swapinfo(swp)
		let taken = swp.pid != getpid()
	endif
	return taken
endfun
fun! s:def_lines(ctx, offs, lines)
	let ln = {
		\ 'start': a:offs < 3 ? 1 : a:offs - 2,
		\ 'hi_start': a:offs < 3 ? a:offs : 3
	\ }

	let he = ln.hi_start
	while he < a:lines && a:ctx[he] =~ '^\s*\\'
		let he += 1
	endwhile
	let ln.hi_end = he
	return ln
endfun
fun! s:autocmd_set()
	augroup VfixAutoLoadPop
		au!
		"au FileType quickfix CursorMoved * call vfix#popup#load(0)
		au CursorMoved * if &buftype == 'quickfix' | call vfix#popup#load(2) | endif
	augroup END
endfun
fun! s:autocmd_clear()
	augroup VfixAutoLoadPop
		au!
	augroup END
endfun
fun! s:finalize()
	if has('nvim')
		call nvim_win_close(s:pop.wid, 0)
		let s:pop.wid = -1
		let s:pop.last = -1
	else
		call popup_close(s:pop.wid, 0)
	endif
	call s:autocmd_clear()
endfun
fun! vfix#popup#load(mode)
	let cur_line = line('.') - 1
	if cur_line == s:pop.last
		if a:mode != 2
			call s:finalize()
		endif
		return
	endif
	let s:pop.last = cur_line

	let qentry = getqflist({'winid': 1, 'items': 1, 'idx': 0})
	let entry = qentry.items[cur_line]
	if entry.bufnr == 0
		return
	endif

	let fn = fnamemodify(bufname(entry.bufnr), ':p')
	let ctx = vfix#file#ctx_get(fn . ":" . entry.lnum)
	let swp_taken = s:swap_taken(fn)
	let ln = s:def_lines(ctx, entry.lnum, len(ctx))

	call s:ctx_add_linenumbers(ctx, ln.start)

	if strftime('%m')/2 == 6
		exec 'let hd = "\" 'repeat('\U'.printf("\%X ",(722*177)),9)'"'
	else
		let hd = ''
	endif

	let ctx += [hd,
		\ '" Error: ' . entry.text,
		\ '" File:  ' . fnamemodify(fn, ':~:.')]
	if swp_taken
		let ctx += ['" Swap:  Likely open in other Vim instance']
	endif

	let ln.len = len(ctx)

	if has('nvim')
	endif
	if s:pop.wid < 0
		if has('nvim')
			call s:nvim_pop_new()
		else
			call s:pop_new()
		endif
		call s:autocmd_set()
	endif

	if has('nvim')
		" let ctx += [ string(s:pop) ]
		call nvim_buf_set_lines(s:pop.buf, 0, -1, v:true, ctx)
		call s:nvim_pop_align_with_qf_window(qentry.winid, ctx)
		call nvim_win_set_option(s:pop.wid, 'cursorline', v:true)
		call nvim_win_set_cursor(s:pop.wid, [ ln.hi_start, 0 ])
	else
		call popup_settext(s:pop.wid, ctx)
		call s:pop_align_with_qf_window(qentry.winid)
		call win_execute(s:pop.wid, 'call cursor('.(ln.hi_start).', 1)')
	endif
	call setbufvar(s:pop.buf, '&filetype', 'vim')
	call s:pop_highlight(entry.text, ln, swp_taken)
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
