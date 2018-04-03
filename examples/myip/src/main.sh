#!/bin/bash

set -euo pipefail

#%include out.sh

chomp() {
	sed "s/$1//"
}

main() {
	if [[ "$*" =~ --help ]]; then
		# We can use the "$TARWD" variable to access the location where bundled assets were extracted to
		cat "$TARWD/README.md"
		exit 0
	fi

	local device="$(ip route | grep default | head -n 1 | grep -Po 'dev\s+[a-z0-9]+' | chomp "dev ")"

	# The tar/sh's bin/ directory is automatically added to the front of the PATH
	#  so we can invoke `find_section.py` directly

	out:info "Your IP is: $(ip a | find_section.py "$device" | grep -Po "inet\\s+[0-9.]+"| chomp "inet ")"
}

main "$@"
