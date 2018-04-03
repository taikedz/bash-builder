#!/bin/bash

set -euo pipefail

##bash-libs: out.sh @ d4f2e817-modified

##bash-libs: colours.sh @ d4f2e817-modified

### Colours for bash Usage:bbuild
# A series of colour flags for use in outputs.
#
# Example:
# 	
# 	echo -e "${CRED}Some red text ${CBBLU} some blue text $CDEF some text in the terminal's default colour")
#
# Requires processing of escape characters.
#
# Colours available:
#
# CRED, CBRED, HLRED -- red, bold red, highlight red
# CGRN, CBGRN, HLGRN -- green, bold green, highlight green
# CYEL, CBYEL, HLYEL -- yellow, bold yellow, highlight yellow
# CBLU, CBBLU, HLBLU -- blue, bold blue, highlight blue
# CPUR, CBPUR, HLPUR -- purple, bold purple, highlight purple
# CTEA, CBTEA, HLTEA -- teal, bold teal, highlight teal
#
# CDEF -- switches to the terminal default
# CUNL -- add underline
#
# Note that highlight and underline must be applied or re-applied after specifying a colour.
#
###/doc

export CRED=$(echo -e "\033[0;31m")
export CGRN=$(echo -e "\033[0;32m")
export CYEL=$(echo -e "\033[0;33m")
export CBLU=$(echo -e "\033[0;34m")
export CPUR=$(echo -e "\033[0;35m")
export CTEA=$(echo -e "\033[0;36m")

export CBRED=$(echo -e "\033[1;31m")
export CBGRN=$(echo -e "\033[1;32m")
export CBYEL=$(echo -e "\033[1;33m")
export CBBLU=$(echo -e "\033[1;34m")
export CBPUR=$(echo -e "\033[1;35m")
export CBTEA=$(echo -e "\033[1;36m")

export HLRED=$(echo -e "\033[41m")
export HLGRN=$(echo -e "\033[42m")
export HLYEL=$(echo -e "\033[43m")
export HLBLU=$(echo -e "\033[44m")
export HLPUR=$(echo -e "\033[45m")
export HLTEA=$(echo -e "\033[46m")

export CDEF=$(echo -e "\033[0m")

### Console output handlers Usage:bbuild
#
# Write data to console stderr using colouring
#
###/doc

### Environment Variables Usage:bbuild
#
# MODE_DEBUG : set to 'true' to enable debugging output
# MODE_DEBUG_VERBOSE : set to 'true' to enable command echoing
#
###/doc

: ${MODE_DEBUG=false}
: ${MODE_DEBUG_VERBOSE=false}

# Internal
function out:buffer_initialize {
	OUTPUT_BUFFER_defer=(:)
}
out:buffer_initialize

### out:debug MESSAGE Usage:bbuild
# print a blue debug message to stderr
# only prints if MODE_DEBUG is set to "true"
###/doc
function out:debug {
	if [[ "$MODE_DEBUG" = true ]]; then
		echo "${CBBLU}DEBUG: $CBLU$*$CDEF" 1>&2
	fi
}

### out:debug:fork [MARKER] Usage:bbuild
#
# Pipe the data coming through stdin to stdout
#
# If debug mode is on, *also* write the same data to stderr, each line preceded by MARKER
#
# Insert this debug fork into pipes to see their output
#
###/doc
function out:debug:fork {
	if [[ "$MODE_DEBUG" = true ]]; then
		local MARKER="${1:-DEBUG: }"; shift || :

		cat - | sed -r "s/^/$MARKER/" | tee -a /dev/stderr
	else
		cat -
	fi
}

### out:info MESSAGE Usage:bbuild
# print a green informational message to stderr
###/doc
function out:info {
	echo "$CGRN$*$CDEF" 1>&2
}

### out:warn MESSAGE Usage:bbuild
# print a yellow warning message to stderr
###/doc
function out:warn {
	echo "${CBYEL}WARN: $CYEL$*$CDEF" 1>&2
}

### out:defer MESSAGE Usage:bbuild
# Store a message in the output buffer for later use
###/doc
function out:defer {
	OUTPUT_BUFFER_defer[${#OUTPUT_BUFFER_defer[@]}]="$*"
}

### out:flush HANDLER ... Usage:bbuild
#
# Pass the output buffer to the command defined by HANDLER
# and empty the buffer
#
# Examples:
#
# 	out:flush echo -e
#
# 	out:flush out:warn
#
# (escaped newlines are added in the buffer, so `-e` option is
#  needed to process the escape sequences)
#
###/doc
function out:flush {
	[[ -n "$*" ]] || out:fail "Did not provide a command for buffered output\n\n${OUTPUT_BUFFER_defer[*]}"

	[[ "${#OUTPUT_BUFFER_defer[@]}" -gt 1 ]] || return 0

	for buffer_line in "${OUTPUT_BUFFER_defer[@]:1}"; do
		"$@" "$buffer_line"
	done

	out:buffer_initialize
}

### out:fail [CODE] MESSAGE Usage:bbuild
# print a red failure message to stderr and exit with CODE
# CODE must be a number
# if no code is specified, error code 127 is used
###/doc
function out:fail {
	local ERCODE=127
	local numpat='^[0-9]+$'

	if [[ "$1" =~ $numpat ]]; then
		ERCODE="$1"; shift || :
	fi

	echo "${CBRED}ERROR FAIL: $CRED$*$CDEF" 1>&2
	exit $ERCODE
}

### out:error MESSAGE Usage:bbuild
# print a red error message to stderr
#
# unlike out:fail, does not cause script exit
###/doc
function out:error {
	echo "${CBRED}ERROR: ${CRED}$*$CDEF" 1>&2
}

### out:dump Usage:bbuild
#
# Dump stdin contents to console stderr. Requires debug mode.
#
# Example
#
# 	action_command 2>&1 | out:dump
#
###/doc

function out:dump {
	echo -n "${CBPUR}$*" 1>&2
	echo -n "$CPUR" 1>&2
	cat - 1>&2
	echo -n "$CDEF" 1>&2
}

### out:break MESSAGE Usage:bbuild
#
# Add break points to a script
#
# Requires MODE_DEBUG set to true
#
# When the script runs, the message is printed with a propmt, and execution pauses.
#
# Press return to continue execution.
#
# Type `exit`, `quit` or `stop` to stop the program. If the breakpoint is in a subshell,
#  execution from after the subshell will be resumed.
#
###/doc

function out:break {
	[[ "$MODE_DEBUG" = true ]] || return 0

	echo -en "${CRED}BREAKPOINT: $* >$CDEF " >&2
	read
	if [[ "$REPLY" =~ quit|exit|stop ]]; then
		out:fail "ABORT"
	fi
}

if [[ "$MODE_DEBUG_VERBOSE" = true ]]; then
	set -x
fi

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
