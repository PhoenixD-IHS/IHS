# IHS

Docker based version of `IHS` (Institutshaushaltssystem). It creates the following containers:

* `ihs-db-1`: MariaDB (local port 3306)
* `ihs-phpmyadmin-1`: phpMyAdmin (local port 8088)
* `ihs-zope-1`: Zope (local port 8080)
* `ihs-web-1`: NGINX (external port 443)

The Zope database is accessible via NGINX configured as reverse SSL proxy. Two locations are special:

* `https://<host>/manage`: Zope management interface
* `https://<host>/mysql`: Web interface of phpMyAdmin


## Installation

Tested on a debian machine with 1&nbsp;GB RAM and 8&nbsp;GB hard drive.

### Install the `docker-ce` environment

```
apt remove docker docker.io containerd runc
apt update
apt install ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### Install the file `.env`

```
cp .env-template .env
vi .env
```

Set configuration variables
* Password for the Zope management account (user `root`)
* Password for the MariaDB `root` user.
* Server hostname (may be `localhost`for a test installation)
* List of IP addresses allowed to access the web server

The list or IP addresses is a string containing one or more statements of the form `allow <ip address>;`. Each IP address may either be a single address or a range  list of "allow ..." statements seperated by ';'
  * Addresses can be single IP addresses like "allow 130.75.1.1;"
  * Addresses can be IP ranges "allow 130.75.1.0/24;"
  * Don't forget the semicolon at the end.

### Install SSL certificate

* Store your certificate in `ssl/\<HOSTNAME>.crt`.
* Store your private key in `ssl/\<HOSTNAME>.key`. The private key must be accessible without a pass phrase.

If there is no certificate private key in the folder `ssl`, a self signed certificate will be generated during installation.

### Build the docker container
```
docker compose up -d --build
```

## Operation

Stop all containers:
```
docker compose down
```

Start all containers:
```
docker compose up -d
```

## Development

### Updating single components

Determine which more current versions you want to use:
* https://hub.docker.com/_/nginx
* https://hub.docker.com/_/mariadb
* https://hub.docker.com/_/phpmyadmin
* https://hub.docker.com/_/python

Modify the container versions in the following files:
* nginx: inside `nginx-Dockerfile` and `docker-compose.yml`
* mariadb: inside `docker-compose.yml`
* phpmyadmin: inside `docker-compose.yml`
* python: inside `zope-Dockerfile` and `docker-compose.yml`
