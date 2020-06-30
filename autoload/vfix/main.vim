" vim: fdm=marker
"" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""" Figlet -w 90 -c -f block
 "                                                                                    "
 "                        _|      _|  _|_|_|_|  _|  _|      _|                        "
 "                        _|      _|  _|              _|  _|                          "
 "                        _|      _|  _|_|_|    _|      _|                            "
 "                          _|  _|    _|        _|    _|  _|                          "
 "                            _|      _|        _|  _|      _|                        "
 "                                                                                    "
 " """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:cpo_bak = &cpo
set cpo&vim

if exists('s:cnf')
	let s:cnf_bak = copy(s:cnf)
	let s:mark_counter = vfix#messages#get_mark_counter()
endif

let s:strapped = 0
let s:cnf = { }
let s:map_virgin = 1

fun! vfix#main#is_map_virgin()
	if s:map_virgin
		let s:map_virgin = 0
		return 1
	else
		return 0
	endif
endfun
fun! vfix#main#boot() abort
	call vfix#options#cnf_init(s:cnf)
	if exists('s:cnf_bak')
		call extend(s:cnf, s:cnf_bak)
		call vfix#messages#set_mark_counter(s:mark_counter)
		let s:strapped = s:cnf.re_source_globals ? 0 : 1
		call vfix#autocmd#clear()
		unlet s:cnf_bak
		unlet s:mark_counter
	endif
	if ! s:strapped
		let s:strapped = 1
		call vfix#options#apply_globals(s:cnf)
	endif

	call vfix#messages#init(s:cnf)
	call vfix#autocmd#set(s:cnf)
endfun
fun! vfix#main#run(...) abort
	if ! s:strapped
		call vfix#main#boot()
	endif
	if vfix#options#arg_parse(s:cnf, a:0, a:000)
		return 1
	endif

	call vfix#file#ctx_clear()
	let l:messages = vfix#messages#get(0)
	let l:reflist = vfix#parser#parse(l:messages)

	if s:cnf.reverse
		call reverse(l:reflist)
	endif

	call vfix#quickfix#update(l:reflist, s:cnf)

	if ! s:cnf.silent
		if s:cnf.copen
			keepalt copen
			wincmd p
		else
			keepalt cw
		endif
	endif

	if s:cnf.clr_once || s:cnf.clr_always
		messages clear
		let s:cnf.clr_once = 0
	endif
endfun

let &cpo= s:cpo_bak
unlet s:cpo_bak
