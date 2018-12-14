# Writing Safe, Maintainable Bash Scripts

You may be used to the idea that bash is a kludgy language to program in, and seen the horrors of long, indecipherable bash routines.

These are some tips to improve your bash script writing to create clean, manageable scripts. It is by no means a course in bash, but should help in managing the logic flow properly, and make your scripts more readable, and more maintainable.

Note that for the most part these tips apply to GNU bash; the original Bourne shell as found on BSD, macOS and other UNIX-like environments, as well as the Linux `/bin/sh`, may not support some of the options discussed.

## Linting: use shellcheck

You can install shellcheck on Ubuntu and Fedora/CentOS:

	# Debian, Ubuntu, Mint
	apt-get update && apt-get install shellcheck -y

	# Fedora
	dnf install epel-release -y
	dnf install shellcheck -y

	# CentOS, Red Hat
	yum install epel-release -y
	yum install shellcheck -y

Run this against your script to get a static analysis of your shell code!

## Use safe runtime modes

> This can be used in both `bash` and `sh` - and should always be!

At the top of your script, set the appropriate runtime modes to catch errors and bail early.

A good line to include at the top of a file is:

	set -euo pipefail

> The `-e` mode causes a shell to exit immedaitely, or a function to return immediately, should a command return a non-zero status

... except when the command is part of an `if` or `while` condition check.

The following script:

	set -e
	false
	echo "Passed"

will echo nothing, as `false` returns a non-zero status, whereas

	set -e
	if false; then echo "Won't happen"; fi
	echo "Passed"

will echo `Passed`.

If a command however returns a nonzero status inside a pipe, say `cat /prc/cpuinfo | grep 'model name' | wc -l` (`/prc` does not exist), the pipe itself only fails if the last command returns a non-zero (here, `wc` exits with `0`).

> `-o pipefail` will cause the pipe to fail if any one of its components returns a non-zero status.

The following will fail if sshd is not in fact running

	sshdline=$(netstat -tlpn | grep sshd)

	echo "SSHD is running : $sshdline"

If you want to display an alternative message, use `|| :` at the end of a pipe or assignment to catch the non-zero return code (`:` is a function that does nothing but return `0`, essentially like `true`, useful here for semantic clarity).

	sshdline=$(netstat -tlpn | grep sshd) || :

	if [[ -n "$sshdline" ]]; then
		echo "SSHD is running : $sshdline"
	else
		echo "$SSHD was not found"	
	fi


> `-u` will cause an error condition on attempting to dereference a variable that has not been set.

This avoids disasters like

	rm -r "$aphome/bin"
	  # A typo in '$apphome' !!

from wiping the wrong directory! (see the Steam bash bug for a real-life horror story)

> With these in mind, let us proceed to the rest of the recommendations.

## Functions

Declaring a function is as simple as

	myfunction() {
		# for bash and sh
	}

or

	function myfunction {
		# bash only
	}

Remember the rule of thumb: no function should have more than around 15-20 lines of operational code (not counting variable declarations and other "setup" and "teardown" code).

### Do not use naked code

A program should have one, and only one, entry point: its `main` function. Trying to hunt down execution flow problems when you're not sure where to start is tedious.

As a scripting language, bash permits writing code without wrapping it in a function. Most of the time, this is alright, but when writing code for re-use, it is nearly always best to encapsulate it in a function. You never know when you're going to import that code and expect it *NOT* to run until you ask it to run.

As such, wrap all your code inside functions, and have only a single bare call to the main function (call it whatever you want) - for example

	my:main() {
		echo "Arguments were:"
		for arg in "$@"; do
			echo "  $arg"
		done
	}

	my:main "$@"

### Namespace your functions

> `bash` only. In `sh`, use `_` (underscore)

