#!/bin/bash
# The post-install script inside the Sangala Studio installer package. It is tracked here so it can
# be reviewed and revised as a diff; the package itself is built on a Mac and is not in this
# repository. Copy this file into the folder given to `pkgbuild --scripts`, under the exact name
# "postinstall": that name is what makes Installer run it, once, after the app has been copied into
# Applications.
#
# ITS ONE JOB IS THE DESKTOP ICON, so a student can start the program straight after installing it -
# the Mac counterpart of "Create Desktop Shortcut.cmd" on Windows. The launcher inside the app
# (app-launcher.sh) makes the same icon at any launch that finds it missing, so an install where
# this script makes nothing still ends with an icon once the app has been opened from Applications.
#
# Installer runs this as root, whose home folder is not the student's, so $HOME and ~ would put the
# icon in the wrong place. Instead it asks macOS who is logged in at the screen and writes to that
# person's Desktop. If nobody is (a remote or managed install), it does nothing.
#
# The icon is a symbolic link rather than a Finder alias: a link needs no scripting of Finder from
# inside Installer, and double-clicking it opens the app.
#
# It always exits 0. Installer reports the whole installation as failed when a post-install script
# exits with an error, and a missing Desktop icon is not worth that.

APP="/Applications/Sangala Studio.app"

USER_NAME="$(/usr/bin/stat -f %Su /dev/console 2>/dev/null)"
case "$USER_NAME" in
  ""|root|loginwindow|_mbsetupuser) exit 0 ;;
esac

# dscl prints the home folder after "NFSHomeDirectory:" on the same line, or on the next line when
# the path holds a space; this reads either, and keeps a path with spaces whole.
USER_HOME="$(/usr/bin/dscl . -read "/Users/$USER_NAME" NFSHomeDirectory 2>/dev/null \
  | /usr/bin/sed -e 's/^NFSHomeDirectory://' -e 's/^ *//' | /usr/bin/grep -v '^$' | /usr/bin/head -n 1)"
DESKTOP="$USER_HOME/Desktop"
LINK="$DESKTOP/Sangala Studio"

[ -d "$APP" ] || exit 0
[ -n "$USER_HOME" ] && [ -d "$DESKTOP" ] || exit 0

# An earlier link may point at an old copy of the app, so replace it. Anything else with this name -
# a Finder alias the launcher made, or a file of the student's own - is left alone.
[ -L "$LINK" ] && /bin/rm -f "$LINK"
if [ ! -e "$LINK" ]; then
  /bin/ln -s "$APP" "$LINK" && /usr/sbin/chown -h "$USER_NAME" "$LINK"
fi

exit 0
