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

fun! s:def_commands()
	command! -nargs=* -complete=customlist,vfix#help#cmd_comp -bar Vfix
		\ :call vfix#main#run(<f-args>)
endfun
if get(g:, 'Vfix_load_on_startup', '0') != '0'
	call vfix#main#boot()
endif
call s:def_commands()

let &cpo= s:cpo_bak
unlet s:cpo_bak
