#!/bin/bash

lunlist=$2

while read line
  do
    set -- $line
    PROV=$1
    VOL=$2

    LUN=`grep $VOL $lunlist | awk '{print $1}'`

    if [ $PROV -ne $LUN ]; then
      echo $PROV $VOL $LUN >> real_luns
    fi

  done < $1
