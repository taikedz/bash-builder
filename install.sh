#!/bin/bash

set -euo pipefail

SCRIPTDIR="$(cd $(dirname "$0"); pwd)"

parse_args() {
    local arg

    for arg in "$@"; do
        case "$arg" in
        --no-pull)
            # Don't try to pull commits from github/libs-dependency
            NO_UPDATE=true
            ;;
        --no-dependency)
            # Don't honour libs-dependency file
            NO_USE_DEPENDENCY=true
            NO_UPDATE=true
            ;;
        --no-install)
            # Do not install after build
            NO_INSTALL=true
            ;;
        verify)
            # Perform the verification task
            DO_VERIFY=true
            ;;
        *)
            die "Unknown option '$arg'"
            ;;
        esac
    done
}

die() {
    echo -e "$*" >&2
    exit 1
}

pull_libraries() {
    echo "Updating libraries ..."
    if [[ ! -d "$libsdir" ]]; then
        git clone "$libsurl" bash-libs || \
            die "Could not clone default libraries repo [$libsurl] to [bash-libs]"
    fi

    BASHLIBS_DEPENDENCY="$(cat libs-dependency)"

    if [[ "${NO_UPDATE:-}" != true ]]; then
	    (cd "$libsdir" && git status && git checkout master && git pull) || \
		    die "Could not update the default libraries in '$libsdir' !"
    fi

    if [[ "${NO_USE_DEPENDENCY:-}" != true ]]; then
        (cd "$libsdir" && git checkout "$BASHLIBS_DEPENDENCY")
    fi

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
    if [[ "${DO_VERIFY:-}" = true ]]; then

        # Note - uses environment BBEXEC
        bash-libs/verify.sh
        exit "$?"
    fi
}

run_build() {
    local installed_libs

    installed_libs="$(bash bash-libs/install.sh|tee /dev/stderr|grep -oP '(?<=\[)[^ ]+?(?=\])')" || die "Error getting installed path of libraries"

    BUILDFILES=(src/bashdoc src/bbuild src/tarshc)

    NO_LOAD_BBUILDRC=true BBSYNTAX=syntax BBPATH="$installed_libs" bash "${BBEXEC}" "${BUILDFILES[@]}" || exit 1
}

install_files() {
    if [[ "${NO_INSTALL:-}" = true ]]; then
        return 0
    fi

    cp ./build-outd/bbuild ./build-outd/bashdoc ./build-outd/tarshc "$binsd/" || \
        die "\033[31;1mFailed installing to [$binsd]\033[0m"

    echo -e "\033[32;1mSuccessfully installed 'bbuild', 'bashdoc', 'tarshc' to [$binsd]\033[0m"

    if ! which shellcheck >/dev/null 2>&1 ; then
        echo -e '\n\tConsider installing "shellcheck"\n'
    fi
}

compatibility_check() {
    if [[ "${DO_VERIFY:-}" ]]; then
        . "$SCRIPTDIR/src/compatibility.sh"
        compatibility:verify || die "Incompatible environment - are you using a GNU/Linux ?"
    fi
}

main() {
    : "${BBEXEC=$SCRIPTDIR/bootstrap/bootstrap-bbuild5}"

    parse_args "$@"
    compatibility_check

    cd "$SCRIPTDIR"
    set_paths
    pull_libraries
    run_verify
    environment_configuration

    run_build
    install_files
}

main "$@"
