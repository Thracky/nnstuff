#!/bin/sh
# Modified newznab_screen.sh for "safe" importing of nzb's.

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

#Enter your MySQL information below
MYSQL_DBNAME="newznab"
MYSQL_USER="root"
MYSQL_PASS=''
MYSQL_HOST="localhost"

#Enter number of times to allow update_releases to loop while processing imported NZB's before doing an update_binaries.
BINARIES_KEEPUP="5"

#Frequency of optimise_db, update_theaters, and update_tvschedule in seconds.
OPTIMISE_UPDATE="43200"

# Start script

LASTOPTIMIZE=`date +%s`
LASTPARSE=`date +%s`

while :

do
CURRTIME=`date +%s`

cd ${NEWZNAB_DIR}/misc/update_scripts

#Run update_binaries, update_releases.
${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/update_binaries_threaded.php
${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/update_releases.php

#Import NZBs and run update_releases once.
${PHP_PATH}  ${NEWZNAB_DIR}/www/admin/nzb-import.php $NZB_PATH $USE_FILENAME $IMPORT_NUM $MAX_POST_AGE
${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/update_releases.php


RELEASE_BACKLOG=`mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASS $MYSQL_DBNAME -s -N -e "select COUNT(*) from releases r left join category c on c.ID = r.categoryID where (r.passwordstatus between -6 and -1) or (r.haspreview = -1 and c.disablepreview = 0)"`
LOOPCOUNTER="0"
while [ $RELEASE_BACKLOG -gt 10 ]; do

${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/update_releases.php

RELEASE_BACKLOG=`mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASS $MYSQL_DBNAME -s -N -e "select COUNT(*) from releases r left join category c on c.ID = r.categoryID where (r.passwordstatus between -6 and -1) or (r.haspreview = -1 and c.disablepreview = 0)"`
LOOPCOUNTER=`expr $LOOPCOUNTER + 1`
if [ $LOOPCOUNTER -gt BINARIES_KEEPUP ];
then

#Update binaries and process releases every time update_releases loops the number of times defined in BINARIES_KEEPUP
#Again, choose threaded or not.
#${PHP_PATH} ${NEWZNAB_DIR}/update_binaries.php

${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/update_binaries_threaded.php
${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/update_releases.php

LOOPCOUNTER="0"
fi
done

# UNCOMMENT THE FOLLOWING LINE IF YOU USE NZPRE.
#${PHP_PATH} ${NEWZNAB_DIR}/update_predb.php true

DIFF=$(($CURRTIME-$LASTOPTIMIZE))
if [ "$DIFF" -gt "$OPTIMISE_UPDATE" ] || [ "$DIFF" -lt 1 ]
then
	LASTOPTIMIZE=`date +%s`
${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/optimise_db.php
${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/update_tvschedule.php
${PHP_PATH}  ${NEWZNAB_DIR}/misc/update_scripts/update_theaters.php
fi

done
