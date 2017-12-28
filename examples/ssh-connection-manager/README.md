# Bash BUilder Example Project : Connection Manager

This tool uses bash builder libraries and file separation to build a SSH connection manger.

It is very simple, and a little incomplete, but does the essential.

See the annotated code in `src/`

The `bbuild_env` is set up to automatically know what files to build -- so you only need to run

	bbuild

to see the results in the `bin/` directory.

The `bbversion/` data is automatically generated and the build number incremented with each build.

