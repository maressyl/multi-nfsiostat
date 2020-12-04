#!/bin/bash

### Listen for frames sent through network and collect them by host
### Meant to be called by a cron every minute (* * * * * nfsiostat-push.bash <PORT> <DIRECTORY>)

port="$1"
storage="$2"

for round in 1 2
do
   while read host
   do
      # Get frame (sent one by one)
      cat < /dev/tcp/$host/$port > "$storage/pull/pulled.txt"
      
      # On success
      if [ $? == 0 ]
      then 
         # Get date
         day=$(head -1 "$storage/pull/pulled.txt" | sed -r 's/T.+$//')
         
         # Store in daily file
         cat "$storage/pull/pulled.txt" >> "$storage/pull/${day}_${host}.txt"
         
         # Remove frame
         rm "$storage/pull/pulled.txt"
      fi
      
      sleep 1
   done < <(cut -d"," -f1 "$storage/hosts.csv")
done
