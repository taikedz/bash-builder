# Writing Cleaner bash (with Bash Builder)

You may first want to check out [the general bash scripting tips](writing_clean_bash.md) before this guide.

The following are notes on what makes Bash Builder a great tool to augment your bash scripting with. It's not so much a guide as a demonstration of what you can gain !

## Lengthy code and boilerplate

In the previous guide, I outlined the need to use safe mode, functions, and local named variables. That trifecta of recommenations leads to situations with heavy boilerplate in every function, like so:

    #!/usr/bin/env bash

    set -eu

    die() {
        local code="${1:-}"
        if [[ "$code" =~ ^[0-9]+$ ]]; then
            shift
        else
            code=100
        fi

        echo "$*" >&2
        exit $code
    }

    gitdemo:clone-or-update() {
        local giturl="${1:-}"; shift || die 1 "URL not specified"
        local destination="${1:-}"; shift || die 2 "Destination not specified"

        if [[ -e "$destination" ]]; then
            ( cd "$destination" ; git pull ) || die "Update failed"
        else
            git clone "$giturl" "$destination" || die "Clone failed"
        fi
    }

    gitdemo:clone-or-update "$@"

The above is a full (if naive) script to either clone a repo, or update it if it already exists locally.

Some items to note:

1. The `die` function implemented at the top of the script
    * It is actually rather fancy, checking for an exit code to use
2. The  couple of lines at the top of the `clone-or-update` function to get the function arguments into named variables
    * along with warning code for when they are not specified
3. The safe mode is incomplete - it is missing pipefail, glob and inline whitespace splitting guards

This also would be the start of a shorthands utility ([hint hint](https://github.com/taikedz/git-shortcuts)) that is likely to grow over time - to a file of tremendous size.

Bash Builder aims to help a little in this respect.

* Firtstly, the `die` function might be re-used time and time again in other scripts, clever as it is. Why not put it somewhere useful, and import it every time it is needed?
    * Bash Builder provides such a mechanism, with re-usable files provided as "librarires".
    * It also provides a `out:fail` command that does just that (more elegantly named than 'die', so barbaric...)
* Secondly, when the script does grow in size, it would be useful to split various parts of it into separate files, to help keep the code organized.
    * Bash Builder allows importing local files in the same way as library files
* Thirdly, that function boilerplate is tedious to maintain...! Why does bash not support named arguments in functions ?
    * Bash Builder provides a syntax post-compilation processor for this.

The following is the equivalent script, written with the assistance of Bash Builder, along with a help section:

    #!/usr/bin/env bash

    #%include std/safe.sh
    #%include std/out.sh

    $%function gitdemo:clone-or-update(giturl destination) {
        if [[ -e "$destination" ]]; then
            ( cd "$destination" ; git pull ) || out:fail "Update failed"
        else
            git clone "$giturl" "$destination" || out:fail "Clone failed"
        fi
    }

    gitdemo:clone-or-update "$@"

Notice now:

1. Using `safe.sh` ensures the full standard safety net is applied.
2. `out.sh` supplies some output control utilities, of which the `out:fail` function - which also optionally takes a status code as first argument
3. The `$%function` marker enables use of the syntax extension allowing named arguments in function declarations
4. ... and the code is significantly shorter now !

## Debugging with introspection

Let's focus on that main function. We can make the destination folder optional, and derive a folder if not specified. For argument's sake, we'll also look at how to debug values:

    #%include std/debug.sh

    debug:mode output

    $%function gitdemo:clone-or-update(giturl ?destination) {
        if [[ -z "$destination" ]]; then
            destination="$(basename "$giturl")"
        fi

        debug:break "Pre-update"

        if [[ -e "$destination" ]]; then
            ( cd "$destination" ; git pull ) || out:fail "Update failed"
        else
            git clone "$giturl" "$destination" || out:fail "Clone failed"
        fi
    }

Notice the `debug:mode output` line - this switches on debugging from that point onward, until `debug:mode /output` is reached (not used here, so never reached).

In debug mode, `debug:*` commands will activate. Here I've used a breakpoint command which stops the script and gives us a rudimentary prompt. Using this prompt, I can

* inspect variables - type `$destination` to see its value
* change variables - type `$destination=newvalue` to set a new value (this will affect the behaviour of the script accordingly !)
* See the environment as the script sees it (type `env`)
* abort (`^C`) or continue (just hit return)

If for whatever reason you are seeing odd behaviour in your script, the `debug:break` tool should help flush out any issues!
