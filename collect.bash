#!/bin/bash

### Takes one nfsiostat frame and append it to a daily file on master
### Meant to be called by a cron every minute (* * * * * multi-nfsiostat/collect.bash [ df ])

# Whether to monitor free space or not
df="$1"

# Script location
script="$(dirname "$0")"

# NFS mountpoint to monitor
target="$(cat ${script}/setup/target.txt)"

# Collect during $width seconds
width=10

# Get timestamp once
timestamp=$(date -I"seconds")
day=$(echo $timestamp | sed -r 's/T.+$//')
time=$(echo $timestamp | sed -r 's/^.+T//')

# Get stats, forget 2nd empty result set
outfile="${script}/store/nfs/${day}.txt"
echo $timestamp >> "$outfile"
"/usr/sbin/nfsiostat" $width 2 $target | tail -9 >> "$outfile"

if [ ! -z "$df" ]
then
   # Monitor free space
   outfile="${script}/store/df/${day}.txt"
   echo -n "$time " >> "$outfile"
   df $target | tail -1 >> "$outfile"
fi
