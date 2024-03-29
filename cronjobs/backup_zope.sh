#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $SCRIPT_DIR/../.env

NAME="${1}"
BACKUPDIR="${2}"

DATE=`date +%F_%T`
HOSTNAME=`hostname -f`

AUTH="Authorization: basic `echo -n "root:${ZOPE_ROOT_PASSWORD}" | base64`"
URL="http://localhost:8080/Select/install/export_py?kurztext=${NAME}"
FILE="${BACKUPDIR}/${HOSTNAME}_IHS-${NAME}_${DATE}.zexp"
echo "Storing ZODB backup of /IHS-${NAME} in ${FILE}..."
wget --quiet -O $FILE --header="$AUTH" $URL
