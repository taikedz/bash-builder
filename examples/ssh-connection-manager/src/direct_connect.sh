
ssh_connect() {
    local chosen="$(choose_server)"

    # If the assignment step failed, then the variable is not set
    # use curly brace notation
    [[ -n "${chosen:-}" ]] || exit 1

    out:info "Connecting to [$chosen]"
    ssh "$chosen"
}

ssh_run() {
    local chosen=( $(choose_server multi) )

    # If the assignment step failed, then the variable is not set
    # use curly brace notation
    [[ -n "${chosen:-}" ]] || exit 1

    for chosen_host in "${chosen[@]}"; do
        out:info "Running on [$chosen_host]"
        ssh "$chosen_host" "$@" || :
    done
}

copyover_files() {
    # Assert that there are at least 3 arguments, or fail
    [[ -n "${3:-}" ]] || out:fail "Usage: (/push|/pull) DEST FILES ..."

    local action="$1"; shift
    local chosen="$(choose_server)"

    # If the assignment step failed, then the variable is not set
    # use curly brace notation
    [[ -n "${chosen:-}" ]] || exit 1

    local portdef=''

    # Assert that chosen has a port def and extract it, or do nothing (`:`) (to evade the on-error bailout)
    [[ "$chosen" =~ :[0-9]+$ ]] && {
        portdef="-P ${chosen#*:}"
        chosen="${chosen%:*}"
    } || :

    local dest="$1"; shift
    
    case "$action" in
    /push)
        out:info "Copying [$*] to [$chosen:$dest]"
        # Do not quote portdef as it has multiple tokens
        scp ${portdef:-} "$@" "$chosen:$dest"
        ;;
    /pull)
        out:info "Copying each [$*] in [$chosen] to local [$dest]"

        #FIXME note: cannot process spaces in arrays properly in bash
        remotefiles=( $(remote_files_tokens "$chosen" "$@") )
        scp ${portdef:-} "${remotefiles[@]}" "$dest"
        ;;
    esac
}

remote_files_tokens() {
    local chosen="$1"; shift

    local tokens=(.)

    while [[ -n "$*" ]]; do
        tokens[${#tokens[@]}]="$chosen:$1"
        shift
    done

    #FIXME in truth, it is not possible to return an array
    echo "${tokens[@]:1}"
}

ssh_copykey() {
    local chosen=( $(choose_server multi) )
    [[ -n "${chosen:-}" ]] || exit 1

    for chosen_host in "${chosen[@]}"; do
        out:info "Connecting to [$chosen_host]"
        ssh-copy-id "$chosen_host"
    done
    out:info "Copying [$*] to [$chosen:$dest]"
    # Do not quote portdef as it has multiple tokens
    scp ${portdef:-} "$@" "$chosen:$dest"
}
