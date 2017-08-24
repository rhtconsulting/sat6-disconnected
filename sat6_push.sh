#!/bin/bash

# sat6_push.sh
# a script to perform a "hammer export" of everything available on this (local) satellite

TARFILE=/var/lib/portkey/temp/$(date +%Y%m%d)-CDNincr.tar
INCRDIR=/var/lib/pulp/katello-export/Default_Organization-Default_Organization_View-v1.0-incremental/
METADIR=/var/lib/pulp/published/yum/https/
DESTDIR=/var/lib/portkey/to_send
# set whether to download kickstart info (only necessary for the first sync of KS repos)
DL_KICKSTARTS=0
# set whether to include all repodata
ALL_REPODATA=0

# first wait for anything currently synchronizing on the Satellite
WAIT=$(/usr/bin/hammer --password password task list --search running | grep Synchronize | wc -l)
while [[ $WAIT -ne 0 ]]
do
  sleep 120
  WAIT=$(/usr/bin/hammer --password password task list --search running | grep Synchronize | wc -l)
done

# now export the entire Sat6 Library since a few days ago:
rm -rf $INCRDIR
HAMMERTIME="/usr/bin/hammer --password password content-view version export --content-view-id 1 --organization-id 1 --since $(date -d '2 days ago' +%Y-%m-%dT00:00:00)"
echo $HAMMERTIME
$HAMMERTIME

