#!/bin/bash

#%include askuser.sh out.sh autohelp.sh

### CronDo Usage:help
#
# Run cron job line now, rather than waiting.
#
# Only line commands that start with ":;" will be offered by CronDo
#
# For example, if you have the following in your crontab:
#
# 	* * * * * echo Hello
# 	* * * * * :; echo Goodbye
#
# You will only be offered the option of running the second command.
#
# Add `:;` to the start of any line which you want to access via `crondo`
#
# (`:` is a command that does nothing; normally used as a placeholder - check that this is the case on your system (that is has not been overridden by a command or alias: issuing the command `type :` should return `: is a shell builtin` ))
#
###/doc

cronchoices="$(crontab -l | grep -P '^\S+ \S+ \S+ \S+ \S+ :;'|sed -r -e 's/^.+?:;//' -e 's/$/ , /' |sed -r -e 's/^ , //')"
MYCMD=$(askuser:choose "Choose a single cron command to run" $cronchoices )

if [[ -z "$MYCMD" ]]; then
	out:fail "Nothing to do."
fi

bash -c "$MYCMD"
