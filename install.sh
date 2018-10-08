#!/bin/bash

set -euo pipefail

SCRIPTDIR="$(cd $(dirname "$0"); pwd)"

printhelp() {
cat <<EOHELP

Install Bash Builder

    ./install.sh [verify] [OPTION ...]

With no specified action, installs the libraries and executables. 

If run as non-root user, will install files to ~/.local/{bin,lib}

If run as root user, will install files to /usr/local/{bin,lib}

With the "verify" action, runs the compatibility check, then runs the libraries verification routines. Installs nothing.

Options:

--no-pull
    Don't try to pull/update the bash-libs/ repository

--depend=REF
    Checkout the specified reference REF in bash-libs/
    e.g. "1.1.6" or "master" or "98aef87"

--no-dependency
    Do not try to change the state of bash-libs/
    Overrides --depend=*

--no-install
    Perform the build, but do not install files
    Does not install libs files either

--clear-libs
    Clear existing files from the destination library dir (~/.local/lib/bbuild or /usr/local/lib/bbuild)
        before installing the new files

--compatible-bbpath
    Newer versions of Bash Libs will install to \$libs/bb instead of directly to \$libs
    This will mean inclusions need to be re-written from '#%include out.sh' to '#%include bb/out.sh'
    Use this option to add 'bb/' directly to BBPATH for new installations.
    For existing installations, edit ~/.bashrc or /etc/bash.bashrc as required

EOHELP
}

parse_args() {
    local arg
    ADD_SUB_BBPATH=false

    for arg in "$@"; do
        case "$arg" in
        --help|-h)
            printhelp
            exit 0
            ;;
        --no-pull)
            NO_UPDATE=true
            ;;
        --no-dependency)
            NO_USE_DEPENDENCY=true
            NO_UPDATE=true
            ;;
        --no-install)
            NO_INSTALL=true
            ;;
        --depend=*)
            DEPEND="${arg#--depend=}"
            ;;
        --clear-libs)
            CLEAR_LIBS=true
            ;;
        --compatible-bbpath)
            ADD_SUB_BBPATH=true
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

    BASHLIBS_DEPENDENCY="${DEPEND:-$(cat libs-dependency)}"

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

    local targets="$libs"
    if [[ "${ADD_SUB_BBPATH:-}" ]]; then
        targets="$targets:$libs/bb"
    fi

    if ! grep "BBPATH=" "$BASHRCPATH" -q; then
        echo "export BBPATH=\"$targets\"" >> "$BASHRCPATH"
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
    if [[ "${NO_INSTALL:-}" = true ]]; then
        BBPATH="$libsdir"
    else
        BBPATH="$(
            CLEAR_EXISTING_LIBS="${CLEAR_LIBS:-}" bash bash-libs/install.sh|tee /dev/stderr|grep -oP '(?<=\[)[^ ]+?(?=\])'
        )" || die "Error getting installed path of libraries"
    fi

    BUILDFILES=(src/bashdoc src/bbuild src/tarshc)

    NO_LOAD_BBUILDRC=true bash "${BBEXEC}" "${BUILDFILES[@]}" || exit 1
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
