#!/usr/bin/env bash

### Install Bash Builder Usage:help
#
#   ./install.sh [OPTIONS]
#
# Install the build utilities.
#
# OPTIONS
#
# --libs
# --libs=TARGET
#   Also install the target version of the libraries.
#   If target is not specified, install latest release version.
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

    install_libs
}

parse_args() {
    local item

    for item in "$@"; do
        case "$item" in
        --libs=*)
            LIBS_TARGET="${item#*=}"
            ;;
        --libs)
            LIBS_TARGET=latest-release
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
    if [[ -z "${LIBS_TARGET:-}" ]]; then
        out:warn "You may need to install additional bash-builder libraries separately."
        return 0
    fi

    if [[ ! -e "bash-libs" ]]; then
        git clone https://github.com/taikedz/bash-libs
    fi

    "bash-libs/install.sh" "${LIBS_TARGET:-}"
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
