#!/bin/bash

#-------------------------------------------------------------------------------
# Author:      F2b
# Date:        12/12/2025
# Description: Backup Pretix DB + /var/pretix-data
#-------------------------------------------------------------------------------
# set -x
#-------------------------------------------------------------------------------

SCRIPT=$(readlink -f $0)
LOGFILE=$(dirname $SCRIPT)/$(basename $0 .sh).log

echoTiming()
{
  echo "[`date +%d"/"%m"/"%Y", "%H":"%M":"%S`"]" $@"
}

Main()
{
  DATETIME=$(date +%Y-%m-%d-%H%M%S)

  echoTiming "INFO: ### Lancement de la sauvegarde ###"
  mkdir /home/backup/${DATETIME}
  cp $SCRIPT /home/backup/${DATETIME}/
  cp /home/backup/Restore_instructions.md /home/backup/${DATETIME}/Restore_instructions.md

  echoTiming "INFO: Dump pretix DB..."
  su -c 'pg_dump pretix >> /tmp/pretix.sql' postgres
  mv /tmp/pretix.sql /home/backup/${DATETIME}/pretix.sql

  echoTiming "INFO: Copy pretix-data directory..."
  cp -r /var/pretix-data /home/backup/${DATETIME}/

  echoTiming "INFO: Create compressed archive..."
  cd /home/backup/; tar -cv -I "xz -9" -f pretix-backup-${DATETIME}.tar.xz ${DATETIME}

  echoTiming "INFO: Cleanup..."
  rm -rf ./${DATETIME}/

  echoTiming "INFO: ### Sauvegarde terminée ###"
}

Main $@ | tee -a $LOGFILE 2>&1