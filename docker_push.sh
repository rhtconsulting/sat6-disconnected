#!/bin/bash

# Re-tag all images found in the local docker registry
# and push them into the site-wide registry. Intended 
# to be run following docker_load.sh

OLD_REGISTRY=registry.access.redhat.com
REGISTRY=my.corp.registry.org:5000

# get list of local images
IMAGES=$(docker images | awk -v SRC="${OLD_REGISTRY}" '$O ~ SRC {printf "%s:%s\n",$1,$2}')

# tag/push each image
for i in ${IMAGES[@]}
do
  IMAGE=$(echo ${i} | cut -d\/ -f 2-3)
  TAGNAME=${REGISTRY}/${IMAGE}

  # tag new registry server
  echo docker tag -f ${i} $TAGNAME
  docker tag -f ${i} $TAGNAME

  # push to registry, retry if any errors
  RET=1
  while [ $RET -ne 0 ]
  do
    docker push $TAGNAME
    RET=$?
  done

  # finally, remove existing tag (optoinal)
#  docker rmi $IMAGE:$VERS

done
