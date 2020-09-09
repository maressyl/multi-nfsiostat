#!/bin/bash

### Send through network all nfsiostat frames which were not sent yet
### Meant to be called by a cron every minute (* * * * * nfsiostat-push.bash <PORT> <DIRECTORY>)

timeout=30
port="$1"
storage="$2"

for frameFile in "$storage/nfsiostat_"*".send"
do
   echo $frameFile
   
   # Make available on port $port for $timeout seconds
   cat "$frameFile" | nc -l -q 1 -p $port -w $timeout
   
   if [ $? == 0 ]
   then
      # On success, remove sent frame file and try sending the next
      rm "$frameFile"
   else
      # On timeout, stop trying (network potentially unavailable, will try in 1 minute anyway)
      exit 1
   fi
done
