#!/bin/bash

### Scripts to remotely run on slaves during setup

# Custom configuration (if any)

# URL of the git repository
pullFrom="$1"

# NFS mountpoint to monitor
target="$2"

# Whether to update the git repository if it already exists or not
update="$3"

# Deployed location
pullTo="$(echo $pullFrom | sed -E 's#^.+/([^/]+)\.git$#\1#')"

# Deploy git repository
if [ -d "$pullTo" ]
then
   if [ "$update" == "update" ]
   then
      # Exists : update
      echo "$pullTo already exists, updating"
      cd "$pullTo"
      git pull
   else
      # Exists : do nothin
      echo "$pullTo already exists, keep intact"
   fi
else
   # Doesn't exist : clone
   echo "$pullTo missing, cloning $pullFrom"
   git clone "$pullFrom"
fi

cd ~/"$pullTo"

# Update target
echo "$target" > setup/target.txt

# Install crontab
crontab setup/slave.cron
