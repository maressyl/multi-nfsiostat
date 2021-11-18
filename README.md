# multi-nfsiostat

## Description

- The "master" and all "slave" servers run `nfsiostat` for 10 seconds every minute.
- The "master" server pulls the daily summary every night, or upon request.
- The "master" server plots summaries of NFS performances upon request.

## Install

1. Pull the repository in your home directory (or create a `multi-nfsiostat` symlink there pointing to the desired location).
2. List in `setup/hosts.txt` all servers to collect data from (possibly including the master), one IP or hostname per line.
3. Set in `setup/target.txt` the mountpoint to monitor (without endline character).
4. Optionnaly update the "Custom configuration" section in `setup/remote-setup.bash` if slaves require specific proxy settings to pull from Github.
5. Check the setup via direct execution (files should appear in `store/nfs` and `store/df`)

```bash
./collect.bash df
```

6. Run `./setup.bash` to deploy on slaves.

## Plots

`./nfsiostat-barplot.R [ DATE ]` will produce a barplot summarizing the metrics over all servers for the corresponding day (today if not specified).

`./nfsiostat-heatmap.R [ DATE ]` will produce a heatmap summarizing the metrics over all servers for the corresponding day (today if not specified).

`./nfsiostat-plot.R store/DATE_HOST.txt [ output.png ]`  will produce a barplot summarizing the metrics for a single day and server (file specified).
