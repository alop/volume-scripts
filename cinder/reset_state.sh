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

reset_state() {
  $SQL_CMD -e "update volumes set status='available',updated_at=(NOW()) where id='${VOLUME_ID}'"
}

verify_update() {
  STATUS=`$SQL_CMD -e "select status from volumes where id='${VOLUME_ID}'"`
}

# Look for volume
echo "Looking for $VOLUME_ID"

NAME=`$SQL_CMD -e "select display_name from volumes where id='${VOLUME_ID}'"`

echo "Is $NAME the volume that needs to be reset in the DB?"
read -p "Are you sure?" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Ok, marking volume $VOLUME_ID $NAME as available"
  reset_state
  verify_update

  if [[ $STATUS =~ 'available' ]]; then
    echo "Status is $STATUS, looks good"
  else
    echo "Status is not correct, please try again"
  fi
fi
