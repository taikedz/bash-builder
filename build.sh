#!/usr/bin/env bash

# By default, do NOT blat previous release !
export BUILDOUTD=bin-candidates/

if [[ "$*" =~ --release ]]; then
    export BUILDOUTD=bin/
fi


BUILDSTATUS=0

_has() {
    local needle="$1"; shift
    local x

    res=1
    for x in "$@"; do
        if [[ "$x" = "$needle" ]]; then
            res=0
        fi
    done

    return "$res"
}

_build() {
    bin/bbuild "$@" || BUILDSTATUS=$((BUILDSTATUS+1))
}

SCRIPTS=(bbuild bbrun bashdoc tarshc)

if [[ -n "$*" ]]; then # Build specific
    for buildsrc in "${SCRIPTS[@]}"; do
        if _has "$buildsrc" "$@"; then
            _build "src/$buildsrc"
        fi
    done

    if _has install "$@"; then
        _build src/install.sh ./install.sh
    fi

else # Build all
    for buildsrc in "${SCRIPTS[@]}"; do
        _build "src/$buildsrc"
    done

    _build src/install.sh ./install.sh
fi


[[ "$BUILDSTATUS" -le 0 ]] || {
    echo "BUILD FAIL -- $BUILDSTATUS failures"
    exit 1
}

echo "Version of bbuild is:"
echo
"$BUILDOUTD/bbuild" --version
