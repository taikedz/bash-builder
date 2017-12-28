
add_server() {
	[[ -n "$*" ]] || out:fail "Please specify a server to add"

	local target="$1"; shift

	echo -e "%\t$target # $*" >> "$SERVERS_FILE"
}

delete_server() {
	[[ -n "$*" ]] || out:fail "Please specify a server to delete"

	local target="$1"; shift
	
	sed -r "/%\s+$target/ d" -i "$SERVERS_FILE"
}
