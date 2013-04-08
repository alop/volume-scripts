#!/bin/bash

if [ $( whoami ) != "root" ]; then
  echo "this script must be run as root"
  exit 1
fi

usage() {
  echo "usage: $0 volume_id"
  exit 1
}

if [ -z $1 ]; then
  usage
fi

VOLUME_ID=$1

#Get our vars sourced
. setup_env.sh

detach_vol() {
  $SQL_CMD -e "update volumes set status='available',mountpoint=NULL,instance_id=NULL,attach_status='detached',updated_at=(NOW()) where id='${VOLUME_ID}"
}
# Look for volume
echo "Looking for $VOLUME_ID"

NAME=`$SQL_CMD -e "select display_name from volumes where id='${VOLUME_ID}'"`

echo "Is $NAME the volume that needs to be detached in the DB?"
read -p "Are you sure?" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Ok, doing stuff here"
  detach_vol
fi
