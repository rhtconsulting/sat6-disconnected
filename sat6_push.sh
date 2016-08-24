#!/bin/bash

# sat6_push.sh
# a script to perform a "hammer export" of everything available on this (local) satellite

TARFILE=/var/lib/portkey/temp/$(date +%Y%m%d)-CDNincr.tar
#INCRDIR=/var/lib/pulp/katello-export/Default_Organization-Default_Organization_View-v1.0-incremental/Default_Organization/Library/
INCRDIR=/var/lib/pulp/katello-export/Default_Organization-Default_Organization_View-v1.0-incremental/
METADIR=/var/lib/pulp/published/yum/https/
DESTDIR=/var/lib/portkey/to_send

# first export the entire Sat6 Library since a few days ago:
#rm -rf $INCRDIR
HAMMERTIME="/usr/bin/hammer --password password content-view version export --content-view-id 1 --organization-id 1 --since $(date -d 'last week' +%Y-%m-%dT00:00:00)"
echo $HAMMERTIME
$HAMMERTIME

# download correct updateinfo metadata
find $INCRDIR -name repodata -exec rm -rfv {} \; 2>/dev/null
for REPO in $(curl -sk --cert /root/.pulp/user-cert.pem https://satellite6.local.host/pulp/api/v2/repositories/ | jq .[].id |sed s^\"^^g | tail )
do
  FEED=$(curl -sk --cert /root/.pulp/user-cert.pem https://satellite6.local.host/pulp/api/v2/repositories/${REPO}/importers/yum_importer/ | jq .config.feed | sed s^\"^^g)
  if [ $FEED == 'null' ]
  then
    continue
  fi
  FPATH=$(echo $FEED | sed s?https://cdn.redhat.com/??)
  wget -N --certificate=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.crt --private-key=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.key --ca-certificate \
    /var/lib/pulp/importers/$REPO-yum_importer/pki/ca.crt --inet4-only -r --no-host-directories --quiet --directory-prefix=$INCRDIR/Default_Organization/Library/  \
    -A repomd.xml $FEED/repodata/repomd.xml
  echo repo $REPO
  FILES=$(cat $INCRDIR/Default_Organization/Library/$FPATH/repodata/repomd.xml | grep href | sed -e s/'^.*<location href=\"repodata\/'// | sed -e s/'\"\/>.*$'//)
  for file in $FILES
  do
    wget -N --certificate=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.crt --private-key=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.key --ca-certificate \
      /var/lib/pulp/importers/$REPO-yum_importer/pki/ca.crt --inet4-only -r --no-host-directories --quiet --directory-prefix=$INCRDIR/Default_Organization/Library/  \
      $FEED/repodata/${file}
  done
done

chown -R apache.apache $INCRDIR

# tar everything up
TARCMD="/usr/bin/tar -cvf ${TARFILE} -C ${INCRDIR} ."
echo $TARCMD
$TARCMD

# copy into dest dir
chown -v portkey $TARFILE
mv -v $TARFILE $DESTDIR
