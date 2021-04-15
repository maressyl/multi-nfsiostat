# multi-nfsiostat

## Description

Each "slave" server runs `nfsiostat` for 10 seconds every minute and send the result to a single "master" server through SSH, in order to plot summaries of NFS performances.

## Setting up the master

1. Pull the repository in the desired location.
2. Edit the `dir_master=` line in `nfsiostat-collect.bash` to define your own location for the metrics store.
3. Check the setup via direct execution (the file should appear in the store)

```bash
./nfsiostat-collect.bash
```
4. Setup a `cron` job using `crontab -e`

```
MAILTO=""
* * * * * ./nfsiostat-collect.bash
```

## Setting up a slave

1. Define the hostname of the master server in `$master`

2. Generate a SSH key (you will be prompted if one already exists)

```bash
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
```

3. Register the SSH key on the master server

```bash
ssh-copy-id $master
```

4. Pull the `nfsiostat-collect.bash` script from the master server
```
scp $master:$location/nfsiostat-collect.bash .
```

5. Check the setup via direct execution (the file should appear in the store)

```bash
./nfsiostat-collect.bash $master
```

6. Setup a `cron` job using `crontab -e` (replace `$master` by its real content)

```
MAILTO=""
* * * * * ./nfsiostat-collect.bash $master
```

## Plots

`./nfsiostat-barplot.R [ DATE ]` will produce a barplot summarizing the metrics over all servers for the corresponding day (today if not specified).

`./nfsiostat-heatmap.R [ DATE ]` will produce a heatmap summarizing the metrics over all servers for the corresponding day (today if not specified).

`./nfsiostat-plot.R store/DATE_HOST.txt [ output.png ]`  will produce a barplot summarizing the metrics for a single day and server (file specified).

