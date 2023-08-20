#!/bin/bash

. /root/src/ihs/.env

NAME="$1"
BACKUPDIR="/var/lib/docker/volumes/ihs_backup/_data"

AUTH="Authorization: basic `echo -n "root:${ZOPE_ROOT_PASSWORD}" | base64`"
URL="http://localhost:8080/Select/install/export_py?kurztext=${NAME}"
FILE=$BACKUPDIR/$NAME`date +"_%F_%T"`.zexp

echo "Storing ZODB backup of /IHS-${NAME} in ${FILE}..."
wget --quiet -O $FILE --header="$AUTH" $URL
