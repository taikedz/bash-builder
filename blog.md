# Bash Builder 5.3 - Syntax Sugars

I've finally gotten round to implementing a feature I've been somewhat pining for a while now... some rudimentary syntactic shortcuts to reduce the verbosity of setting up arguments for functions.

Specifically, if following the guidelines of good scripting, you will know that you should always have the unofficial strict mode on, and always name your variables. To comply with this, the bash script developer must add quite a bit of boiler plate to the top of their functions.

For example:

```sh
set -euo pipefail

copyfrom(host user dest) {
    local host="${1:-}"; shift || out:fail "Host not specified !"
    local user="${1:-}"; shift || out:fail "User not specified !"
    local dest="${1:-}"; shift || out:fail "Dest dir not specified !"
    local srcdir

    for srcdir in "$@"; do
        scp "$user@$host:$srcdir" "$dest"
    done
}
```

What is in fact a function with just a couple of key parts becomes visibily longer due to having to perform variable name setup. Maintenance is made more tedious owing to the numerous lines that "can" be ignored whilst reading.

The following is a feature-wise equivalent of the previous script:

```sh
set -euo pipefail

$%function copyfrom(host user dest) {
    local srcdir

    for srcdir in "$@"; do
        scp "$user@$host:$srcdir" "$dest"
    done
}
```

Clarity is improved, sanity is restored.

## Naming Doughnuts

The following used to reside at the top of the file whilst writing the initial notes for the second implementation

```
# Proposal:
# "$" should be pronounced "dough" as in slang for money
# "%" should be pronounced as "nuts" as in nuts and bolts.
# Bringing these together in "$%" notation, we get "dough nuts".
# Bash Doughnuts Notation.
```
