#!/bin/bash
MARIADB_ROOT_PASSWORD="secure-password"
DOCKER_CONTAINER_NAME="ihs-db-1"
DATE=`date +%Y-%m-%d`
HOSTNAME=`hostname -f`

docker exec "${DOCKER_CONTAINER_NAME}" bash -c "mysqldump --all-databases --password=${MARIADB_ROOT_PASSWORD} > /backup/${DATE}_${HOSTNAME}-db.sql"
