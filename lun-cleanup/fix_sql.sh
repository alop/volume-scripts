#!/bin/bash

while read line
  do
    set -- $line
    OLD_PROV=$1
    VOL=$2
    REAL_PROV=$3

    echo "update volumes set provider_location=${REAL_PROV} where id=CONV('${VOL}',16,10);"
    done < $1
