#!/bin/bash

### Pulls the requested daily summaries frm
### Meant to be called once per night (1 0 * * * multi-nfsiostat/pull.bash yesterday clean)
### Can also be called upon request to refresh the data available on master (./nfsiostat-pull.bash [ now ])

# Date to pull
when="$1"
if [ -z "$when" ]; then when="now"; fi

# Whether to clean pulled files on origin server or not
clean="$2"
if [ "$clean" == "clean" ]; then option="--remove-source-files"; else option=""; fi

# Script location
script="$(dirname "$0")"

# Deployed location
pullFrom="$(git remote get-url origin)"
pullTo="$(echo $pullFrom | sed -E 's#^.+/([^/]+)\.git$#\1#')"

# Collect NFS daily summaries
while read host
do
   echo $host
   day=$(date -d "$when" -I"date")
   rsync -z $option "$host:${pullTo}/store/nfs/${day}.txt" "${script}/store/nfs/${day}_${host}.txt"
done < setup/hosts.txt
