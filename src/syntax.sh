
### Syntax Post-processing Usage:syntax
#
# Bash Builder adds some post-processing to built files
# to allow some extra features.
#
# It is active by default ; you can set an environment variable
# `BBSYNTAX=off` to prevent it from activating.
#
###/doc

# TODO - there are several array-related shortcuts to add
# * transparent handling of serialization
#   * though this may be rendered less relevant with strict mode

bbuild:syntax_post() {
    [[ "${BBSYNTAX:-}" != off ]] || return 0

	local target="${1:-}"; shift || out:fail "No syntax post-processing target supplied !"
	
    bbuild:syntax:expand_function_signatures "$target"
    bbuild:syntax:dot_arrays "$target"
}

### Function signature expansion Usage:syntax
#
# An option to use a function's signature to declare local variables.
# Requires your script to include `args.sh`
#
# NOTE: function names must match the following regex:
#   ^[a-zA-Z0-9_:.-]+$
#
# 	You write ===>   $%function functionname(var1 var2 var3) {
#
# 	You get   ===>   functionname() { . <(args:use:local var1 var2 var3 -- "$@") ;
#
# 	Example:
#
# 	    $%myfunc(firstname lastname) {
# 	        echo "Hello $lastname, $firstname - you have a new message!"
# 	        echo "$*"
# 	    }
###/doc
bbuild:syntax:expand_function_signatures() {
    sed -r 's/^(\s*)\$''%function\s*([a-zA-Z0-9_:.-]+)\(([^)]+?)\)\s+\{''/''\1\2() {\n\1    . <(args:use:local \3 -- "$@") ; ''/' -i "$1"
}

### Dot notation for associative arrays Usage:syntax
#
# Access a data map array via dot notation:
#
# Dot notation is identified by use of `$%.`
#
# Assignment is done by using an `=` sign immediately after the dot notation
#
#   $%.object.property1=value
#   $%.object.property2=stuff
#
# Value printing is done by not including an equality sign
#
#   echo "$%.object.property1"
#
# An iterable series of values can be printed using `@` notation
#
#   process_values "$%.object[@]"
#
# The values themselves, on one line, can be printed using `*` notation
#
#   echo "$%.object[*]"
#
###/doc
bbuild:syntax:dot_arrays() {
    local transforms
    transforms=(
        # $%.object.property=     --> object[property]=
        # $%.object.$placeholder= --> object[$placeholder]=
        -e 's/\$%\.([a-zA-Z0-9_]+)\.([$a-zA-Z0-9_]+)=/\1[\2]=/g'

        # $%.object.property     --> ${object[property]}
        # $%.object.$placeholder --> ${object[$placeholder]}
        -e 's/\$%\.([a-zA-Z0-9_]+)\.([$a-zA-Z0-9_]+)/${\1[\2]}/g'

        # $%.object[!] --> ${!object[@]}
        -e 's/\$%\.([a-zA-Z0-9_]+)\[\!\]/${!\1[@]}/g'

        # $%.object[@] --> ${object[@]}
        -e 's/\$%\.([a-zA-Z0-9_]+)\[@\]/${\1[@]}/g'

        # $%.object[*] --> ${object[*]}
        -e 's/\$%\.([a-zA-Z0-9_]+)\[\*\]/${\1[*]}/g'

        # $%.object[<some variable or string>] --> ${object[<the same>]}
        -e 's/\$%\.([a-zA-Z0-9_]+)\[([^]]+)\]/${\1[\2]}/g'

        # local $%.object --> declare -A object
        -e 's/local\s+\$%\.([a-zA-Z0-9_]+)/declare -A \1/g'

        # $%.object --> declare -Ag object
        -e 's/\$%\.([a-zA-Z0-9_]+)/declare -Ag \1/g'
    )

    sed -r "${transforms[@]}" -i "$1"

    if grep "\$%\." "$1"|grep -vP '^\s*#' ; then
        out:fail "--- Some dot-array syntax did not convert ---"
    fi
}
