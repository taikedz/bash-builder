#!/bin/bash

set -euo pipefail

pull_libraries() {
    echo "Updating libraries ..."
    if [[ ! -d "$libsdir" ]] && [[ ! -L "$libsdir" ]]; then
        git clone "$libsurl" || {
            echo "Could not clone default libraries repo [$libsurl]"
            exit 1
        }
    fi

    BASHLIBS_DEPENDENCY="$(cat libs-dependency)"

    (cd "$libsdir" && git pull && git checkout "$BASHLIBS_DEPENDENCY") || {
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

environment_configuration() {
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

run_build() {
    bash bash-libs/install.sh

    BUILDFILES=(src/bashdoc src/bbuild src/tarshc)

    BBPATH="$libsdir" bash bootstrap/bootstrap-bbuild5 "${BUILDFILES[@]}" "$@" || exit 1
    cp ./build-outd/bbuild ./build-outd/bashdoc ./build-outd/tarshc "$binsd/"

    echo -e "\033[32;1mSuccessfully installed 'bbuild', 'bashdoc', 'tarshc' to [$binsd]\033[0m"

    if ! which shellcheck 2>&1 >/dev/null ; then
        echo -e '\n\tConsider installing "shellcheck"\n'
    fi
}

main() {
    cd "$(dirname "$0")"
    set_paths
    pull_libraries
    run_verify "$@"
    environment_configuration
    run_build
}

main "$@"
