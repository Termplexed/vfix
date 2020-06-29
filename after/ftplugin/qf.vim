if v:version < 802 && !has('nvim')
    finish
endif

let s:cpo_bak = &cpo
set cpo&vim

fun! s:add_map()
	let l:accel = get(g:, 'Vfix_popup_map_key', 'v')
	let l:map = mapcheck(l:accel, 'n')
	if empty(l:map) || l:map is '<nop>'
		exe "nnoremap <silent> <buffer> " . l:accel . " :call vfix#popup#load(0)<CR>"
		call vfix#help#set_popmap(l:accel)
		call vfix#echo#info("Vfix: Enter '" . l:accel . "` to open / close popup", 1)
	else
		call vfix#echo#warn("Vfix: No mapping for popup: '" . l:accel . "` not free.", 1)
	endif
endfun

if vfix#main#is_map_virgin()
	call s:add_map()
endif

let &cpo= s:cpo_bak
unlet s:cpo_bak
