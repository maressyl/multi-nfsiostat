#!/bin/bash

### Takes one nfsiostat frame and append it to a daily file on master
### Meant to be called by a cron every minute (* * * * * nfsiostat-push.bash <MASTER>)

master="$1"

### ssh-keygen
### ssh-copy-id $master

# Storage location on the master
dir_master="/srv/scratch/mareschalsy/nfsiostat/store"

# Collect during $width seconds
width=10

# Get timestamp once
timestamp=$(date -I"seconds")
day=$(echo $timestamp | sed -r 's/T.+$//')

# Get stats, forget 2nd empty result set
tmpfile="/tmp/nfsiostat.txt"
echo $timestamp > "$tmpfile"
"/usr/sbin/nfsiostat" $width 2 | tail -9 >> "$tmpfile"

# Send to master for appending
if [ ! -z "$master" ]
then
   cat "$tmpfile" | ssh $master "cat >> $dir_master/${day}_$(hostname).txt"
else
   cat "$tmpfile" >> $dir_master/${day}_$(hostname).txt
fi

