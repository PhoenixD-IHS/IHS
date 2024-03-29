#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $SCRIPT_DIR/../.env

BACKUPDIR="${1}"

DATE=`date +%F_%T`
HOSTNAME=`hostname -f`

FILE="${BACKUPDIR}/${HOSTNAME}_IHS-${NAME}_${DATE}.zexp"
mysqldump --all-databases --host=127.0.01 --password=${MARIADB_ROOT_PASSWORD} > ${BACKUPDIR}/${DATE}_${HOSTNAME}-db.sql
