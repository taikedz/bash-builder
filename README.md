# Bash Builder

(C) 2017-2019 Tai Kedzierski, provided under GNU General Public License v3.0.

A toolset for managing bash snippets/libraries, managing in-line documentation, and bundling assets into single executables.

For more on writing cleaner bash scripts, see the [clean writing notes](docs/writing_clean_bash.md).

## What is this?

Bash Builder is a tool to help writing bash scripts as multiple files, but collating and distributing as a single file.

Bash, as a language, lacks a usable mechanism to allow developing separate, loosely-related components in separate files, and building libraries of such files for re-use from searchable library paths.

The Bash Builder project aims to provide such a structure:

* collater for assembling bash scripts using `#%include` statements
* customizable search paths for inclusion of files
* a default library of useful functions to make developing in bash clearer and cleaner
* a utility to collect and bundle assets and external scripts into a single executable
* added syntax sugars (e.g. variable names in function signatures)
* utility to execute bash-builder-augmented scripts

Note that the tools are specifically written against GNU bash and GNU coreutils - strict POSIX `sh` usage is not supported; run the compatibility check using `bash src/compatibility.sh` to check that all tools on the system match the required versions.

## Installing

Clone this repository, run the installation file.

	git clone https://github.com/taikedz/bash-builder
	cd bash-builder

    # Optionally, run a compatibility check before installing
	bash src/compatibility.sh
    
    ./install.sh [ --libs ]
	# or,
	#   sudo ./install.sh [ --libs ]

Then open a new shell, or re-load your `~/.bashrc` file.

You can now issue the `bbuild` command to build your scripts. See the `demo` folder for an example.

If you installed as root, the commands are installed to `/usr/local/bin`, otherwise they are installed to `~/.local/bin`, and you may need to add that directory to your `$PATH`

## Features

### `bbuild`

The main collater script that processes the scripts, each into a single executable file.

	bbuild SOURCEFILE [DESTFILE]

The source file will be processed for `#%include` directives, and produce an output file in `build-outd/` by default, or in the destination file if specified.

Use the `#%include` directive in your scripts to import snippets from the builder path `$BBPATH`, or specify a file to import:

Assuming a folder structure like

    ./
      |
      |_ main.sh
      |
      |_ morescript.sh

You can write this in `main.sh`:

	# Include some handy message printing functions
    #  installed on $BBPATH

	#%include std/out.sh

	# Include a file on a path in the same directory as the specified script
	#%include morescript.sh

    # ... (rest of your script here ) ...

You can run

    bbuild main.sh bin/myscript.sh

to build your script to the bin/ directory as a `myscript.sh` executable.

If you have `shellcheck` installed, you can also have it run against the compiled script.

See `bbuild --help` for more information.

#### Extra Syntax !

A syntactic post-processor seeks and replaces macro strings starting with `$%`. Specify `BBSYNTAX=off` in your environment to disable this syntax post-processing.

**Function signatures**

You can declare functions using variable names in the function signature:

```sh
$%function copyfrom(host user dest) {
    for srcdir in "$@"; do
        scp "$user@$host:$srcdir" "$dest"
    done
}

# The first three arguments are assigned to the names ; the rest remain available in "$@"
copyfrom server.example.com myusername ./downloads /etc/hosts /home/user/backup.log
```

If fewer arguments than the number named are provided at runtime, the script/subshell will exit, detailing which variable could not be assigned.

**Events**

You can declare "events" (signal traps) using a shorthand notation like so:

```sh

# Plain interrupt catchers

$%on SIGINT SIGTERM int-or-term() {
    echo "Got SIGINT or SIGTERM"
}

# Declare a trap within an event

do_stuff() {
    touch tmp1 tmp2

    $%on EXIT regular_exit() {
        # Cleanup
        rm tmp1 tmp2
    }
}
```

which will add a trap on the declared signals.

Note that trap/event functions do not take arguments.

### `bbrun`

An executable that allows you to directly run scripts written for bash builder without a compilation step.

`bbrun` compiles the script and runs it immediately, and is suitable for a shebang line. The actual runtime script is written to `/tmp/`, so bbrun provides a `$BBRUN_SCRIPT` variable to determine the original location of the script.

For example, the following script file can be made executable and run directly:

```bash
#!/usr/bin/env bbrun

#%include std/out.sh

main() {
    out:info "You ran '$BBRUN_SCRIPT' (compiled to '$0')"
}

main "$@"
```

Limitations:

