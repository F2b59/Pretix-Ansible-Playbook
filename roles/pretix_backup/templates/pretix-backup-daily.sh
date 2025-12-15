#!/bin/bash

#-------------------------------------------------------------------------------
# Author:      F2b
# Date:        13/01/2025
# Description: Backup Pretix DB + /var/pretix-data
#-------------------------------------------------------------------------------
# set -x
#-------------------------------------------------------------------------------

SCRIPT=$(readlink -f $0)
#LOGFILE=$(dirname $SCRIPT)/$(basename $0 .sh).log
LOGFILE=$(dirname $SCRIPT)/pretix-backup.log

echoTiming()
{
  echo "[`date +%d"/"%m"/"%Y", "%H":"%M":"%S`"]" $@"
}

Main()
{
  echoTiming "INFO: ### Lancement script de sauvegarde Daily ###"
  rm -rf /home/backup/postgresql/* /home/backup/pretix/*
  
  echoTiming "INFO: Dump pretix DB..."
  su -c 'pg_dump pretix >> /tmp/pretix.sql' postgres
  mv /tmp/pretix.sql /home/backup/postgresql/pretix.sql

  echoTiming "INFO: Copy pretix-data directory..."
  cp -r /var/pretix-data /home/backup/pretix/

  echoTiming "DEBUG: Filesystem usage:"
  df -h | grep "/$"
  
  echoTiming "INFO: Running Duplicity for PostgreSQL..."
  duplicity --no-encryption /home/backup/postgresql rsync://backup@{{ backup_server_address }}//home/backup/{{ domain_name }}/postgresql  # /!\ Jinja2 templating here
  
  echoTiming "INFO: Running Duplicity for pretix-data..."
  duplicity --no-encryption /home/backup/pretix rsync://backup@{{ backup_server_address }}//home/backup/{{ domain_name }}/pretix  # /!\ Jinja2 templating here
  
  echoTiming "INFO: ### Sauvegarde terminée ###"
}

Main $@ | tee -a $LOGFILE 2>&1
