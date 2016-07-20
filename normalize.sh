#!/bin/bash

# normalize.sh
# a script to consistently convert, split, and pull stuff sent from portkey (push_daemon.sh)

WATCHDIR=/opt/test
DONEDIR=/opt/test/done

# don't bother running if another instance is
if [ -f ${WATCHDIR}/normalize_lock ]
then
  exit 0
fi

# grab the first file in that list
THEFILE=$(find $WATCHDIR -maxdepth 1 -type f -name '*_of_*.txt' -not -name '.*' | head -1)

# exit if list is empty
if [ $(echo $THEFILE | wc -w) -eq 0 ]
then
  exit 0
fi

touch $WATCHDIR/normalize_lock

echo $THEFILE found.  Starting convert/check routine.

# /opt/test/something.0_of_12.txt
# figure out how many parts we're dealing with

TOTALCNT=$(echo ${THEFILE} | rev | cut -d. -f2 | cut -d_ -f1 | rev)
FILEBASE=$(echo ${THEFILE} | rev | cut -d. -f3- | rev)
DONEFILE=${DONEDIR}/$(basename ${FILEBASE})

echo -n > $DONEFILE
for num in $(seq -f %02g 0 ${TOTALCNT})
do
  FILE=${FILEBASE}.${num}_of_${TOTALCNT}.txt
  BASENAME=$(basename $FILE | rev | cut -d. -f3- | rev)
  while ! [ -f ${FILE} ] 
  do
    echo "Waiting on $FILE to be transferred..."
    sleep 6 
  done 
  echo Converting $FILE to $DONEDIR/$BASENAME.$num
  tail -n +3 $FILE | base64 -d > $DONEDIR/$BASENAME.$num
  echo Checking $DONEDIR/$BASENAME.$num
  echo $(head $FILE -2 | tail -1 | cut -d' ' -f1) $DONEDIR/$BASENAME.$num > $DONEDIR/$BASENAME.$num.sha
  sha256sum -c $DONEDIR/$BASENAME.$num.sha
  retval=$?
  if [ $retval -ne 0 ]
  then
    echo SHA256 returned error, quitting!
    exit 1
  else
    rm $FILE
    rm $DONEDIR/$BASENAME.$num.sha
    cat $DONEDIR/$BASENAME.$num >> $DONEFILE
    rm $DONEDIR/$BASENAME.$num
  fi
done

# remove lock
rm $WATCHDIR/normalize_lock
