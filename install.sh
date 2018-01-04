#!/bin/bash

set -euo pipefail

pull_libraries() {
	if [[ ! -d "$libsdir" ]] && [[ ! -L "$libsdir" ]]; then
		git clone "$libsurl" || {
			echo "Could not clone default libraries repo [$libsurl]"
			exit 1
		}
	fi
}

set_paths() {
	libsurl="https://github.com/taikedz/bash-libs"
	libsdir=./bash-libs/libs

	if [[ "$UID" == 0 ]]; then
		export libs=/usr/local/lib/bbuild
		binsd=/usr/local/bin
		BASHRCPATH=/etc/bash.bashrc
	else
		export libs="$HOME/.local/lib/bbuild"
		binsd="$HOME/.local/bin"
		BASHRCPATH="$HOME/.bashrc"
	fi
}

environment_configuration() {
	if [[ ! "$PATH" =~ "$binsd" ]]; then
		echo "export PATH=\$PATH:$binsd" >> "$BASHRCPATH"
	fi

	if ! grep "BBPATH=" "$BASHRCPATH" -q; then
		echo "export BBPATH=\"$libs\"" >> "$BASHRCPATH"
	fi

	mkdir -p "$binsd"
}

run_build() {
	bash bash-libs/install.sh

	BUILDFILES=(src/bashdoc src/bbuild)

	BBPATH="$libsdir" bash bootstrap/bootstrap-bbuild5 "${BUILDFILES[@]}" "$@" || exit 1
	cp ./build-outd/bbuild ./build-outd/bashdoc "$binsd/"

	echo -e "\033[32;1mSuccessfully installed 'bbuild' to [$binsd]\033[0m"

	if ! which shellcheck 2>&1 >/dev/null ; then
		echo -e '\n\tConsider installing "shellcheck"\n'
	fi
}

main() {
	cd "$(dirname "$0")"
	set_paths
	pull_libraries
	environment_configuration
	run_build
}
