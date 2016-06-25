#!/bin/bash

# Loads all images stored in .tar files.  Intended to 
# import the files created by docker_save.sh
# THIS WILL USE A TON OF DISK SPACE

# original credit to Nick Sabine (github.com/nsabine/ose_scripts)

# the path where a directory structure of images is stored
IMAGES_PATH=/opt/docker/saved_images


for i in `find $IMAGES_PATH -name "*.gz"`
do 
  echo -n "Decompressing: "
  ls ${i}
  gunzip ${i}
done

for i in `find $IMAGES_PATH -name "*.tar"`
do 
  echo -n "Loading file: "
  ls ${i}
  docker load -i ${i}
done;
