#!/bin/bash -x

# grab all available images on the upstream registry
# that docker_list_images.py points to (redhat.com)
# and pull them to the local registry,
# filtering by the IMAGE_REGEX pattern
# finally, save the images to files
# This will create a directory structure under $IMAGES_PATH
# which contains the saved images.

# original credit to Nick Sabine (github.com/nsabine/ose_scripts)

# the regular-expression defining which images to pull
# (remove egrep from "repos" below to pull all available)
IMAGE_REGEX='^rhel|^openshift3|^rhscl/'

# the path at which to store images
IMAGES_PATH=/opt/docker/saved_images

# get list of images to pull
repos=$(python docker_list_images.py | egrep $IMAGE_REGEX)


for r in $repos;
do
  SAVE_DIR=$(dirname ${IMAGES_PATH}/$r)
  sudo mkdir -p ${SAVE_DIR}
  CLEANEXIT=1
  TRIES=1
  # pull each image, retrying if failures are detected (up to 4)
  while [ ${CLEANEXIT} -ne 0 -a ${TRIES} -lt 4 ]; 
  do
    docker pull -a registry.access.redhat.com/$r
    CLEANEXIT=$?
    ((TRIES++))
  done
  
  VERSIONSTRING=$(docker images | grep $r | awk '{print $1 ":" $2}'| sort | uniq)

  # save and compress each image on disk, replacing old copies if necessary
  echo sudo docker save -o ${IMAGES_PATH}/${r}.tar $VERSIONSTRING
  sudo docker save -o ${IMAGES_PATH}/${r}.tar $VERSIONSTRING
  sudo rm -f ${IMAGES_PATH}/${r}.tar.gz
  sudo gzip ${IMAGES_PATH}/${r}.tar
  underscore=$(echo ${r} | sed s^/^_^g)
  curl -k -f -v -T ${IMAGES_PATH}/${r}.tar.gz https://10.0.93.8/file/satelite6/${underscore}.tar.gz

done
