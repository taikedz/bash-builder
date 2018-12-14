#!/bin/bash

### Example of use of the TarSH functionality
###
### Of note, we include the local README.md to stand as a help file
###  and an executable script which we can invoke directly, as the bundled `bin/` directory
###  is added automatically by the runtime header included when the bundle is compiled.
###
### See the comments starting with `###`

set -euo pipefail

#%include std/out.sh

chomp() {
    sed "s/$1//"
}

get_default_device() {
    # Presume the first default route in the routing table gives us the main interface
    ip route | grep default | head -n 1 | grep -Po 'dev\s+[a-z0-9:@]+' | chomp "dev "
}

extract_inets() {
    local device="$1"
    grep "$device$" | grep -Po "inet\\s+[0-9.]+" | chomp "inet "
}

ip_for_device() {
    local device
    device="$1"; shift

    ### The tgz.sh's `bin/` directory is automatically added to the front of the PATH
    ###  so we can invoke `find_section.py` directly

    ip a | find_section.py "$device" | extract_inets "$device"
}

main() {
    if [[ "$*" =~ --help ]]; then
        ### We can use the "$TARWD" variable to access the location
        ###  where bundled assets were extracted to
        cat "$TARWD/README.md"
        exit 0
    fi

    local device myip

    device="$(get_default_device)"
    myip="$(ip_for_device "$device")"

    if [[ "$*" =~ -b ]]; then
        echo "$myip"
    else
        out:info "Your IP is: $myip"
    fi
}

main "$@"
