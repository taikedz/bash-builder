# TarSH

A script suite for combining assets into a tar file, and header data for the tar file to self-run

## Requirements

You can run `tarshc` to specify all items to be included in the self-extracting archive.

You must include a `bin/` directory, and there must be a `bin/main.sh` script as a main entry point to the application

## Runtime

The compiled archive (Tar Script) has some header script lines which allow it to self-unpack and run.

By default it unpacks to the current directory ; by setting the `TSH_D` environment variable, it can be made to unpack to any other location.

Any time the Tar Script is run, it first checks to see if a corresponding unpacked directory already exists. If it does, then it directly runs the already unpacked instance. This is always true, except when the unpack directory is `/tmp` in which case, the script always unpacks again.

The Tar Script can be forcibly re-extracted by running it with the single argument `:unpack` , e.g.

    my-app.tgz.sh :unpack

# Example

The following is an example of

* creating a script
* getting an asset file
* running in the current working directory

Script:


    mkdir my-demo ; cd my-demo

    mkdir bin
    mkdir assets

    # Create some asset
    echo "Hello there" > assets/other.txt

    # Create main script, and use the asset
    cat <<'EOF' > bin/main.sh
    echo "Running from $TARWD"
    echo "Running in $PWD"
    echo "Path includes $PATH"
    echo

    echo "--- Internal asset ---"
    cat "$TARWD/assets/other.txt"
    echo

    echo "--- Local listing ---"
    ls
    echo
    EOF



    # Build the runnable tar - it will be named after the containing directory (here, `my-demo`)
    tarshc bin/ assets/

    ./my-demo.tgz.sh



