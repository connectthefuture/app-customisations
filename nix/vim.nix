{pkgs ? import <nixpkgs> {}, pluginArgs ? {}}:
with pkgs;
let
	macvim = lib.overrideDerivation (pkgs.macvim) (o: {
		configureFlags = o.configureFlags ++ [ "--enable-perlinterp=no" ];
	});
	vim_configurable = if stdenv.isDarwin
		then vimUtils.makeCustomizable macvim
		else pkgs.vim_configurable;
	knownPlugins = vimPlugins // (pkgs.callPackage ./vim-plugins.nix pluginArgs);
	vimrcConfig = {
		customRC = ''
			set nocompatible
			let g:vim_addon_manager.addon_completion_lhs=""
			if !empty(glob("~/.vimrc"))
				source ~/.vimrc
			else
				source ${../vim/vimrc}
			endif
		'';
		vam = {
			inherit knownPlugins;
			pluginDictionaries = [
				# load always
				{
					names = [
						"asyncrun"
						# "ack.vim"
						"ctrlp"
						"fish-syntax"
						"fugitive"
						"indent-finder"
						"ir-black"
						"misc"
						# "multiple-cursors"
						# "neomake"
						"repeat"
						"sensible"
						"Solarized"
						"surround"
						"Tagbar"
						"targets"
						"tcomment"
						"The_NERD_tree"
						"vala.vim"
						"vim-indent-object"
						"vim-grepper"
						"vim-nix"
						"vim-rust"
						"vim-stratifiedjs"
						"vim-visual-star-search"
						"vim-watch"
					]
					++ (if knownPlugins.gsel == null then [] else ["gsel"])
					++ (if stdenv.isDarwin then [] else ["command-t"])
					;
				}
				# full documentation at
				# github.com/MarcWeber/vim-addon-manager
			];
		};
	};
	vim = vim_configurable.customize {
		name = "vim"; # actual binary name
		inherit vimrcConfig;
	};
	vimrc = vimUtils.vimrcFile vimrcConfig;
in
stdenv.mkDerivation {
	name = "vim-custom";
	buildInputs = [ makeWrapper ];
	unpackPhase = "true";
	passthru = {
		vimrc = runCommand "vimrc" {} ''
			mkdir -p $out/share/vim/
			ln -s ${vimrc} $out/share/vim/vimrc
		'';
	};
	installPhase = ''
		mkdir -p $out/bin
		makeWrapper ${vim}/bin/vim $out/bin/vim \
			--prefix PATH : ${silver-searcher}/bin \
			--prefix PATH : ${python}/bin \
			--prefix PATH : ${ctags}/bin \
		;
		echo -e "#!${bash}/bin/bash\nexec \"$out/bin/vim\" -g \"\$@\"" > $out/bin/gvim
		chmod +x $out/bin/*
	'';
}