* This relies on the host having `bash-libs` installed and accessible to the user.
* Cannot be used on scripts written to rely on the location of `$0` (the running script itself)
    * use the `$BBRUN_SCRIPT` variable instead, or the `std/this.sh` lib (version from 2.1.6 onwards)

### `bashdoc`

Processor for a simple, general documentation format that allows you to insert documentation comments in your files, and extract them; documentation comments should be in [Markdown](https://daringfireball.net/projects/markdown/) - this allows them to simply be printed on-screen, or to file for further transformation into web pages.

The documentation processor is very basic, but has the advantage of being extremely simple and would work on any file that uses a single `#` to denote comments - it doesn't really care so long as it finds documenmtation comments - the following produces a documentation section named TITLE, and a description. The `###` and `Usage:` tokens are necessary, and the `###/doc` terminates the doc comment.

	### TITLE Usage:help
	# some description
	###/doc

By default, `bashdoc` will try to find and print any documentation comment tagged as "Usage:bbuild"

Without specifying any arguments, returns all modules along the BBPATH inclusino paths. Example usage:

	bashdoc std/out.sh

This prints the documentation for the first `std/out.sh` script found on the `$BBPATH` path.

### Message flags ("tagging")

You can add tag directives to your files using the #%bbtags directive to cause messages to appear when files are included during build. Tags are processed in order of declaration, and use a prefix to determine the message type.

There are 3 tag prefixes:

	"i:" -- this causes an info message to be printed
	"w:" -- this causes a warning message to be printed
	"e:" -- this causes an error message to be printed, and exits the build with failure

Tags without any of these prefixes are only printed when --debug is specified in the arguments.

The following would cause two warning messages to appear during build:

	#%bbtags w:deprecated w:use_other

The following would cause a warning message to appear during build, then a failure message and exit.

	#%bbtags w:deprecated e:too_dangerous

## Default library

The default library is hosted in a separate repository at [https://github.com/taikedz/bash-libs](https://github.com/taikedz/bash-libs) ; you will be offered a choice to add it during the installation process.

You can configure `$BBPATH` in your `.bashrc` file to point to a series of custom locations for scripts, each path is separated by a colon `:`. By default, `BBPATH` is automatically set to `~/.local/lib/bash-builder:/usr/local/lib/bash-builder`.

A typical use case would be to add your library directory from the current working directory:

	export BBPATH="./my-extra-libs:$HOME/.local/lib/bash-builder:/usr/local/lib/bash-builder"

In this case, scripts from the current directory's `my-extra-libs/` are loaded preferably, then the user's general library folder, and finally the main library folder is checked.

### Autohelp

Autohelp is one of the libraries in `bash-libs/libs` that is probably worth highlighting:

Autohelp allows you to use documentation comments to produce help.

	### TITLE Usage:help
	# This is a help section. When using autohelp,
	# this text will be printed any time "--help"
	# is detected in the arguments!
	###/doc

	#%include autohelp.sh

	autohelp:check "$@" # Detect --help string; if found, print help, and exit

When your script subsequently is run with the `--help` option, autohelp will *always* kick in, printing the help contents, and exiting.

You can also call the help print routine from within your script using the `autohelp:print` command (does not cause the script to exit).

See `bashdoc std/autohelp/sh` for more info.

### Debugging Tools

`debug.sh` is part of the standard libararies, allowing you to print debug-level messages when the debug mode flag is set, as well as providing the ability to view and change variables of a running script using the `debug:break` function.

See `bashdoc std/debug.sh` for more info

### TarSH - Self Extracting and Running TAR files

A utility for collecting various assets into a single self-extracting and running tar file.

Using this, full collections of scripts and binary assets can be deployed in a single runnable file.

See [the `tarsh` documentation](docs/tarsh.md) and the [myip](examples/myip) example.

## Examples

Since Bash Builder is itself written in bash, you could study the tool itself for insight into how it is used.

The primary examples are the [`bbuild`](src/bbuild), [`bbrun`](src/bbrun), and [`bashdoc`](src/bashdoc) programs themselves written to be compiled by bash builder !

You can see an additional example project in [examples/ssh-connection-manager](examples/ssh-connection-manager)

After installing bash-builder and re-sourcing your `.bashrc`, you can `cd` to that directory and run `bbuild` to build the project.

	cd examples/ssh-connection-manager
	./build.sh
	bin/connect --help

You can also see a simple example of the use of multiple scripting languages combined into one through TarSH in the [examples/myip](examples/myip) folder

	cd examples/myip
	./build.sh
	./myip.tgz.sh

