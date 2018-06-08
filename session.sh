#!/bin/bash

# Execute periodic stuff inside a user session.

# Normally you would use cron, but this script
# is intended to only execute stuff as long as
# the user session is alive. It inhirits the
# session logon keys so ext4 encryption does not
# get in the way (a nasty problem with cron).

# The commands to execute are stored in a tab
# seperated values file (tsv) called session.tsv
# Format:
# <period> <tab> <commandline>
# For the <period> format, see man sleep

# If you edit the file while session.sh is running,
# you have to killall session.sh and start the
# session.sh& again, e.g. by logging in again.

# Activate using your ~/profile by including:
# /PATH/TO/session.sh &

# DO NOT FORGET the ampersand so it starts in
# the background, otherwise your login manager
# such as LightDM will hang because it waits
# on the script to finish.

# The process tree in which session.sh is active on my system :-)
# root  \_ lightdm --session-child 12 19
# evert     \_ /bin/sh /etc/xdg/xfce4/xinitrc -- /etc/X11/xinit/xserverrc
# evert         \_ /bin/bash /home/evert/session.sh
# evert         |   \_ /bin/bash /home/evert/session.sh
# evert         |   |   \_ /bin/sh /SOME/NICE/SCRIPT
# evert         |   \_ sleep infinity
# evert         \_ xfce4-session

SESSIONTAB="session.tsv"

# Evert Mouw, 2018-06-08

function LOG {
	echo "$(date) $1" >> "$0.log"
}

# check already started
RUNNING_NMBR=$(pgrep -c $(basename $0))
if [[ $RUNNING_NMBR -gt 1 ]]
then
	LOG "$0 already active"
	exit
else
	LOG "$0 starting with pid $$"
fi

function subshell {
	# for use by periodic
	LOG "  Starting subshell $BASHPID for $1 $2"
	while true
	do
		eval "$2"
		sleep $1
	done
}

function periodic {
	# arg 1: time interval (see man sleep)
	# arg 2: command to evaluate (execute)
	subshell $1 "$2" &
	PID=$!
	PIDLIST="$PID $PIDLIST"
}

if ! [[ -f $SESSIONTAB ]]
then
	LOG "$SESSIONTAB not found!"
	exit 1
fi

while read LINE
do
	PERIODE=$(echo "$LINE" | cut -f1)
	CMDLINE=$(echo "$LINE" | cut -f2)
	periodic $PERIODE "$CMDLINE"
done < $SESSIONTAB

function killsubs {
	LOG "Killing subshells and exiting."
	# kill all subshells created using periodic/subshell
	for P in $PIDLIST
	do
		kill $P >/dev/null 2>&1
	done
	# inspired by zuazo (2016)
	# https://unix.stackexchange.com/questions/313644/execute-command-or-function-when-sigint-or-sigterm-is-send-to-the-parent-script
	trap - SIGINT SIGTERM # clear the trap
	kill -- -$$ # Sends SIGTERM to child/sub processes
}

trap killsubs SIGINT SIGTERM

sleep infinity
