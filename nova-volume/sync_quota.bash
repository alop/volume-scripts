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

. setup_env.sh

TENANT_NAME=$1

#get tenant Id from keystone
PROJECT_ID=`$K_SQL_CMD -e "select id from tenant where name='${TENANT_NAME}'"`

#TEST QUERIES

COUNT=`$SQL_CMD -e "select COUNT(*) from volumes where deleted=0 and project_id='${PROJECT_ID}'"`
echo "Actual volume usage is $COUNT"

QUOTA_VOL=`$SQL_CMD -e "select in_use from quota_usages where resource='volumes' and project_id='${PROJECT_ID}'"`
echo "Quota thinks it's $QUOTA_VOL"
# SQL pseudo

if [ $COUNT -eq $QUOTA_VOL ]
then
	echo "Quota matches, exiting"
	exit
fi

echo "Updating..."

$SQL_CMD -e "update quota_usages set in_use=(select COUNT(*) from volumes where project_id='${PROJECT_ID}' and deleted=0) where project_id='${PROJECT_ID}' and resource='volumes'"
$SQL_CMD -e "update quota_usages set in_use=(select SUM(SIZE) from volumes where project_id='${PROJECT_ID}' and deleted=0) where project_id='${PROJECT_ID}' and resource='gigabytes'"

echo "Should be fixed"
COUNT=`$SQL_CMD -e "select COUNT(*) from volumes where deleted=0 and project_id='${PROJECT_ID}'"`
echo "Actual volume usage is $COUNT"

QUOTA_VOL=`$SQL_CMD -e "select in_use from quota_usages where resource='volumes' and project_id='${PROJECT_ID}'"`
echo "Quota thinks it's $QUOTA_VOL"
