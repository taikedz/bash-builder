#!/usr/bin/env bash

#%include std/test.sh
#%include std/abspath.sh
#%include std/syntax-extensions.sh

TESTS=(
    include-count
    function-signature
    trap
)

move_to_here() {
    cd "$(dirname "$0")"

    bbuild_bin="$(abspath:path "$PWD/../bin-candidates")/bbuild"

    f:bbuild() {
        "$bbuild_bin" "$@"
    }

    out:info "f:bbuild = [$bbuild_bin]"
}

f:count() {
    local i="$1"; shift

    [[ "$("$@")" = "$i" ]]
}

$%function t:trap(scriptfile) {
    test:require grep "Came out" -q <("$scriptfile")
}

$%function t:function-signature(scriptfile) {
    test:require grep "Running" -q <("$scriptfile")
}

$%function t:include-count(scriptfile) {
    test:require f:count 1 grep '##bash-libs: safe\.sh' -c "$scriptfile"
}

main() {
    local testname

    move_to_here

    for testname in "${TESTS[@]}"; do
        test:require f:bbuild "src/$testname.sh" "run-${testname}.sh"

        "t:$testname" "./run-${testname}.sh"

        rm "run-${testname}.sh"
    done

    test:report
}

main "$@"
