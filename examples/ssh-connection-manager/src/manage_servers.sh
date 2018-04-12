edit_servers() {
    : ${EDITOR=nano}
    "$EDITOR" "$SERVERS_FILE"
}

add_server() {
    [[ -n "$*" ]] || out:fail "Please specify a server to add"

    local target="$1"; shift

    local addmessage="$*"
    [[ -z "$addmessage" ]] || addmessage=" # $addmessage"

    echo -e "%\t${target}${addmessage}" >> "$SERVERS_FILE"
}

delete_server() {
    [[ -n "$*" ]] || out:fail "Please specify a server to delete"

    local target="$1"; shift
    
    sed -r "/%\s+$target(\s+|$)/ d" -i "$SERVERS_FILE"
}
