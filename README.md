# Bash Builder

(C) 2017 Tai Kedzierski, provided under GNU General Public License v3.0.

A toolset for managing bash snippets/libraries, and managing in-line documentation.

For more on writing cleaner bash scripts, see the [clean writing notes](writing_clean_bash.md).

## What is this?

Bash Builder is a tool to help writing bash scripts as multiple files, but compiling and distributing as a single file. Note that this is specifically for GNU bash - strict POSIX `sh` usage is not supported.

Bash, as a language, lacks a usable mechanism to allow developing separate, loosely-related components in separate files, and building libraries of such files for re-use.

The Bash Builder project aims to provide such a structure:

* combiner for assembling bash scripts using `#%include` statements
* customizable search paths for inclusion of files
* a default library of useful functions to make developing in bash clearer and cleaner

## Installing

Clone this repository, run the installation file.

	git clone https://github.com/taikedz/bash-builder
	cd bash-builder

	# Verify only (no install)
	./install.sh --verify

	# Actually perform installation
	./install.sh

	# or,
	#   sudo ./install.sh

Then open a new shell, or re-load your `~/.bashrc` file.

You can now issue the `bbuild` command to build your scripts. See the `demo` folder for an example.

If you installed as root, the commands are installed to `/usr/local/bin`, otherwise they are installed to `~/.local/bin`, and you may need to add that directory to your `$PATH`

## Examples

Two primary examples are the [`bbuild`](src/bbuild) and [`bashdoc`](src/bashdoc) programs themselves written to be compiled by bash builder.

You can see an additional example project in [examples/ssh-connection-manager](examples/ssh-connection-manager)

After installing bash-builder, you can `cd` to that directory and run `bbuild` to build the project.

	cd examples/ssh-connection-manager
	bbuild
	bin/connect --help

## Features

### `bbuild`

The main compiler script that processes the scripts, each into a single executable file.

	bbuild FILES ...

Each file will be processed for `#%include` directives, and each file specified will produce its own standalone script.

Use the `#%include` directive in your scripts to import snippets from the builder path `$BBPATH`, or specify a file to import:

	# Include some handy message printing functions
	#%include out.sh

	# Include a file on a path in the same directory as the specified script
	#%include src/morescript.sh

The output will be placed in a `bbuild-outd` directory (or, whatever directory is specified by `$BUILDOUTD`).

If you have `shellcheck` installed, you can also have it run against the compiled script.

See `bbuild --help` for more information.

### `bashdoc`

Processor for a simple, general documentation format that allows you to insert documentation comments in your files, and extract them; documentation comments should be in [Markdown](https://daringfireball.net/projects/markdown/) - this allows them to simply be printed on-screen, or to file for further transformation into web pages.

The documentation processor is very basic, but has the advantage of being extremely simple and would work on any file that uses a single `#` to denote comments - it doesn't really care so long as it finds documenmtation comments - the following produces a documentation section named TITLE, and a description. The "###" and "Usage:" tokens are necessary, and the "###/doc" terminates the doc comment.

	### TITLE Usage:help
	# some description
	###/doc

By default, `bashdoc` will try to find and print any documentation comment tagged as "Usage:bbuild"

Without specifying any arguments, returns all modules along the BBPATH inclusino paths. Example usage:

	bashdoc out.sh

This prints the documentation for the `out.sh` script.

### Default library

The default library is hosted in a separate repository at https://github.com/taikedz/bash-libs ; it is cloned locally during install.

If you installed as root, the default library from `bash-libs/libs/` is installed to `/usr/local/lib/bbuild`, otherwise they are installed to `~/.local/lib/bbuild`

You can configure `$BBPATH` in your `.bashrc` file to point to a series of custom locations for scripts, each path is separated by a colon `:`. By default, BBPATH is automatically set to `~/.local/lib/bbuild:/usr/local/lib/bbuild`.

A typical use case would be to add your library directory from the current working directory:

	export BBPATH=./mylibs:$HOME/.local/lib/bbuild:/usr/local/lib/bbuild

You can do this in your `.bashrc` file, or in the current working directory as `./bbuild_env`

In this case, scripts from the current directory's `mylibs/` are loaded preferably, then the user's general library folder, and finally the main library folder is checked.

### Tagging

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

### Autohelp

Autohelp is one of the libraries in `bash-libs/libs` that is probably worth highlighting:

Autohelp allows you to use documentation comments to produce help.

	### TITLE Usage:help
	# This is a help section. When using autohelp,
	# this text will be printed any time "--help"
	# is detected in the arguments!
	###/doc

	#%include autohelp.sh

When your script subsequently is run with the `--help` option, autohelp will *always* kick in, printing the help contents, and exiting.

You can also call the help print routine from within your script using the `autohelp:print` command (does not cause the script to exit).

