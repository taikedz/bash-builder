#!/usr/bin/env bash

### Install Bash Builder Usage:help
#
#   ./install.sh [OPTIONS]
#
# Install the build utilities.
#
# This script can pull in the satndard library and install it for you.
#
# OPTIONS
#
# --libs=TARGET
#   Install the target version of the libraries. By default, 'latest-release'
#   
# --no-libs
#   Do not offer to install standard library
#
# --rc
#   Install from the release candidates directory instead of release directory
#
###/doc

#%include std/safe.sh
#%include std/autohelp.sh
#%include std/out.sh

main() {
    autohelp:check "$@"

    bindir="$HOME/.local/bin"
    libsdir="$HOME/.local/lib/bash-builder"

    LIBS_TARGET=latest-release
    parse_args "$@"

    if [[ "$UID" = 0 ]]; then
        bindir="/usr/local/bin"
        libsdir="/usr/local/lib/bash-builder"
    fi

    mkdir -p "$bindir"
    mkdir -p "$libsdir"

    cp "$INSTALL_SOURCE"/bbuild \
        "$INSTALL_SOURCE"/bashdoc \
        "$INSTALL_SOURCE"/tarshc \
        "$bindir/"
    ensure_bbpath

    out:info "Installed to '$bindir'."
    out:info "You may need to install libraries separately."

    install_libs
}

parse_args() {
    local item

    for item in "$@"; do
        case "$item" in
        --libs=*)
            LIBS_TARGET="${item#*=}"
            ;;
        --no-libs)
            LIBS_TARGET=""
            ;;
        --rc)
            INSTALL_SOURCE=bin-candidates/
            ;;
        *)
            out:fail "Unknown option '$item'"
            ;;
        esac
    done
}

install_libs() {
    local reply
    if [[ -z "$LIBS_TARGET" ]]; then
        return 0
    fi

    read -p "(Re)Install standard libraries? Y/n> " reply
    if [[ ! "$reply" =~ ^(y|Y|yes|YES|)$ ]]; then
        out:warn "Skipped installing libraries."
        return
    fi

    if [[ ! -e "bash-libs" ]]; then
        git clone https://github.com/taikedz/bash-libs
    fi

    "bash-libs/install.sh" "$LIBS_TARGET"
}

ensure_bbpath() {
    bashrcpath="$HOME/.bashrc"

    if [[ "$UID" = 0 ]]; then
        bashrcpath="/etc/bash.bashrc"
    fi

    if ! grep '^export BBPATH=' -q "$bashrcpath" ; then
        echo "export BBPATH=$libsdir" >> "$bashrcpath"
    fi
}

main "$@"
