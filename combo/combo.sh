#!/bin/sh
# Combination of safebackfill and my import script.

set -e

#Path to php binary
export PHP_PATH="/usr/bin/php"

#Path to your newznab installation
export NEWZNAB_DIR="/var/www/newznab"

#Path to NZB's to import
NZB_PATH="/path/to/nzbs/"

#Number of NZB's to import per run.
IMPORT_NUM="100"

#Use NZB name for release name. "true" or "false"
USE_FILENAME="true"

#Maximum age of usenet post to import from NZB's in days. Leave blank to import everything.
MAX_POST_AGE=""

#Number of days to backfill.
BACKFILL_DAYS="200"

#Enter your MySQL information below
MYSQL_DBNAME="newznab"
MYSQL_USER="root"
MYSQL_PASS=''
MYSQL_HOST="localhost"

#Enter number of times to allow update_releases to loop while processing backfill before doing an update_binaries.
BINARIES_KEEPUP="5"

#Begin script
while :

do

cd ${NEWZNAB_DIR}/misc/update_scripts

#Get our groups up to date before starting a backfill day, threaded or not.
#${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/update_binaries.php
${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/update_binaries_threaded.php
${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/update_releases.php

#Import NZBs and run update_releases once before we backfill.
${PHP_PATH}  ${NEWZNAB_DIR}/www/admin/nzb-import.php $NZB_PATH $USE_FILENAME $IMPORT_NUM $MAX_POST_AGE
${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/update_releases.php

#Run backfill, either regular or threaded, take your pick.
#${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/backfill.php
${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/backfill_threaded.php

#Run update_releases once so we know how many releases we are dealing with.
${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/update_releases.php

#Check the number of releases waiting for postproc
RELEASE_BACKLOG=`mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASS $MYSQL_DBNAME -s -N -e "select COUNT(*) from releases r left join category c on c.ID = r.categoryID where (r.passwordstatus between -6 and -1) or (r.haspreview = -1 and c.disablepreview = 0)"`
LOOPCOUNTER="0"

while [ $RELEASE_BACKLOG -gt 10 ]; do 
${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/update_releases.php

RELEASE_BACKLOG=`mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASS $MYSQL_DBNAME -s -N -e "select COUNT(*) from releases r left join category c on c.ID = r.categoryID where (r.passwordstatus between -6 and -1) or (r.haspreview = -1 and c.disablepreview = 0)"`
LOOPCOUNTER=`expr $LOOPCOUNTER + 1`
if [ $LOOPCOUNTER -gt $BINARIES_KEEPUP ]
then

#Update binaries and process releases every time update_releases loops the number of times defined in BINARIES_KEEPUP
#Again, choose threaded or not.

#${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/update_binaries.php
${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/update_binaries_threaded.php
${PHP_PATH} ${NEWZNAB_DIR}/misc/update_scripts/update_releases.php
LOOPCOUNTER="0"

fi

done

echo "Finished backfilling another day, running optimizations and cleanup."
sleep 5

echo "Optimization done, on to backfilling another day."
mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASS $MYSQL_DBNAME -e "UPDATE groups set backfill_target=backfill_target+1 where active=1 and backfill_target<$BACKFILL_DAYS;"
sleep 5

done
