#!/bin/bash

cd "$(dirname "$0")"
libsurl="https://github.com/taikedz/bash-libs"
libsdir=./bash-libs/libs

if [[ ! -d "$libsdir" ]] && [[ ! -L "$libsdir" ]]; then
	git clone "$libsurl" || {
		echo "Could not clone default libraries repo [$libsurl]"
		exit 1
	}
fi

if [[ "$UID" == 0 ]]; then
	libs=/usr/local/lib/bbuild
	binsd=/usr/local/bin
	BASHRCPATH=/etc/bash.bashrc
else
	libs="$HOME/.local/lib/bbuild"
	binsd="$HOME/.local/bin"
	BASHRCPATH="$HOME/.bashrc"
fi

if [[ ! "$PATH" =~ "$binsd" ]]; then
	echo "export PATH=\$PATH:$binsd" >> "$BASHRCPATH"
fi

if ! grep "BBPATH=" "$BASHRCPATH" -q; then
	echo "export BBPATH=\"$libs\"" >> "$BASHRCPATH"
fi

mkdir -p "$libs"
mkdir -p "$binsd"

cp "$libsdir"/* "$libs/"
if [[ "$UID" = 0 ]]; then
	chmod 644 "$libs"/*
fi

BUILDFILES=(src/bashdoc src/bbuild)

BBPATH="$libsdir" BUILDOUTD="$binsd" bash bootstrap/bootstrap-bbuild5 "${BUILDFILES[@]}" "$@" || exit 1

echo -e "\033[32;1mSuccessfully installed\033[0m"

if ! which shellcheck 2>&1 >/dev/null ; then
	echo 'Consider installing "shellcheck"'
fi
