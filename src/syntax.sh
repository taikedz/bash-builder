### Syntax Post-processing Usage:syntax
#
# Bash Builder adds some post-processing to built files
# to allow some extra features.
#
# It is active by default ; you can set an environment variable
# `BBSYNTAX=off` to prevent it from activating.
#
###/doc

bbuild:syntax_post() {
    [[ "${BBSYNTAX:-}" != off ]] || return 0

	local target="${1:-}"; shift || out:fail "No syntax post-processing target supplied !"
	
    bbuild:syntax:expand_function_signatures "$target"
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

