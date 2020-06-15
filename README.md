<h1 align="center">:Vfix</h1>

<p align="center">
  <img width="600"
       alt=":Vfix in action preview"
       src="https://raw.githubusercontent.com/Termplexed/res/master/gif/Vfix.gif">
</p>

A crude and simple script for Vim to resolve some of the error `:messages` yielded when vim-scrips fail.

Can be a help to find where errors originate etc.

---

## :information_source:&nbsp;&nbsp;&nbsp;About

Parses `:messages` and resolves numeric and other references to errors before adding them to QuickFix list.

##  :heavy_dollar_sign:&nbsp;&nbsp;&nbsp;Example

As in gif above.

<pre>
Error detected while processing function 346[5]..345[31]..340:
line   3:
E492: Not and editor command: ^I^I^Iautocmdx
</pre>
Pushed by ***Vfix*** to QuickFix as:
<pre>
1  <b>.vim/some/dir/script.vim</b>|460 error 492|<i> fun! s:MyScript.set_au(): Not an editor command:   autocmdx</i>
2  <b>.vim/some/dir/script.vim</b>|564 info|<i> Called by: fun! s:MyScript.go_active(a, b)</i>
3  <b>.vim/some/dir/script.vim</b>|594 info|<i> Called by: fun! s:MyScript.interpret_cmd(...)</i>
</pre>
Here we have on line 1. in QuickFix the offending line `460` by function `340` resolved to `s:MyScript.set_au()`.

Line 2. and 3. are the trace from *345* to *346*. The entries in the QuickFix list are direct links to the scripts and their error lines - as long as they can be found.

<h2>:floppy_disk:&nbsp;&nbsp;&nbsp;Install</h2>

Put script in a autoload folder or source it manually.

## :pager::&nbsp;&nbsp;&nbsp;Commands

Adds one command: `:Vfix`

## :books:&nbsp;&nbsp;&nbsp;Usage

The script comes with a few options. When script is sourced you can run:

```vim
:Vfix help
```

to get a list:
```wasm
Options:
  a  : append  - Append to QuickFix List. Default OFF:replace
  r  : reverse - Reverse messages.        Default ON :LIFO
  o  : copen   - Open using copen.        Default OFF:cw
  s  : silent  - Do not open window.      Default OFF
 ig  : nolost  - Ignore lost functions.   Default OFF
 au  : autorun - Vfix on sourcing a file. Default OFF
 ac  : clear   - Alway clear ":messages". Default OFF
 cc  : clear   - Clear messages once.
 sf  : Print Status for flags.
  h  : This help
```

Beware that `cc` and `ac` clears `:messages`. To view status of flags use `:Vfix sf`

**:Vfix** alone runs the script and open QuickFix if it managed to dechipher any errors - optionally with `cc`, `a`, `s`, `o` or `r` option(s).

###  :mag:&nbsp;&nbsp;&nbsp;Lost functions

Note that every time a script get sourced it get a new reference. If this is anumeric ref. it can not be resolved later and one will get `N/A` + a noop address in the errors list. Activate `ig` to silence these.

##  :earth_americas:&nbsp;&nbsp;&nbsp;Global options

Override on options can be set in .vimrc (or elsewhere). All takes `1` for on and `0` for off.
```vim
g:Vfix_append         " Append to QuickFix error list
g:Vfix_copen          " Use copen
g:Vfix_silent         " Never open window
g:Vfix_reverse        " Reverse messages / errors LIFO
g:Vfix_ignore_lost    " Ignore errors where functions can not be resolved
g:Vfix_clr_always     " Clear :messages each time Vfix is executed
g:Vfix_auto_run       " Auto run on sourcing. Can be buggy.

g:Vfix_re_source_globals
" Mainly for hacking this script.
" If set and true global options will be reset when re-sourcing script.
```
##  :mega:&nbsp;&nbsp;&nbsp;Note

As it read the files where errors originated each file with errors will be added to the hidden buflist. (`ls!`).

Have a solution using `head` at least on OS with this program. Patch later.

##  :curly_loop:&nbsp;&nbsp;&nbsp;History

Is a snip that has been in my .vim directory for years, adding a little now and then. Likely a lot of bugs, ironically enough. Did some cleanup on the code and have likley introduced a few more. But put it out there in case anyone find it helpful.
