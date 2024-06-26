# IHS

Docker based version of `IHS` (Institutshaushaltssystem). It creates the following containers (if the working directory is called `ihs`):

- `ihs-db-1`: MariaDB (local port 3306)
- `ihs-phpmyadmin-1`: phpMyAdmin (local port 8088)
- `ihs-zope-1`: Zope (local port 8080)
- `ihs-web-1`: NGINX (external port 443)

The Zope database is accessible via NGINX configured as reverse SSL proxy. Two locations are special:

- `https://<host>/manage`: Zope management interface
- `https://<host>/mysql`: Web interface of phpMyAdmin

## Installation

Tested on a debian machine with 1&nbsp;GB RAM and 8&nbsp;GB hard drive.

### Install the `docker-ce` environment

```bash
apt remove docker docker.io containerd runc
apt update
apt install ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### Download the installation files

It's higly recommended to clone the git repository to obtain the files:
```bash
git clone https://github.com/PhoenixD-IHS/IHS.git
```
To update the content of the repository run
```bash
git pull
```
from within the cloned folder.
The following parts of these instructions assume that the current working directory is the cloned/downloaded IHS folder.

### Install the file `.env`

```bash
cp .env-template .env
vi .env
```

Set configuration variables

- Server hostname (may be `localhost`for a test installation)
- List of IP addresses allowed to access the web server
- Password for the Zope management account (user `root`)
- Password for the MariaDB `root` user.

The list or IP addresses is a string containing one or more statements of the form `allow <ip address>;`. Each IP address may either be a single address (e.g. `allow 192.168.1.130;`) or an address range (e.g. `allow 192.168.2.0/24;`). If it is changed, run `docker compose down` followed by `docker compose up -d` to reload the addresses into the container.

### Install SSL key and certificate

Store the SSL private key as `ssl/<host>.key` and its certificate as `ssl/<host>.crt`. The key must be accessible without a pass phrase. If there is no certificate private key in the folder `ssl`, a self signed certificate will be generated during installation.

### Build all docker containers

```bash
docker compose up -d --build
```

## Operation

Stop all containers:

```bash
docker compose down
```

Start all containers:

```bash
docker compose up -d
```

## Data transfer from IHS version 11

On the shell console of the old IHS system run the following commands to create a copy of the last database of institute foo. We will keep the current database `Institute_foo` and work only on `Institute_foo_copy` in case anything goes wrong.

```bash
rcmysql stop
cd /local/mysql
cp -a Institut_foo Institut_foo_copy
rcmysql start
```

Switch to a MySQL console on the old IHS system and select the database `Institut_foo_copy`. Then run the following commands to remove obsolete tables which might exist:

```mysql
DROP TABLE IF EXISTS Log;
DROP TABLE IF EXISTS MiscData;
```

Replace the role ID by the role name in `Fonds.Gruppe` (Don't forget to replace `foo` in the command):

```mysql
ALTER TABLE Fonds CHANGE Gruppe Gruppe_old INT(11) NOT NULL DEFAULT '0';
ALTER TABLE Fonds ADD Gruppe VARCHAR(40) NOT NULL DEFAULT '' AFTER Gruppe_old;
UPDATE Fonds as b
INNER JOIN IHS_foo.Roles as a on a.Id = b.Gruppe_old
SET b.Gruppe = a.Rolename;
ALTER TABLE Fonds DROP Gruppe_old;
```

Add missing default values:

```mysql
ALTER TABLE SAP ALTER COLUMN Steuer SET DEFAULT '';
ALTER TABLE SAPinsert ALTER COLUMN Steuer SET DEFAULT '';
```

Convert all tables from charset latin1 to utf8. This can take quite a while, if `SAP` is a large table.

```mysql
ALTER TABLE Anlage CONVERT TO CHARACTER SET utf8;
ALTER TABLE Beleg CONVERT TO CHARACTER SET utf8;
ALTER TABLE Bewilligung CONVERT TO CHARACTER SET utf8;
ALTER TABLE Entsperrung CONVERT TO CHARACTER SET utf8;
ALTER TABLE Fonds CONVERT TO CHARACTER SET utf8;
ALTER TABLE HiWimittel CONVERT TO CHARACTER SET utf8;
ALTER TABLE HiWitarif CONVERT TO CHARACTER SET utf8;
ALTER TABLE HiWivertrag CONVERT TO CHARACTER SET utf8;
ALTER TABLE invPosition CONVERT TO CHARACTER SET utf8;
ALTER TABLE invUnterposition CONVERT TO CHARACTER SET utf8;
ALTER TABLE Korrektur CONVERT TO CHARACTER SET utf8;
ALTER TABLE Mitarbeiter CONVERT TO CHARACTER SET utf8;
ALTER TABLE Personalnummer CONVERT TO CHARACTER SET utf8;
ALTER TABLE Planfonds CONVERT TO CHARACTER SET utf8;
ALTER TABLE Planung CONVERT TO CHARACTER SET utf8;
ALTER TABLE Position CONVERT TO CHARACTER SET utf8;
ALTER TABLE Projekttraeger CONVERT TO CHARACTER SET utf8;
ALTER TABLE SAP CONVERT TO CHARACTER SET utf8;
ALTER TABLE SAPinsert CONVERT TO CHARACTER SET utf8;
ALTER TABLE Sperre CONVERT TO CHARACTER SET utf8;
ALTER TABLE Stelle CONVERT TO CHARACTER SET utf8;
ALTER TABLE Tarif CONVERT TO CHARACTER SET utf8;
ALTER TABLE Unterposition CONVERT TO CHARACTER SET utf8;
ALTER TABLE Vertrag CONVERT TO CHARACTER SET utf8;
ALTER TABLE Zuweisung CONVERT TO CHARACTER SET utf8;
```

The database is now ready for the transfer. Switch back to the shell console of the old IHS system now and generate a database dump `foo.db`. We delete the explicit database engine specification to use the default engine of MariaDB.

```bash
mysqldump -u root -p --skip-add-locks Institut_foo_copy | sed -e "s/^) ENGINE.*utf8;$/);/" > /local/tmp/foo.db
```

Transfer `foo.db` to the new IHS server and store it in the folder `/var/lib/docker/volumes/ihs_mariadb-data/_data`. Run the following command to get a shell in the MariaDB container:

```bash
docker exec -it ihs-db-1 /bin/bash
```

Import the database dump on the new IHS server using the following command on the container shell.

```bash
cat /var/lib/mysql/foo.db | mariadb -u root -p Institut_foo
```

All tables of `Institut_foo` should now be of type InnoDB instead of MyISAM. You can check that using phpMyAdmin.

The database is now restored and the new IHS server is operational with all data from the old server. An import of the latest SAP data via the IHS web interface of the new server should thus indicate no new booking data.

## Development

### Useful docker commands

Show list of running containers:

```bash
docker ps
```

Run an interactive shell in a container:

```bash
docker exec -it ihs-db-1 /bin/bash
```

Run a single command in a container:

```bash
docker exec ihs-web-1 cat /etc/hosts
```

### Most important file locations

- `./.env`: Global parameters
- `./docker-compose.yml`: Build configuration of all containers
- `/var/lib/docker/containers/xxxxx/xxxxx-json.log`: Container log
- `/var/lib/docker/volumes`: Shared volumes for persistent data

### Updating single containers

Links to the official docker images on which the IHS system is based (to look up the most recent version):

- https://hub.docker.com/_/nginx
- https://hub.docker.com/_/mariadb
- https://hub.docker.com/_/phpmyadmin
- https://hub.docker.com/_/python

Links to zope releases (to look up the most recent version):

- https://pypi.org/project/Zope/#history

The IHS system is configured for specific version numbers of these images to keep it stable. IHS developers make sure that compatible version of the underlying images are used. The most recent, tested version can be found in the `docker-compose.yaml`.  Before updating the MariaDB, python or zope version make sure you have a backup!:

To update, replace the `docker-compose.yaml` with the most recent version in this repository and restart the containers:

```bash
docker compose down
docker compose up -d
```
