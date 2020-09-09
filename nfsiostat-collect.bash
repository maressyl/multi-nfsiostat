#!/bin/bash

### Takes one nfsiostat frame and store it both in a daily file (for archiving) and in a frame file (to be sent through network by nfsiostat-push.bash)
### Meant to be called by a cron every minute (* * * * * nfsiostat-push.bash <DIRECTORY>)

storage="$1"

# Collect during $width seconds
width=3

# Get timestamp once
timestamp=$(date -I"seconds")
day=$(echo $timestamp | sed -r 's/T.+$//')
echo $timestamp > "$storage/nfsiostat_${timestamp}.send"

# Get stats
/usr/sbin/nfsiostat $width 2 | tail -9 >> "$storage/nfsiostat_${timestamp}.send"

# Keep a local copy   
cat "$storage/nfsiostat_${timestamp}.send" >> "$storage/nfsiostat_${day}.txt"
