#!/bin/bash

set -euo pipefail

pull_libraries() {
    echo "Updating libraries ..."
    if [[ ! -d "$libsdir" ]] && [[ ! -L "$libsdir" ]]; then
        git clone "$libsurl" bash-libs || {
            echo "Could not clone default libraries repo [$libsurl] to [bash-libs]"
            exit 1
        }
    fi

    BASHLIBS_DEPENDENCY="$(cat libs-dependency)"

    (cd "$libsdir" && git status && git checkout master && git pull && git checkout "$BASHLIBS_DEPENDENCY") || {
        echo "Could not update the default libraries in '$libsdir' !"
        exit 1
    }
    echo # just separate this operation
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

configure_install_environment() {
    if [[ ! "$PATH" =~ "$binsd" ]]; then
        echo "export PATH=\$PATH:$binsd" >> "$BASHRCPATH"
    fi

    if ! grep "BBPATH=" "$BASHRCPATH" -q; then
        echo "export BBPATH=\"$libs\"" >> "$BASHRCPATH"
    fi

    mkdir -p "$binsd"
}

run_verify() {
    if [[ "$*" =~ --verify ]]; then
        BBEXEC="$PWD/bootstrap/bootstrap-bbuild5" bash-libs/verify.sh
        exit "$?"
    fi
}

build_and_install() {
    bash bash-libs/install.sh

    BUILDFILES=(src/bashdoc src/bbuild src/tarshc)

    BBPATH="$libsdir" bash bootstrap/bootstrap-bbuild5 "${BUILDFILES[@]}" "$@" || exit 1
    cp ./build-outd/bbuild ./build-outd/bashdoc ./build-outd/tarshc "$binsd/" || {
        echo -e "\033[31;1mFailed installing to [$binsd]\033[0m"
        exit 1
    }

    echo -e "\033[32;1mSuccessfully installed 'bbuild', 'bashdoc', 'tarshc' to [$binsd]\033[0m"

    if ! which shellcheck >/dev/null 2>&1 ; then
        echo -e '\n\tConsider installing "shellcheck"\n'
    fi
}

main() {
    cd "$(dirname "$0")"
    set_paths
    pull_libraries
    run_verify "$@"
    configure_install_environment
    build_and_install
}

main "$@"
