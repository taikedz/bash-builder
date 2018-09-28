### Syntax Subfeatures Usage:help
#
# Bash Builder adds some post-processing to built files
# as an option, to allow some extra features.
#
# You can opt to switch on all syntax post-processing
# subfeatures ("syntax extensions")
#
# Syntax extensions include:
#
# 'expandarg1':
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
# 'expandlocal':
#
# An option which allows quickly defining a local variable
#
# 	You write ===>   $%myvar=
#
# 	You get   ===>   local myvar=
#
###/doc

bbuild:syntax_post() {
	# Syntax post-processor
	local target="${1:-}"; shift || :
	
	bbuild:syntax:expand_local "$target"
	bbuild:syntax:expand_arg1 "$target"
}

bbuild:syntax:use() {
	[[ "$BBUILD_syntax_features" =~ "$1" ]]
}

bbuild:syntax:expand_arg1() {
	bbuild:syntax:use syntax || bbuild:syntax:use expandarg1 || return
	# adjacent quotes prevent this code from mangling itself
	sed -r 's/=\$''%1\s*/="${1:-}"; shift /g' -i "$1"
}

bbuild:syntax:expand_local() {
	bbuild:syntax:use syntax || bbuild:syntax:use expandlocal || return
	sed -r 's/^(\s*)\$%([a-zA-Z0-9_]+)=/\1local \2=/g' -i "$1"
}
