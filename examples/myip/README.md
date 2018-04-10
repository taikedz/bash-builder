# My IP

Find the IP address for the default route.

If you have multiple network interfaces, this script uses the `ip route` table to determine the first default path, extracts the `ip a` section, and reads the IP (v4) for that interface.

## Example Project

This is a small example project demonstrating the use of the TarSH component of Bash Builder

To run it:

	./build.sh

	./myip.tgz.sh

The `build.sh` script builds the bash asset in `src/` into `bin`, then runs `tarshc` to bundle it.

This produces a directly runnable bundle.

## Options

Friendly message with your IP:

	./myip.tgz.sh

Batch mode: just the IP, for programmatic use

	./myip.tgz.sh -b
