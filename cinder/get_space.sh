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

SPACE=`$SQL_CMD -e "select SUM(size) from volumes where deleted=0"`
echo "Total requested space = $SPACE"
