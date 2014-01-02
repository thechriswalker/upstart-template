#!/bin/bash
set -e
# This is an OSX hack, requiring you have gnuutils installed, with or without a prefix
# if not the script will fail.
READLINK=$(which greadlink)
test -x "$READLINK" || READLINK=$(which readlink)

BINARY="$($READLINK -f "$1")"
## get fll path...
test -x $BINARY || { echo "Binary file not present, or not executable!" >&2; exit 1; }

APP_NAME="$(basename $BINARY)"

function prompt() { # VAR prompt default
  local temp
  read -e -p "$2 [$3] " temp
  if [ "$temp" == "" ];
  then
    temp="$3";
  fi
  eval $1="$temp"
}

prompt WORKING_DIR "App Working Directory?" "$(pwd)"
prompt USER "Run as user?" "$(whoami)"
prompt LOG "Log output to?" "/var/log/${APP_NAME}.log"
prompt DESCRIPTION "App Description" "${APP_NAME}"

cat << EOF
description     "App"
author          "Chris Walker <github@thechriswalker.net>"

start on filesystem or runlevel [2345]
stop on runlevel [!2345]

kill signal INT

respawn
respawn limit 10 5
umask 022

console none

USER=$USER
WORKING_DIR="$WORKING_DIR"
BINARY="$BINARY"
OUTPUT="$LOG"

pre-start script
    test -x \$BINARY || { stop; exit 0; }
    test -e \$WORKING_DIR || { stop; exit 0; }
    test -e \$OUTPUT || { touch \$OUTPUT && chown \$USER:\$USER \$OUTPUT }
end script

# Start
chdir \$WORKING_DIR
exec sudo -u \$USER \$BINARY 2>&1 >>\$OUTPUT
EOF
