#!/bin/bash

# normalize.sh
# a script to consistently convert, split, and pull stuff sent from portkey (push_daemon.sh)

WATCHDIR=/opt/test/out
DONEDIR=/opt/test/done

# grab list of files to play with
LIST="$(find $WATCHDIR -maxdepth 1 -type f -size +1c -name '*_of_*.txt' -not -name '.*') exit"

# check incoming directory for files, quit if none
if [ $(echo $LIST | wc -l) -eq 0 ]
then
  exit 0
fi

for THEFILE in $LIST
do
  FILENONUM=$(echo ${THEFILE} | rev | cut -d. -f3- | rev)
  #FILEBASE=$(basename ${THEFILE})

  # check for end-of-list keyword
  if [ $THEFILE == "exit" ]
  then
    #echo "No files found, exiting"
    exit 0
  fi

  # check to see if this file has been handled by another process...
  if [ -f $TMPDIR/${FILENONUM}.inprogress ]
  then
    #exit 0
    echo "$(date '+%Y%m%d - %H:%M:%S') $TMPDIR/${FILENONUM}.inprogress found, skipping."
  else
    # make sure all parts are available, otherwise go on to next file
    TOTALCNT=$(echo ${THEFILE} | rev | cut -d. -f2 | cut -d_ -f1 | rev)
    declare -i OKCNT=0
    for num in $(seq -f %02g 0 ${TOTALCNT})
    do
      FILE=${FILENONUM}.${num}_of_${TOTALCNT}.txt
      BASENAME=$(basename $FILE | rev | cut -d. -f3- | rev)
      if ! [ -f ${FILE} ] 
      then
        echo "$(date '+%Y%m%d - %H:%M:%S') "$FILE has not yet been transferred, skipping this group for now."
        break
      else
        OKCNT=$OKCNT+1
      fi
      if [ $OKCNT -eq $(($TOTALCNT + 1)) ]
      then
        break 2
      fi
    done
  fi
done

touch $TMPDIR/${FILENONUM}.inprogress

echo "$(date '+%Y%m%d - %H:%M:%S') $THEFILE found.  Starting convert/check routine."

# /opt/test/something.0_of_12.txt
# figure out how many parts we're dealing with

TOTALCNT=$(echo ${THEFILE} | rev | cut -d. -f2 | cut -d_ -f1 | rev)
FILENONUM=$(echo ${THEFILE} | rev | cut -d. -f3- | rev)
DONEFILE=${DONEDIR}/$(basename ${FILENONUM})

echo -n > $DONEFILE
for num in $(seq -f %02g 0 ${TOTALCNT})
do
  FILE=${FILENONUM}.${num}_of_${TOTALCNT}.txt
  BASENAME=$(basename $FILE | rev | cut -d. -f3- | rev)
  echo "$(date '+%Y%m%d - %H:%M:%S') Converting $FILE to $DONEDIR/$BASENAME.$num"
  tail -n +3 $FILE | base64 -d > $DONEDIR/$BASENAME.$num
  echo "$(date '+%Y%m%d - %H:%M:%S')  Checking $DONEDIR/$BASENAME.$num"
  echo $(head -2 $FILE | tail -1 | cut -d' ' -f1) $DONEDIR/$BASENAME.$num > $DONEDIR/$BASENAME.$num.sha
  sha256sum -c $DONEDIR/$BASENAME.$num.sha
  retval=$?
  if [ $retval -ne 0 ]
  then
    echo "$(date '+%Y%m%d - %H:%M:%S') SHA256 returned error, quitting!"
    exit 1
  else
    rm $FILE
    rm $DONEDIR/$BASENAME.$num.sha
    cat $DONEDIR/$BASENAME.$num >> $DONEFILE
    rm $DONEDIR/$BASENAME.$num
  fi
done

# remove lock
if [ -f $TMPDIR/${FILENONUM}.inprogress ]
  then
    rm $TMPDIR/${FILENONUM}.inprogress
  fi
