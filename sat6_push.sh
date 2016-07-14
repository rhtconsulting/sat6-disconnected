#!/bin/bash

# sat6_push.sh
# a script to perform a "hammer export" of everything available on this (local) satellite


# first export the entire Sat6 Library since two days ago:

HAMMERTIME="/usr/bin/hammer --password password content-view version export --content-view-id 1 --organization-id 1 --since $(date -d '2 days ago' +%Y-%m-%dT00:00:00)"

echo $HAMMERTIME
$HAMMERTIME

