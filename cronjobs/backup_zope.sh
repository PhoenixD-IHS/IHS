#!/bin/bash

DOCKER_CONTAINER_NAME="ihs-zope-1"
DATE=`date +%Y-%m-%d`
HOSTNAME=`hostname -f`
docker exec "${DOCKER_CONTAINER_NAME}" bin/zopeinstance stop
docker exec "${DOCKER_CONTAINER_NAME}" cp "/usr/local/share/ihs/var/filestorage/Data.fs" "/backup/${DATE}_${HOSTNAME}-Data.fs"
docker exec "${DOCKER_CONTAINER_NAME}" bin/zopeinstance start
