#!/bin/bash
# Sync for QRadar
# Version 1.0 by Oliver Braun
# Version 1.1 by Bruno Oliveira
#
# This script performs a couple of checks before synchronizing two QRadar Systems
# This script only runs if the destination server is online.
# This script writes a lock file to avoid a new synchronization while the old job is still running.
# No options are available
#
#
# cronjob entry like this: (every 12 hours at 5min after full hour)
#       5 */12 * * * root /root/rsync_script.sh
#
# before running this script make sure that you can ping the other system (adjust iptables)
# make sure that your public key is on the other host for ssh communication
#

## Variables
LOCKFILE=/store/sva_rsync_KL.lock
LOGFILE=/var/log/qradar.svarsync_KL
RSYNC=/usr/bin/rsync
BWLIMIT=20000   # Bandwidth limit for the sync job.
SOURCE=/store/ariel
TARGET=/store
VIP=10.12.128.68
MAILADDR=address@address.com
DATE=`date '+%b %d %T'`

check_lock(){
# Check whether lock file exists

if [[ ! -e $LOCKFILE ]]
then
        echo "$DATE No Lock found." >> $LOGFILE
        touch $LOCKFILE
        echo "$DATE Creating one" >> $LOGFILE
else
        echo "$DATE Lock found -- exiting" >> $LOGFILE
        echo "$DATE Lock found, no backup performed" | mailx -s "QRadar backup error" $MAILADDR
        exit 1
fi
}


check_server(){
# Check whether the destination server is online.

ping $VIP -c 1 > /dev/null 2>&1
if [ $? -ne 0 ]
then
  echo "$DATE $VIP is not available. Exiting..." >> $LOGFILE
  echo "$DATE $VIP is not available" | mailx -s "QRadar backup error" $MAILADDR
  exit 1
fi

}

cleanup(){
# Removes the Lock File

rm $LOCKFILE
echo $DATE "Lock File has been successfully erased" >> $LOGFILE
exit 0
}

syncing(){
# the main function doing the sync

echo $DATE "Synchronization has started" >> $LOGFILE
$RSYNC -azv --bwlimit=$BWLIMIT $SOURCE root@$VIP:$TARGET >> $LOGFILE
echo "$DATE Synchronization done, please check once a month." | mailx -s "QRadar backup done" $MAILADDR
echo $DATE "Synchronization has successfully ended" >> $LOGFILE
}


#
# Starting script
#

touch $LOGFILE
echo $DATE "********************************Starting rsync-script**************************************" >> $LOGFILE
check_server
check_lock
syncing
cleanup
exit 1  # you should never reach this point ...
