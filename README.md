# session.sh

*Execute periodic stuff inside a user session.*

Normally you would use cron, but this script is intended to only execute stuff as long as the user session is alive. It inhirits the session logon keys so ext4 encryption does not get in the way (a nasty problem with cron).

The commands to execute are stored in a tab seperated values file (tsv) called `session.tsv`. Format:

	<period> <tab> <commandline>

For the <period> format, see man sleep

If you edit the file while `session.sh` is running, you have to `killall session.sh` and start the `session.sh&` again, e.g. by logging in again.

Activate using your `~/profile` by including:

	/PATH/TO/session.sh &

DO NOT FORGET the ampersand so it starts in the background, otherwise your login manager such as LightDM will hang because it waits on the script to finish.

The process tree in which session.sh is active on my system :-)

	root  \_ lightdm --session-child 12 19
	evert     \_ /bin/sh /etc/xdg/xfce4/xinitrc -- /etc/X11/xinit/xserverrc
	evert         \_ /bin/bash /home/evert/session.sh
	evert         |   \_ /bin/bash /home/evert/session.sh
	evert         |   |   \_ /bin/sh /SOME/NICE/SCRIPT
	evert         |   \_ sleep infinity
	evert         \_ xfce4-session

*Evert Mouw, 2018-06-08*
