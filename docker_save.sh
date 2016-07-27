#!/bin/bash -x

STORAGE=/var/lib/pulp/exports/docker
IMAGE_STORAGE=${STORAGE}/images
DESTINATION=/var/lib/pulp/exports/to_send/

repos=$(/var/lib/pulp/exports/docker_list_images.py | egrep  '^rhel|^openshift3|^rhscl/')

# do a fresh pull of everything in our regex above
for r in $repos;
do
  SAVE_DIR=$(dirname ${IMAGE_STORAGE}/$r)
  sudo mkdir -p ${SAVE_DIR}
  CLEANEXIT=1
  TRIES=1
  while [ ${CLEANEXIT} -ne 0 -a ${TRIES} -lt 4 ]; 
  do
    docker pull -a registry.access.redhat.com/$r
    CLEANEXIT=$?
    ((TRIES++))
  done
done

# we only want to save and push stuff changed within the past week...
for r in $(docker images | grep 'days ago' | cut -d' ' -f1 | grep registry.access.redhat.com | sort | uniq | sed s?registry.access.redhat.com/??)
do
  VERSIONSTRING=$(docker images | grep $r | awk '{print $1 ":" $2}'| sort | uniq)

  echo docker save $VERSIONSTRING \| gzip \> ${IMAGE_STORAGE}/${r}.tar.gz
  docker save $VERSIONSTRING | gzip > ${IMAGE_STORAGE}/${r}.tar.gz
  underscore=$(echo ${r} | sed s^/^_^g)
  mv -v ${IMAGE_STORAGE}/${r}.tar.gz ${DESTINATION}/${underscore}.tar.gz.docker
done
