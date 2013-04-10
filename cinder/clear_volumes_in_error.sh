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
}
clean_up() {
  $SQL_CMD -e "update volumes set deleted=1,deleted_at=(NOW()) where status like 'error%' and deleted=0 and provider_location is NULL"
}
get_list

if [ -z $LIST ]; then
  echo "Looks like there are no error volumes at this time"
  exit
fi

echo "Clearing up volumes that are in an error state"
echo $LIST
clean_up
unset LIST
get_list
if [ -z $LIST ]; then
  echo "Everything looks ok now"
fi
