#!/usr/bin/env bash

# By default, do NOT blat previous release !
export BUILDOUTD=bin-candidates/

if [[ "$*" =~ --release ]]; then
    export BUILDOUTD=bin/
fi

status=0

bin/bbuild src/bbuild                  ; status=$((status+$?))
bin/bbuild src/bashdoc                 ; status=$((status+$?))
bin/bbuild src/tarshc                  ; status=$((status+$?))
bin/bbuild src/install.sh ./install.sh ; status=$((status+$?))

[[ "$status" -le 0 ]] || {
    echo "BUILD FAIL"
    exit 1
}

echo "Version of bbuild is:"
echo
"$BUILDOUTD/bbuild" --version
