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


$SQL_CMD -e "update block_device_mapping set deleted=1,deleted_at=(NOW()) where volume_id in (select id from volumes where deleted=1) and deleted=0"
