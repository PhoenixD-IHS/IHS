#!/bin/bash

mkdir -p /usr/local/share/ihs

# create build instructions
echo "[buildout]
extends =
	https://zopefoundation.github.io/Zope/releases/${ZOPE_VERSION}/versions-prod.cfg
parts =
	zopeinstance

[zopeinstance]
recipe = plone.recipe.zope2instance
user = root:${ZOPE_ROOT_PASSWORD}
http-address = 8080
zodb-temporary-storage = on
eggs =
    Products.PythonScripts
    Products.ExternalMethod
    Products.TemporaryFolder
    Products.Sessions
    Products.ZMySQLDA
    Products.PluggableAuthService
    Products.ExternalEditor
    reportlab
" > /usr/local/share/ihs/buildout.cfg


cd /usr/local/share/ihs

if [ ! -f /usr/local/share/ihs/.installed.cfg ] || [ $(grep -ic "Zope-${ZOPE_VERSION}-py${PYTHON_VERSION}" .installed.cfg) -eq 0 ];
then
  # not installed or python/zope version was changed
	if [ -f "./var/filestorage/Data.fs" ];
	then
    # there is an existing zope database to preserve
		mv ./var/filestorage/Data.fs ./var/filestorage/Data.fs.bak
		buildout

    # start and stop zope once to create a blank Data.fs.
    # this can be used if the old Data.fs is incompatible with the new environment.
    # it is saved as Data.fs.dist
		/usr/local/share/ihs/bin/zopeinstance start
		/usr/local/share/ihs/bin/zopeinstance stop
		mv ./var/filestorage/Data.fs ./var/filestorage/Data.fs.dist
		mv ./var/filestorage/Data.fs.bak ./var/filestorage/Data.fs
	else
    # no installation found. Nothing to backup.
		buildout
	fi
fi

# copy files to zope directory
cp /zope_files/zope_setup.py /usr/local/share/ihs/
cp /zope_files/index_html.zexp /usr/local/share/ihs/var/zopeinstance/import/
cp /zope_files/Select.zexp /usr/local/share/ihs/var/zopeinstance/import/
mkdir -p /usr/local/share/ihs/parts/zopeinstance/Extensions/
cp -r /zope_files/Extensions/* /usr/local/share/ihs/parts/zopeinstance/Extensions/

/usr/local/share/ihs/bin/zopeinstance run /usr/local/share/ihs/zope_setup.py

# start zope instance
/usr/local/share/ihs/bin/zopeinstance start
exec "$@"
