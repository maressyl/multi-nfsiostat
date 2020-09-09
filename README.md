# multi-nfsiostat

## Description

### Slave servers

Two cron tasks run each minute on each slave server :

* `./nfsiostat-collect.bash` runs `nfsiostat` during 30 seconds and prints the result in both a `.send` file and a daily aggregate stored locally.
* `./nfsiostat-push.bash` exposes on the requested TCP port all local `.send` files (one by one, until all are sent or until the first timeout). The script is blocked during the exposition until the master server queries the slave, or until time runs out (30 seconds). Once the `.send` file collected by the master, it is removed from the slave server.

### Master server

Aside the two server cron tasks, one extra task running each minute :

* `./nfsiostat-pull.bash` queries one by one all slave servers (one per second at most), in two nested loops. If the queried slave server is proposing a `.send` file, it is downloaded and appended to the daily aggregate of the corresponding server in the "pull" directory.

## Manual operations

### Force the collection

`.send` files can accumulate on slave servers in case of network problems. `./nfsiostat-magnet.bash` will try to collect all pending files in all slave server (infinite loop to kill manually).

### Plot data

Two R scripts for data representation are available in "plot". They are expected to be run from the terminal in the "plot" directory, they collect data files in "../pull".

Without argument, they plot the data corresponding to the current day. A date can be passed with the YYYY-MM-DD format to plot a specific day.

`plot/nfsiostat-plotAll.bash` will plot both heatmaps and barplots for all days with available data, skipping days which were already plotted.
