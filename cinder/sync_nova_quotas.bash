#!/bin/bash

if [ $( whoami ) != "root" ]; then
	echo "This script must be run as root"
	exit 1
fi

LOGFILE=/var/log/quota_sync.log
. setup_env.sh

#Get all quotas by project
PROJECT_LIST=`N_SQL_CMD -N -e "select distinct project_id from quota_usages"`

#TEST QUERIES
check_quota() {
echo "Checking quotas for $PROJECT_ID " >>$LOGFILE
COUNT=`$N_SQL_CMD -e "select COUNT(*) from instances where deleted=0 and project_id='${PROJECT_ID}'"`
echo "Actual instance usage is $COUNT" >>$LOGFILE

QUOTA_VOL=`$N_SQL_CMD -e "select in_use from quota_usages where resource='instances' and project_id='${PROJECT_ID}'"`
echo "Quota thinks it's $QUOTA_VOL" >>$LOGFILE

if [ $COUNT -eq $QUOTA_VOL ]
then
	echo "Quota matches, exiting" >>$LOGFILE
else
  echo "Quota needs update" >>$LOGFILE
  update_quota
fi
}
check_ram() {
echo "Checking instance quota for $PROJECT_ID" >>$LOGFILE
RAM=`$N_SQL_CMD -e "select SUM(memory_mb) from instances where deleted=0 and project_id='${PROJECT_ID}'"`
QUOTA_RAM=`$N_SQL_CMD -e "select in_use from quota_usages where resource='ram' and project_id='${PROJECT_ID}'"`

if [ "$RAM" == "NULL" ]; then
	RAM="0"
fi
if [ $RAM -eq $QUOTA_RAM ]
then
	echo "Memory quota matches, exiting" >>$LOGFILE
else
  echo "Memory quota needs update" >>$LOGFILE
  update_quota
fi
}

update_quota() {
echo "Updating... $PROJECT_ID" >>$LOGFILE

$N_SQL_CMD -e "update quota_usages set in_use=(select COUNT(*) from instances where project_id='${PROJECT_ID}' and deleted=0) where project_id='${PROJECT_ID}' and resource='instances'"
$N_SQL_CMD -e "update quota_usages set in_use=(select SUM(vcpus) from instances where project_id='${PROJECT_ID}' and deleted=0) where project_id='${PROJECT_ID}' and resource='cores'"
$N_SQL_CMD -e "update quota_usages set in_use=(select SUM(memory_mb) from instances where project_id='${PROJECT_ID}' and deleted=0) where project_id='${PROJECT_ID}' and resources='ram'"

echo "Should be fixed" >>$LOGFILE
}

for PROJECT_ID in $PROJECT_LIST
do
check_quota
check_space
done

