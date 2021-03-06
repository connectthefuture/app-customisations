function __rerun_last_line
	commandline -r ""
	and commandline -f history-search-backward execute
end

function fish_user_key_bindings -d "My key bindings for fish"
	bind --erase \cg
	bind \cg complete_with_gsel

	# because of https://github.com/fish-shell/fish-shell/issues/1668
	bind --erase \cr
	bind --erase -k f5
	bind \cr __rerun_last_line
	bind -k f5 __rerun_last_line
end
