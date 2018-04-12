choose_server() {
    init_serverfile

    local choice_routine="$(get_choice_routine "${1:-}")"

    local servers="$(load_servers)"
    [[ -n "${servers:-}" ]] || out:fail "No configured servers."

    local chosen_server=""
    local choice_command=("$choice_routine" "Connect to:" "$servers")
    
    if [[ -n "${choose:-}" ]]; then
        chosen_server="$( echo "$choose" | "${choice_command[@]}" 2>/dev/null )"
    else
        chosen_server="$( "${choice_command[@]}" )"
    fi

    chosen_server="$(de_annotate "$chosen_server")"

    echo "$chosen_server"
}

de_annotate() {
    local chosen="$*"
    chosen="${chosen%%#*}"
    echo "${chosen%% *}"
}

load_servers() {
    grep -P '^%\s+' "$SERVERS_FILE"|sed -r 's/^%\s+//'
}

get_choice_routine() {
    local choice_routine=askuser:choose
    [[ "${1:-}" = multi ]] && choice_routine=askuser:choose_multi

    echo "$choice_routine"
}
