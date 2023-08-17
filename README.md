# IHS
Docker based version of the _Institutshaushaltssystem_.
It creates the following containers:
* MariaDB
* nginx (reverse proxy for SSL)
* phpMyAdmin (listens only on localjost:8080)
* Zope

## Installation
Tested on a debian machine with 1GB RAM and 8GB hard drive.

### Install Docker:
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
### Modify content of .env
* Choose a secure password for the zope management account.
* Choose a secure password for the mariadb root user.
* Modify the hostname of the server
* Modify the list of IP addresses allowed to access the web server.
  * Accepts list of "allow ..." statements seperated by ';'
  * Addresses can be single IP addresses like "allow 130.75.1.1;"
  * Addresses can be IP ranges "allow 130.75.1.0/24;"
  * Don't forget the semicolon at the end.

### Install SSL certificate
* Copy your certificate to ssl/\<HOSTNAME>.crt. (example: ssl/ihs.pxd.uni-hannover.de.crt)
* Copy your private key to ssl/\<HOSTNAME>.key. (example: ssl/ihs.pxd.uni-hannover.de.key)
  * Private key should be accessible without a password.
* If no certificate is present, a self signed certificate will be generated during installation.

### Build the docker container
```
docker compose up -d --build
```

## Updating single components
* Find out which versions you want to use
  * https://hub.docker.com/_/nginx
  * https://hub.docker.com/_/mariadb
  * https://hub.docker.com/_/phpmyadmin
  * https://hub.docker.com/_/python
* Modify the version behind the container name
  * nginx: inside nginx-Dockerfile and docker-compose.yml
  * mariadb: inside docker-compose.yml
  * phpmyadmin: inside docker-compose.yml
  * python: inside zope-Dockerfile and docker-compose.yml
* Stop IHS containers ```docker compose down```
* Start IHS containers ```docker compose up -d --build```
