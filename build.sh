#!/usr/bin/env bash

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
    f:bbuild "$@" || {
        BUILDSTATUS=$((BUILDSTATUS+1))
        return
    }
}

use_bootstrap_script() {
    # running bin/bbuild to re-write itself leads to spurious
    # errors. Use a separate bootstrapping copy
    mkdir -p bin-candidates
    cp bin/bbuild bin-candidates/bbuild-bootstrap
    f:bbuild() {
        bin-candidates/bbuild-bootstrap "$@"
    }
}

set_build_outdir() {
    # By default, do NOT blat previous release !
    export BUILDOUTD=bin-candidates/
    RUN_TESTS=true
    f:bbuild() {
        bin/bbuild "$@"
    }

    if [[ "$*" =~ --release ]]; then
        use_bootstrap_script

        export BUILDOUTD=bin/
        RUN_TESTS=false
    fi
}

run_tests() {
    if [[ "$RUN_TESTS" = true ]]; then
        echo -e "\n--- Integration tests"
        test-integration/test-all.sh
        echo -e "---\n"
    fi
}

main() {
    local all_scripts=(bbuild bbrun bashdoc tarshc)

    set_build_outdir "$@"
    BUILDSTATUS=0

    if [[ -n "$*" ]] && [[ ! "$*" = --release ]]; then # Build specific
        for buildsrc in "${all_scripts[@]}"; do
            if _has "$buildsrc" "$@"; then
                _build "src/$buildsrc"
            fi
        done

        if _has install "$@"; then
            _build src/install.sh ./install.sh
        fi

    else # Build all
        for buildsrc in "${all_scripts[@]}"; do
            _build "src/$buildsrc"
        done

        _build src/install.sh ./install.sh
    fi

    run_tests

    [[ "$BUILDSTATUS" -le 0 ]] || {
        echo "BUILD FAIL -- $BUILDSTATUS failures"
        exit 1
    }

    echo "Version of bbuild is:"
    echo
    "$BUILDOUTD/bbuild" --version
}

main "$@"
