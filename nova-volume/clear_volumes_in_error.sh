#!/bin/bash

if [ $( whoami ) != "root" ]; then
  echo "this script must be run as root"
  exit 1
fi

usage() {
  echo "usage: $0 volume_id"
  exit 1
}

#Get our vars sourced
. setup_env.sh
get_list() {
  LIST=`$SQL_CMD -e "select id from volumes where status like 'error%' and deleted=0 and provider_location is NULL"`
  SNAP_LIST=`$SQL_CMD -e "select id from snapshots where status like 'error%' and deleted=0"`
}
clean_up() {
  $SQL_CMD -e "update volumes set deleted=1,deleted_at=(NOW()) where status like 'error%' and deleted=0 and provider_location is NULL"
  $SQL_CMD -e "update snapshots set deleted=1,deleted_at=(NOW()) where status like 'error%' and deleted=0"
}
get_list

if [ -z "$LIST" ]; then
  echo "Looks like there are no error volumes at this time"
  exit
fi

echo "Clearing up volumes that are in an error state"
echo $LIST
echo "Clearing up snapshots that are in an error state"
echo $SNAP_LIST
clean_up
unset LIST
get_list
if [ -z $LIST ]; then
  echo "Everything looks ok now"
fi
