### Syntax Post-processing Usage:help
#
# Bash Builder adds some post-processing to built files
# as an option, to allow some extra features.
#
# You can opt to switch on all syntax post-processing
# subfeatures ("syntax extensions"), or individual ones
#
###/doc

# TODO - there are several array-related shortcuts to add
# * transparent handling of serialization
#   * though this may be rendered less relevant with strict mode
# * associative arrays

bbuild:syntax_post() {
	# Syntax post-processor
	local target="${1:-}"; shift || :
	
	bbuild:syntax:expand_local "$target"
	bbuild:syntax:expand_arg1 "$target"
    bbuild:syntax:expand_function_signatures "$target"
}

bbuild:syntax:use() {
    [[ -n "${BBSYNTAX[*]}" ]] &&
        [[ "$BBSYNTAX" =~ syntax ]] ||
        [[ "$BBSYNTAX" =~ "$1" ]]
}

### expandarg1 Usage:bbuild
#
# An option which allows safe assignment of the first argument, and
# forces a shift. The shift itself may error, allowing it to be caught.
#
# 	You write ==>   =$%1
#
# 	You get   ==>   ="${1:-}"; shift
#
# 	Example :
#
# 		myfunc() {
# 			person=$%1  || out:fail "person not specified"
# 			message=$%1 || out:fail "message not specified"
#
# 			echo "Hello $person : $message"
# 		}
#
##/doc
bbuild:syntax:expand_arg1() {
	bbuild:syntax:use expandarg1 || return 0
	# adjacent quotes prevent this code from mangling itself
	sed -r 's/=\$''%1\s*/="${1:-}"; shift /g' -i "$1"
}

### expandlocal Usage:bbuild
#
# An option which allows quickly defining a local variable
#
# 	You write ===>   $%myvar=
#
# 	You get   ===>   local myvar=
#
# 	Example:
#
# 	    myfunc() {
# 	        # declare a local variable person
# 	        $%person="$1"
#
# 	        echo "Hello $person"
# 	    }
###/doc
bbuild:syntax:expand_local() {
	bbuild:syntax:use expandlocal || return 0
	sed -r 's/^(\s*)\$''%([a-zA-Z0-9_]+)=/\1local \2=/g' -i "$1"
}

### expandfsig Usage:bbuild
#
# An option to use a function's signature to declare local variables
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
	bbuild:syntax:use expandfsig || return 0
    sed -r 's/^(\s*)\$''%function\s*([a-zA-Z0-9_:.-]+)\(([^)]+?)\)\s+\{''/''\1\2() {\n\1    . <(args:use:local \3 -- "$@") ; ''/' -i "$1"
}

###### +++++++++++++++++++++++++++

### Example and test
# Direct test
#   (
#       . src/syntax.sh
#       bbuild test-syntax.sh
#       BBSYNTAX=syntax bbuild:syntax_post build-outd/test-syntax.sh # This will eventually integrate to bbuild itself
#       build-outd/test-syntax.sh Alice Bob "extra data"
#   )

# Test data in "test-syntax.sh" :

###%include args.sh
##
##$%function sayhello(name1 name2) {
##	$%myvar=$%1
##
##	echo "Hello $name1 and $name2, myvar is $myvar"
##}
##
##sayhello "$@"
