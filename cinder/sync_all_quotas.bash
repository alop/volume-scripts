#!/bin/bash

if [ $( whoami ) != "root" ]; then
	echo "This script must be run as root"
	exit 1
fi

LOGFILE=/var/log/quota_sync.log
. setup_env.sh

#Get all quotas by project
PROJECT_LIST=`mysql -u cinder -p${CINDER_PASS} -h db-non-identity cinder -N -e "select distinct project_id from quota_usages"`

#TEST QUERIES
check_quota() {
echo "Checking quotas for $PROJECT_ID " >>$LOGFILE
COUNT=`$SQL_CMD -e "select COUNT(*) from volumes where deleted=0 and project_id='${PROJECT_ID}'"`
echo "Actual volume usage is $COUNT" >>$LOGFILE

QUOTA_VOL=`$SQL_CMD -e "select in_use from quota_usages where resource='volumes' and project_id='${PROJECT_ID}'"`
echo "Quota thinks it's $QUOTA_VOL" >>$LOGFILE

if [ $COUNT -eq $QUOTA_VOL ]
then
	echo "Quota matches, exiting" >>$LOGFILE
	MATCH=true
fi
}
check_space() {
echo "Checking space quota for $PROJECT_ID" >>$LOGFILE
SIZE=`$SQL_CMD -e "select SUM(SIZE) from volumes where deleted=0 and project_id='${PROJECT_ID}'"`
QUOTA_GIGS=`$SQL_CMD -e "select in_use from quota_usages where resource='gigabytes' and project_id='${PROJECT_ID}'"`

if [ "$SIZE" == "NULL" ]; then
	SIZE="0"
fi
if [ $SIZE -eq $QUOTA_GIGS ]
then
	echo "Size quota matches, exiting" >>$LOGFILE
	SIZE_MATCH=true
fi
}

update_quota() {
echo "Updating... $PROJECT_ID" >>$LOGFILE

$SQL_CMD -e "update quota_usages set in_use=(select COUNT(*) from volumes where project_id='${PROJECT_ID}' and deleted=0) where project_id='${PROJECT_ID}' and resource='volumes'"
$SQL_CMD -e "update quota_usages set in_use=(select SUM(SIZE) from volumes where project_id='${PROJECT_ID}' and deleted=0) where project_id='${PROJECT_ID}' and resource='gigabytes'"

echo "Should be fixed" >>$LOGFILE
}

for PROJECT_ID in $PROJECT_LIST
do
MATCH=false
SIZE_MATCH=false
check_quota
if [ $MATCH ]; then
	echo "Quota is OK" >>$LOGFILE
else
update_quota
fi
check_space
if [ $SIZE_MATCH ]; then
	echo "Size quota is OK" >>$LOGFILE
else
update_quota
fi
done

