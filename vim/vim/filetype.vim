" markdown filetype file

if exists("did\_load\_filetypes")
    finish
endif
augroup markdown
    au! BufRead,BufNewFile *.md   setfiletype mkd
augroup END

augroup narrativejavascript
    au! BufRead,BufNewFile *.njs   setfiletype javascript
    au! BufRead,BufNewFile *.jss   setfiletype javascript
augroup END