# download correct updateinfo metadata
find $INCRDIR -name repodata -exec rm -rf {} \; 2>/dev/null
for REPO in $(curl -sk --cert /root/.pulp/user-cert.pem https://satellite6.local.host/pulp/api/v2/repositories/ | jq .[].id |sed s^\"^^g | grep -v Images)
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
  echo feed $FEED
  FILES=$(cat $INCRDIR/Default_Organization/Library/$FPATH/repodata/repomd.xml | grep href | sed -e s/'^.*<location href=\"repodata\/'// | sed -e s/'\"\/>.*$'//)
  for file in $FILES
  do
    wget -N --certificate=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.crt --private-key=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.key --ca-certificate \
      /var/lib/pulp/importers/$REPO-yum_importer/pki/ca.crt --inet4-only -r --no-host-directories --quiet --directory-prefix=$INCRDIR/Default_Organization/Library/  \
      $FEED/repodata/${file}
  done

  # for special cases (kickstarts), download addons repodata...
  if [ $DL_KICKSTARTS -ne 0 ]
  then
    if [ $(echo ${FEED} | grep kickstart | grep '6/6' | grep server)n != 'n' ]
    then
      for addon in HighAvailability ScalableFileSystem LoadBalancer Server ResilientStorage
      do
        wget -N --certificate=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.crt --private-key=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.key --ca-certificate \
        /var/lib/pulp/importers/$REPO-yum_importer/pki/ca.crt --inet4-only -r --no-host-directories --quiet --directory-prefix=$INCRDIR/Default_Organization/Library/  \
        -A "repomd.xml,.treeinfo,productid" $FEED/${addon}/repodata/
        FILES=$(cat $INCRDIR/Default_Organization/Library/${FPATH}/${addon}/repodata/repomd.xml | grep href | sed -e s/'^.*<location href=\"repodata\/'// | sed -e s/'\"\/>.*$'//)
        for file in $FILES
        do
          wget -N --certificate=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.crt --private-key=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.key --ca-certificate \
          /var/lib/pulp/importers/$REPO-yum_importer/pki/ca.crt --inet4-only -r --no-host-directories --quiet --directory-prefix=$INCRDIR/Default_Organization/Library/  \
          ${FEED}/${addon}/repodata/${file}
        done
      done
    fi
    if [ $(echo ${FEED} | grep kickstart | grep '6/6' | grep workstation)n != 'n' ]
    then
      for addon in ScalableFileSystem Workstation
      do
        wget -N --certificate=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.crt --private-key=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.key --ca-certificate \
        /var/lib/pulp/importers/$REPO-yum_importer/pki/ca.crt --inet4-only -r --no-host-directories --quiet --directory-prefix=$INCRDIR/Default_Organization/Library/  \
        -A "repomd.xml,.treeinfo,productid" $FEED/${addon}/repodata/
        FILES=$(cat $INCRDIR/Default_Organization/Library/${FPATH}/${addon}/repodata/repomd.xml | grep href | sed -e s/'^.*<location href=\"repodata\/'// | sed -e s/'\"\/>.*$'//)
        for file in $FILES
        do
          wget -N --certificate=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.crt --private-key=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.key --ca-certificate \
          /var/lib/pulp/importers/$REPO-yum_importer/pki/ca.crt --inet4-only -r --no-host-directories --quiet --directory-prefix=$INCRDIR/Default_Organization/Library/  \
          ${FEED}/${addon}/repodata/${file}
        done
      done
    fi
    if [ $(echo ${FEED} | grep kickstart | grep '7/7' | egrep 'server|system-z')n != 'n' ]
    then
      for addon in HighAvailability ResilientStorage
      do
        wget -N --certificate=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.crt --private-key=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.key --ca-certificate \
        /var/lib/pulp/importers/$REPO-yum_importer/pki/ca.crt --inet4-only -r --no-host-directories --quiet --directory-prefix=$INCRDIR/Default_Organization/Library/  \
        -A "repomd.xml,.treeinfo,productid" $FEED/addons/${addon}/repodata/
        FILES=$(cat $INCRDIR/Default_Organization/Library/${FPATH}/addons/${addon}/repodata/repomd.xml | grep href | sed -e s/'^.*<location href=\"repodata\/'// | sed -e s/'\"\/>.*$'//)
        for file in $FILES
        do
          wget -N --certificate=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.crt --private-key=/var/lib/pulp/importers/$REPO-yum_importer/pki/client.key --ca-certificate \
          /var/lib/pulp/importers/$REPO-yum_importer/pki/ca.crt --inet4-only -r --no-host-directories --quiet --directory-prefix=$INCRDIR/Default_Organization/Library/  \
          ${FEED}/addons/${addon}/repodata/${file}
        done
      done
    fi
  else
    find $INCRDIR -name kickstart -type d -exec rm -rf {} \; 2>/dev/null
  fi
done


# add-in ostree data
find -L /var/lib/pulp/published/ostree/web/ -type f | sort > /tmp/os_tree.txt
if [[ $(diff /var/lib/portkey/os_tree.txt /tmp/os_tree.txt) != '' ]]
then
  for osdir in $(find -L /var/lib/pulp/published/ostree/web/ -type d )
  do
    dir=$(echo ${osdir} | cut -d/ -f 8-)
    if  ! [[ -d ${INCRDIR}/${dir} ]]
    then
      mkdir -p ${INCRDIR}/${dir}
    fi
  done
  for osfile in $(find -L /var/lib/pulp/published/ostree/web/ -mtime -2 -type f)
  do
    cp -f ${osfile} ${INCRDIR}/$(echo ${osfile} | cut -d/ -f 8-)
  done
  cp -f /tmp/os_tree.txt /var/lib/portkey/os_tree.txt
fi

chown -R foreman.foreman $INCRDIR

# remove repodata if there are no RPMS and we didn't force all
if [ $ALL_REPODATA -eq 0 ]
then
  for dir in $(find ${INCRDIR} -type d  -name os)
  do
    HAS_RPMS=$(ls ${dir}/*.rpm ${dir}/Packages/*.rpm 2>/dev/null | wc -l)
    if [ $HAS_RPMS -eq 0 ]
    then
      echo $dir has rpms = $HAS_RPMS
      rm -rfv $dir
    fi
  done
fi


# tar everything up
TARCMD="/usr/bin/tar -cf ${TARFILE} -C ${INCRDIR} ."
echo $TARCMD
$TARCMD

# copy into dest dir
chown -v portkey $TARFILE
mv -v $TARFILE $DESTDIR

