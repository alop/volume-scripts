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


