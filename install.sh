#!/usr/bin/env bash

main() {
    bindir="$HOME/.local/bin"
    libsdir="$HOME/.local/lib/bash-builder"

    if [[ "$UID" = 0 ]]; then
        bindir="/usr/local/bin"
        libsdir="/usr/local/lib/bash-builder"
    fi

    mkdir -p "$bindir"
    mkdir -p "$libsdir"

    cp bin/bbuild bin/bashdoc bin/tarshc "$bindir/"
    ensure_bbpath

    echo "Installed to '$bindir'."
    echo "You may need to install libraries separately."

    install_libs
}

install_libs() {
    read -p "(Re)Install standard libraries? Y/n> "
    if [[ ! "$REPLY" =~ ^(y|Y|yes|YES|)$ ]]; then
        echo "Skipped installing libraries."
        return
    fi

    if [[ ! -e "bash-libs" ]]; then
        git clone https://github.com/taikedz/bash-libs
    fi

    "bash-libs/install.sh" "latest-release"
}

ensure_bbpath() {
    bashrcpath="$HOME/.bashrc"

    if [[ "$UID" = 0 ]]; then
        bashrcpath="/etc/bash.bashrc"
    fi

    if ! grep '^export BBPATH=' ; then
        echo "BBPATH=$libsdir" >> "$bashrcpath"
    fi
}

main "$@"
