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

#Get our vars sourced
. setup_env.sh

VOLUME_ID=$1

echo "Looking for volume"
NAME=`$SQL_CMD -e "select display_name from volumes where id='${VOLUME_ID}'"`
STATUS=`$SQL_CMD -e "select status from volumes where id='${VOLUME_ID}'"`
LOCATION=`$SQL_CMD -e "select provider_location from volumes where id='${VOLUME_ID}'"`

if [[ $STATUS != 'creating' ]]; then
  echo "Volume $VOLUME_ID $NAME is not stuck in creating, it is $STATUS"
  exit
fi

if [[ -z $LOCATION ]]; then
  $SQL_CMD -e "update volumes set status='deleting',deleted=1,deleted_at=(NOW()) where id='${VOLUME_ID}'"
  echo "$VOLUME_ID deleted"
fi
