COMPATIBILITY_status=0

compat:warn() {
    local tool="$1"; shift
    echo -e "\033[33;1mWARN: '$tool' : Need $*\033[0m"
    COMPATIBILITY_status=1
}

compat:ok() {
    local tool="$1"; shift
    echo -e "\033[32;1m OK : $tool\033[0m"
}

compat:check() {
    local message="$1"; shift
    local seek="$1"; shift

    compat:hasbins "$1" || {
        compat:warn "$1" "to be installed"
        return 0
    }

    if [[ -n "$seek" ]]; then
        "$@" 2>&1 | grep -q "$seek" && compat:ok "$message" || compat:warn "$1" "$message"
    else
        compat:ok "$message"
    fi
}

compat:hasbins() {
    local bin
    for bin in "$@"; do
        if which "$bin" >/dev/null 2>&1 ; then
            return 0
        fi
    done
    return 1
}

compat:requirebins() {
    local tool message
    tool="$1"; shift
    message="$1"; shift
    compat:hasbins "$@" && compat:ok "$message" || compat:warn "$tool" "$message"
}

compatibility:verify() {
    which which >/dev/null 2>&1 || {
        compat:warn "which" "essential ! -- ABORT"
        exit 1
    }

    compat:check "GNU bash" "GNU bash" bash --version
    compat:check "GNU grep" "GNU grep" grep --version
    compat:check "GNU sed" "GNU sed" sed --version
    compat:check "coreutils base64" "coreutils" base64 --version

    compat:requirebins "head, cat, ..." "basic tools" head tail cat basename dirname
    compat:requirebins "tee" "tee" tee

    # Optional, really

    # Autohelp
    compat:check "tput" "" tput
    compat:check "coreutils fold" "coreutils" fold --version

    # cdiff
    compat:check "GNU diffutils" "GNU" diff --version

    # crypt
    compat:check "OpenSSL" "" openssl

    # git
    compat:check "git" "" git

    # guiout
    compat:requirebins "gui tool" "xmessage or zenity" xmessage zenity

    # sums
    compat:check "GNU bc calculator" "Free Software Foundation" bc --version

    # tarheader
    compat:check "GNU tar" "GNU tar" tar --version
    
    return "$COMPATIBILITY_status"
}

if [[ "$(basename "$0")" = compatibility.sh ]]; then
    compatibility:verify
fi
