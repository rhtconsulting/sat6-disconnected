#!/bin/bash -x

STORAGE=/var/lib/portkey/docker
SENT_IMAGES=/var/lib/portkey/sent-images.txt
IMAGE_STORAGE=${STORAGE}/images
DESTINATION=/var/lib/portkey/to_send/
DOCKER_IMAGES=$(mktemp)

repos=$(/var/lib/portkey/sat6-disconnected/docker_list_images.py | egrep  '^rhel|^openshift3|^rhscl/|^jboss|^dotnet|^cloudforms' | grep -v beta)

# do a fresh pull of everything in our regex above
for r in $repos;
do
  SAVE_DIR=$(dirname ${IMAGE_STORAGE}/$r)
  mkdir -p ${SAVE_DIR}
  CLEANEXIT=1
  TRIES=1
  while [ ${CLEANEXIT} -ne 0 -a ${TRIES} -lt 4 ]; 
  do
    docker pull -a registry.access.redhat.com/$r
    CLEANEXIT=$?
    ((TRIES++))
  done
done


# Gen up current list of images
docker images > $DOCKER_IMAGES

# Save only those image IDs that we haven't saved before
for image in $(cat $DOCKER_IMAGES | awk '{print $3}' | sort | uniq)
do
  if [[ $( grep ${image} ${SENT_IMAGES} ) == '' ]]
  then 
    VERSIONSTRING=$(cat $DOCKER_IMAGES | grep ${image} | awk '{print $1 ":" $2}'| sort | uniq)
    
    echo docker save $VERSIONSTRING \| gzip \> ${IMAGE_STORAGE}/${image}.tar.gz
    docker save $VERSIONSTRING | gzip > ${IMAGE_STORAGE}/${image}.tar.gz
    mv -v ${IMAGE_STORAGE}/${image}.tar.gz ${DESTINATION}/${image}.tar.gz.docker
    temp_sort=$(mktemp)
    echo ${image} | sort ${SENT_IMAGES} - > ${temp_sort}
    mv -f ${temp_sort} ${SENT_IMAGES}
  fi
done

# toss the new mapping into to_send, to double-check versions on the other side
mv -v $DOCKER_IMAGES ${DESTINATION}/docker-image-mapping.txt
