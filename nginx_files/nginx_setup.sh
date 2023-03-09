#!/bin/bash

if [ ! "$(ls -A /etc/ssl/nginx)" ]; then
	# no certs provided, create self signed
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/nginx/${NGINX_HOST}.key -out /etc/ssl/nginx/${NGINX_HOST}.crt -batch
fi

if [ ! -f "/etc/ssl/nginx/${NGINX_HOST}.key" ]; then
	echo "SSL directory not empty, but no key file found. Make sure its filename is ${NGINX_HOST}.key"
	exit 1
fi

if [ ! -f "/etc/ssl/nginx/${NGINX_HOST}.crt" ]; then
	echo "SSL directory not empty, but no crt file found. Make sure its filename is ${NGINX_HOST}.crt"
	exit 1
fi

#cp /etc/nginx/templates/default.conf.template /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh nginx -g "daemon off;"
