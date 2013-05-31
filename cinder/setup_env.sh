#!/bin/bash

if [ $( whoami ) != "root" ]; then
  echo "This script must be run as root"
  exit 1
fi

CINDER_PASS=`knife data bag show --secret-file=/etc/chef/encrypted_data_bag_secret db_passwords cinder | grep -v id | cut -d: -f2 | sed 's/^ *//g'`

NOVA_PASS=`knife data bag show --secret-file=/etc/chef/encrypted_data_bag_secret db_passwords nova | grep -v id | cut -d: -f2 | sed 's/^ *//g'`

DB_IP='db-non-identity'

SQL_CMD="mysql -u cinder -p${CINDER_PASS} -h $DB_IP cinder -N"
N_SQL_CMD="mysql -u nova -p${NOVA_PASS} -h $DB_IP nova -N"
