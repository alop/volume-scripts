#!/bin/bash

if [ $( whoami ) != "root"]; then
  echo "This script must be run as root"
  exit 1
fi

NOVA_PASS=`knife data bag show --secret-file=/etc/chef/encrypted_data_bag_secret prod_dfw2_secrets nova | grep -v id | cut -d: -f2 | sed 's/^ *//g'`

DB_IP='o2r1-ops'
