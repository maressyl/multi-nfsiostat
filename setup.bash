#!/bin/bash

### Installs a SSH key to all slave servers, in order to be able to pull files from them without password

# Whether to update the git repository if it already exists or not
update="$1"

# NFS mountpoint to monitor
target="$(cat setup/target.txt)"

# Generate a SSH key, if none exists
if [ ! -f ~/.ssh/id_rsa ]
then
   ssh-keygen
fi

# Git repository
pullFrom="$(git remote get-url origin)"

# Collect NFS daily summaries
while read host
do
   echo "[ $host ]"
   
   # Install SSH key
   ssh-copy-id $host
   
   # Remote setup
   ssh $host bash -s -- "$pullFrom" "$target" "$update" < setup/remote-setup.bash
   
done < setup/hosts.txt

# Install crontab
crontab setup/master.cron
