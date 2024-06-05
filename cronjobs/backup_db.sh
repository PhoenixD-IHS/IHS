#!/bin/bash

VERBOSE=false

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $SCRIPT_DIR/../.env

if [ "${1}" == "-h" ] || [ $# -lt 1 ]; then
	echo "Usage: backupe_zope.sh <backup-directory>"
	echo "	backup-directory - Verzeichnis in welches das Backup gespeichert wird."
	echo ""
	exit 0
fi

BACKUPDIR="${1}"
VERBOSE="${2}"

DATE=`date +%F_%T`
HOSTNAME=`hostname -f`

FILE="${BACKUPDIR}/${HOSTNAME}_IHS-${NAME}_${DATE}.zexp"
if [ $VERBOSE ]; then
	echo -n "Dumping database to ${BACKUPDIR}/${DATE}_${HOSTNAME}-db.sql.gz..."
fi
mysqldump --all-databases --host=127.0.0.1 --password=${MARIADB_ROOT_PASSWORD} | gzip -c > ${BACKUPDIR}/${DATE}_${HOSTNAME}-db.sql.gz
if [ $VERBOSE ]; then
	echo " done!"
fi
