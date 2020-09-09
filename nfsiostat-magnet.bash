#!/bin/bash

### Pull all pending frames immediately
### Meant to be called manually

port="$1"
storage="$2"

while true
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
         echo "Pulled "$(head -1 "$storage/pull/pulled.txt")" from $host"
         rm "$storage/pull/pulled.txt"
      fi
   done < <(cut -d"," -f1 "$storage/hosts.csv")
done
