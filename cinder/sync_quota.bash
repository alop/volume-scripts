#!/bin/bash

if [ $( whoami ) != "root" ]; then
	echo "This script must be run as root"
	exit 1
fi

usage() {
	echo "USAGE: $0 project_name

	Example: $0 sandbox-iad1"
	exit 1
}

if [ -z $1 ]; then
	usage
fi

CINDER_PASS=`knife data bag show --secret-file=/etc/chef/encrypted_data_bag_secret db_passwords cinder | grep -v id | cut -d: -f2 | sed 's/^ *//g'`

KEYSTONE_PASS=`knife data bag show --secret-file=/etc/chef/encrypted_data_bag_secret db_passwords keystone | grep -v id | cut -d: -f2 | sed 's/^ *//g'`
TENANT_NAME=$1

#get tenant Id from keystone
PROJECT_ID=`mysql -u keystone -p${KEYSTONE_PASS} -h db-identity keystone -N -e "select id from tenant where name='${TENANT_NAME}'"`

#TEST QUERIES

COUNT=`mysql -u cinder -p${CINDER_PASS} -h db-non-identity cinder -N -e "select COUNT(*) from volumes where deleted=0 and project_id='${PROJECT_ID}'"`
echo "Actual volume usage is $COUNT"

QUOTA_VOL=`mysql -u cinder -p${CINDER_PASS} -h db-non-identity cinder -N -e "select in_use from quota_usages where resource='volumes' and project_id='${PROJECT_ID}'"`
echo "Quota thinks it's $QUOTA_VOL"
# SQL pseudo

if [ $COUNT -eq $QUOTA_VOL ]
then
	echo "Quota matches, exiting"
	exit
fi

echo "Updating..."

mysql -u cinder -p${CINDER_PASS} -h db-non-identity cinder -N -e "update quota_usages set in_use=(select COUNT(*) from volumes where project_id='${PROJECT_ID}' and deleted=0) where project_id='${PROJECT_ID}' and resource='volumes'"
mysql -u cinder -p${CINDER_PASS} -h db-non-identity cinder -N -e "update quota_usages set in_use=(select SUM(SIZE) from volumes where project_id='${PROJECT_ID}' and deleted=0) where project_id='${PROJECT_ID}' and resource='gigabytes'"

echo "Should be fixed"
COUNT=`mysql -u cinder -p${CINDER_PASS} -h db-non-identity cinder -N -e "select COUNT(*) from volumes where deleted=0 and project_id='${PROJECT_ID}'"`
echo "Actual volume usage is $COUNT"

QUOTA_VOL=`mysql -u cinder -p${CINDER_PASS} -h db-non-identity cinder -N -e "select in_use from quota_usages where resource='volumes' and project_id='${PROJECT_ID}'"`
echo "Quota thinks it's $QUOTA_VOL"
