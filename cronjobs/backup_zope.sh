#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $SCRIPT_DIR/../.env

if [ "${1}" == "-h" ] || [ $# -lt 2 ]; then
	echo "Usage: backupe_zope.sh <acronym> <backup-directory>"
	echo "	acronym - Instutskuerzel, wie es auch im IHS verwendet wird (Gross/Kleinschreibung beachten!)"
	echo "	backup-directory - Verzeichnis in welches das Backup gespeichert wird."
	echo ""
	exit 0
fi

NAME="${1}"
BACKUPDIR="${2}"
VERBOSE="${3}"

DATE=`date +%F_%T`
HOSTNAME=`hostname -f`

AUTH="Authorization: basic `echo -n "root:${ZOPE_ROOT_PASSWORD}" | base64`"
URL="http://localhost:8080/Select/install/export_py?kurztext=${NAME}"
FILE="${BACKUPDIR}/${HOSTNAME}_IHS-${NAME}_${DATE}.zexp"
if [ $VERBOSE ]; then
	echo -n "Storing ZODB backup of /IHS-${NAME} in ${FILE}.gz..."
fi

HTTP_CODE=$(wget --spider -S --header="$AUTH" $URL 2>&1 | grep "HTTP/" | awk '{print $2}')

if [ $HTTP_CODE != "200" ]; then
	echo "ERROR: Webserver returned HTTP code ${HTTP_CODE}. Check if the server is running properly."
	echo "NO BACKUP WAS SAVED!!!"
	exit 1
fi

wget --quiet -O - --header="$AUTH" $URL > "${FILE}"

if [ ! -s "${FILE}" ]; then
	echo "ERROR: The file seems to be empty! Check if the acronym is correct!"
	echo "NO BACKUP WAS SAVED!!!"
	exit 1
fi

gzip "${FILE}"

if [ $VERBOSE ]; then
	echo " done!"
fi
