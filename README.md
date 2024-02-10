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
* Server hostname (may be `localhost`for a test installation)
* List of IP addresses allowed to access the web server
* Password for the Zope management account (user `root`)
* Password for the MariaDB `root` user.

The list or IP addresses is a string containing one or more statements of the form `allow <ip address>;`. Each IP address may either be a single address (e.g. `allow 192.168.1.130;`) or an address range (e.g. `allow 192.168.2.0/24;`).

### Install SSL key and certificate

Store the SSL private key as `ssl/<host>.key` and its certificate as `ssl/<host>.crt`. The key must be accessible without a pass phrase. If there is no certificate private key in the folder `ssl`, a self signed certificate will be generated during installation.

### Build all docker containers

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

## Data transfer from IHS version 11

On the shell console of the old IHS system run the following commands to create a copy of the last database of institute foo. We will keep the current database `Institute_foo` and work only on `Institute_foo_copy` in case anything goes wrong.
```
rcmysql stop
cd /local/mysql
cp -a Institut_foo Institut_foo_copy
rcmysql start
```

Switch to a MySQL console on the old IHS system and select the database `Institut_foo_copy`. Then run the following commands to remove obsolete tables which might exist:
```
DROP TABLE IF EXISTS Log;
DROP TABLE IF EXISTS MiscData;
```

Replace the role ID by the role name in `Fonds.Gruppe`:
```
ALTER TABLE Fonds CHANGE Gruppe Gruppe_old INT(11) NOT NULL DEFAULT '0';
ALTER TABLE Fonds ADD Gruppe VARCHAR(40) NOT NULL DEFAULT 'None' AFTER Gruppe_old;
UPDATE Fonds as b 
INNER JOIN IHS_pxd.Roles as a on a.Id = b.Gruppe_old
SET b.Gruppe = a.Rolename;
ALTER TABLE Fonds DROP Gruppe_old;
```

Add missing default values:
```
ALTER TABLE SAP ALTER COLUMN Steuer SET DEFAULT '';
ALTER TABLE SAPinsert ALTER COLUMN Steuer SET DEFAULT '';
```

Convert all tables from charset latin1 to utf8. This can take quite a while, if `SAP` is a large table.
```
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

The database is now ready for the transfer. Switch back to the shell console of the old IHS system now and generate a database dump `foo.db`. We switch the database engine to utf8 in this step. This makes utf8 the default for new tables in the future.
```
mysqldump -u root -p<pass> --skip-add-locks Institut_foo_copy | sed -e "s/^) ENGINE.*utf8;$/);/" > /local/tmp/foo.db
```

Transfer `foo.db` to the new IHS server and store it in the folder `/var/lib/docker/volumes/ihs_backup/_data`. Run the following command to get a shell in the MariaDB container:
```
docker exec -it ihs-db-1 /bin/bash
```

Import the database dump on the new IHS server using the following command on the container shell. 
```
cat /backup/foo.db | mysql -u root -p<pass> Institut_foo
```
All tables of `Institut_foo` should now be of type InnoDB instead of MyISAM. You can check that using phpMyAdmin.

The database is now prepared to import the latest SAP data via the IHS web interface.

## Development

### Useful docker commands

Show list of running containers:

```
docker ps
```

Run an interactive shell in a container:

```
docker exec -it ihs-db-1 /bin/bash
```

Run a single command in a container:

```
docker exec ihs-web-1 cat /etc/hosts
```

### Most important file locations

* `./.env`: Global parameters
* `./docker-compose.yml`: Build configuration of all containers
* `./nginx_templates/default.conf.template`: NGINX configuration
* `/var/lib/docker/containers/xxxxx/xxxxx-json.log`: Container log
* `/var/lib/docker/volumes`: Shared volumes for persistent data

### Updating single containers

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