A little known fact of bash is that `:` and `.` are all perfectly valid characters to have in a function name, so you should use them to namespace your functions, especially when writing libraries that will be imported (for example, with [bash-builder](https://github.com/taikedz/bash-builder)).

	bb:echo() {
		echo "$*" >&2
	}

	bb:info() {
		bb:echoe "${CRED}$*${CDEF}"
	}

	bb:info "Saying hello !"

### Use wrapper functions to improve clarity

Some bash syntax is more quizzical, so consider wrapping such occurrences.

	qz:get_pids() {
		local targetname="$1"; shift
		ps aux | grep -P "\b$targetname\b"| grep -v grep | awk '{print $2}' | xargs echo
	}

	# Now we can simply see that we are looking for the PIDs of a process:
	
	qz:get_pids chromium

### Don't use back-ticks, use `$()` instead

You cannot nest back-ticked subshells, and back-ticks make recognizing starts and ends difficult; use the nestable form instead.

	qz:find_processes_for() {
		local target="$1"; shift
		local target_ids="$(qz:get_pids "$(which "$target")" )"

		echo "The PIDs are $target_ids"
	}

	qz:find_processes_for apache2

### Use the `[[` test tool

In `sh`, the more commonly used test command is `[` - which is in fact an executable file (try running `which [` !). It is useful, but has its limitations.

In `bash`, a more powerful construct is `[[` which is not an executable but an actual syntax feature of the bash language.

For example, `/bin/[` only has support for some basic matching operations. The following are available to `[[`:

	text=hey

	if [[ "$text" == ?e? ]]; then echo "[$text] is the letter 'e' with a character on either side"; fi

	if [[ "$text" =~ e ]]; then echo "[$text] contains the letter 'e'"; fi

	if [[ "$text" =~ (.)e ]]; then echo "The first instance of 'e' in [$text] is '${BASH_REMATCH[1]}'"; fi

Note the final example, where we use a [regular expression](https://www.regular-epxressions.info) with capturing groups. Since `[[` is a language construct in its own right, we do not need to worry about `(.)e` running a subshell - the context indicates that it is a pattern. The `${BASH_REMATCH[@]}` array can be used to access captured groups.

## Variables

Always use quotes around variables to catch unexpected whitespace or prevent path glob expansion. Always. Except when you necessarily should not - like in bash regex comparisons (see the `$numpat` example below).

### Use local variables

Rather than litter your namespace with global assignments unnecessarily, as is the default in bash, use local variables inside functions.

	nums:is_number() {
		local tocheck="$1"; shift
		local numpat="^[0-9]+$"

		# Do not quote "$numpat", otherwise it loses its regex matching behaviour
		[[ "$tochek" =~ $numpat ]]
	}

### Use named arguments

Avoid referencing arguments by number - store them in named local variables. You never know when you might start inserting new positional arguments, and it makes for a more readable logic.

Note that you can dereference a variable plainly `$variable` or by explicitly encapsulating it `${variable}`

	rels:describe_academic_relationship() {
		local teacher="$1"; shift
		local student="$1"; shift

		echo "${teacher} teaches ${student}"
	}

	rels:describe_academic_relationship "Alice" "Bob"

### Namespace your global variables

Use an uppercase namespace on global variables your script or library may set, to avoid name clashes with other elements of the script.

Use safe dereference notation `${VARNAME:-}` to access variables that might not yet have been assigned (when not assigned, expands to an empty string).

	myapp:parse_args() {
		if [[ "$*" =~ --help ]]; then
			MYAPP_help=true
		fi
	}

	myapp:main() {
		myapp:parse_args "$@"

		if [[ "${MYAPP_help:-}" = true ]]; then
			echo "Help !!"
		fi
			
	}

	myapp:main "$@"

## Use arrays

Pass items down to functions using arrays; pass them back using global variables. This is probably the kludgiest of common things one would want to do in general programming which bash has currently no mechanism for.

The token used for main arguments of the script `$@` is also used as the main arguments of a function. A copy is passed to the called function, which can manipulate its copy without affecting the caller's copy.

When dereferencing an array, always quote it, as leaving it naked makes its contents subject to splitting along whitespace.

	echo "There are $# arguments:"

	for x in "$@"; do
		echo "$x"
	done

Assigning and using an array is as simple as

	myarray=(one "and two" three four five)

	echo ${myarray[1]} # ---> "and two"
	echo ${myarray[2]} # ---> "three"

We reference the array in general as `${myarray[@]}`, and use extra tokens to splice and count.

	echo "${myarray[@]:2}" # ---> "three four five"
	echo "${myarray[@]:2:2}" # ---> "three four"

	echo "There are ${#myarray[@]} items in the array"

Copying an array is a little more involved

	RESULT_ARRAY=("${myarray[@]}")

* `"${myarray[@]}"`
* The parentheses `()` declare the content as an array

Functions can only output string data - as such, returning any arrays whose members contain whitespace is not possible, and instead, using a global variable is the only way available.

### Use pointer variables

The `declare -n` keyword allows creating variables that act as pointers to other variables. In this way, a secondary function can assign values to a variable in a higher-up function.

    outer() {
        local myvar=(a b c)

        change_array myvar

        for x in "${myvar[@]}"; do
            echo "$x"
        done
        # prints "one", "two" and "three" on their respective lines
        # due to the change by change_array
    }

    change_array() {
        declare -n inner="$1" # inner becomes a pointer to the name specified as argument

        # We can now affect the varaible from further up the stack.

        inner=(one two three)
    }

## Separate into files

Like with most programming languages, it is best to keep your code conceptually organized into multiple files for easier management and source control.

If you know where files will be, you can source them directly

	. "$HOME/.local/lib/myapp/file1.sh"

Otherwise, use [bash builder](https://github.com/taikedz/bash-builder) to aggregate your separate files into single executables !

## Additional resources

* [Common bash gotchas](http://mywiki.wooledge.org/BashPitfalls)
* [Gogole's Shell Style Guide](https://google.github.io/styleguide/shell.xml)
