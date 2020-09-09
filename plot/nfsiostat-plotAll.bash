#!/bin/bash

### Plot all pulled log files
### Meant to be called manually

# Dates with log files
dates=$(ls ../pull/ | sed -r 's/_.+$//' | sort | uniq)

for date in $dates
do
   echo $date
   if [ ! -f "nfsiostat-barplot_$date.png" ] || [ $date == $(date +'%Y-%m-%d') ]; then ./nfsiostat-barplot.R $date; fi
   if [ ! -f "nfsiostat-heatmap_$date.png" ] || [ $date == $(date +'%Y-%m-%d') ]; then ./nfsiostat-heatmap.R $date; fi
done
