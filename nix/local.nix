{pkgs ? import <nixpkgs> {}}:
let packagesExt = pkgs // (import ./packages.nix { inherit pkgs; }); in
with packagesExt;
let
	isDarwin = stdenv.isDarwin;
	isLinux = stdenv.isLinux;
	bash = "#!${pkgs.bash}/bin/bash";
	wrapper = script: writeScript "wrapper" script;
	wrappers = {
		# ALL

	} // (if isLinux then {
		# LINUX only...
		"mount.ssh" = wrapper ''${bash}
			set -eu
			if [ "$#" -lt 2 ]; then
				echo "usage: mount.ssh [opts] remote local-dir"
				exit 2
			fi
			if [ ! -e "$2" ]; then
				echo "Making directory: $2"
				mkdir -p "$2"
			fi

			${sshfsFuse}/bin/sshfs "$@"
		'';

		# "my-gnome-shell" = wrapper ''${bash}
		# 	exec my-gnome-wrapper gnome-shell "$@"
		# '';
    #
		# "my-gnome-wrapper" = wrapper ''${bash}
		# 	exec /usr/bin/env \
		# 		SHELLSHAPE_DEBUG=1 \
		# 		XDG_DATA_DIRS=${builtins.getEnv "HOME"}/.local/share:${builtins.getEnv "HOME"}/.local/nix/share:/usr/local/share/:/usr/share/ \
		# 		"$@";
		# '';
	} else {});
	installed = with lib; remove null [
		my-nix-prefetch-scripts
		daglink
		git
		# gsel (XXX failing)
		ctags
		fish
		nodejs
		direnv
		# silver-searcher
		ripgrep
		music-import
		gup
		passe-client
		vim-watch
		vim
		vim.vimrc
		python2Packages.ipython
		python3Packages.ipython
		pyperclip

		(buildFromGitHub ./sources/piep.json)
		(buildFromGitHub ./sources/version.json)
	] ++ (if isLinux then [
		#tilda
		#spotify
		xbindkeys
		jsonnet
		pythonPackages.youtube-dl
		irank
		irank-releases
		eog-rate
		vlc
		parcellite
		dumbattr
		shellshape
		snip
		trash
		(runCommand "systemd-units" {} ''
			mkdir -p $out/share/systemd
			cp -a "${system.config.system.build.standalone-user-units}" $out/share/systemd/user
		'')
		(import ./applications.nix {inherit pkgs; })
		(runCommand "gnome-shell-extensions" {} ''
			mkdir -p $out/share/gnome-shell/extensions
			${concatStringsSep "\n" (remove null (mapAttrsToList (name: src:
				if src == null then null else ''
					for suff in xdg/data/gnome-shell/extensions share/gnome-shell/extensions; do
						if [ -e "${src}/$suff/${name}" ]; then
							ln -s "${src}/$suff/${name}" $out/share/gnome-shell/extensions/${name}
						else
							echo "Skipping non-existent gnome-shell extension: ${src}/$suff/${name}"
						fi
					done
				'') gnome-shell-extensions))
			}
		'')
	] else [
	]) ++ (
		mapAttrsToList (name: script:
			runCommand "${name}-wrapper" {} ''
				mkdir -p $out/bin
				ln -s ${script} $out/bin/${name}
			''
		) wrappers
	);
	dirs = [ "bin" "etc" "share"];
	system = import ./system.nix { pkgs = packagesExt; };
	gnome-shell-extensions = import ./gnome-shell.nix { pkgs = packagesExt; };
in
symlinkJoin { name = "local"; paths = installed; }
