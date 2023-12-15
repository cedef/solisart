#!/bin/bash

INPUT=$1
FROM_TIME="${2:-2 hour ago}"
TO_TIME="${3:-now}"

OUTTEMP="${4:-/tmp/temperatures.html}"
#OUTCIRC="${5:-/tmp/circulateurs.png}"

usage() {
    echo "
Usage:
    $(basename $0) input-csv-file start end-date

Example:
    ~/tmp/solisart/solisart.csv 2023-08-20 2023-08-27
    "

}

if [ "$1" = "-h" -o "$1" = "--help" ]
then
    usage
    exit 2
fi

echo "
Plotting $INPUT from $FROM_TIME to $TO_TIME. Output written to $OUTTEMP
"

echo gnuplot -e "xfrom='$(date +"%d/%m/%y %H:%M" -d "${FROM_TIME}")'; \
            xto='$(date +"%d/%m/%y %H:%M" -d "${TO_TIME}")'; \
            inputfile='${INPUT}'; \
            outtemp='${OUTTEMP}'; \
            outcirc='${OUTCIRC}'" -p $(dirname $0)/solisart.gnuplot

gnuplot -e "xfrom='$(date +"%d/%m/%y %H:%M" -d "${FROM_TIME}")'; \
            xto='$(date +"%d/%m/%y %H:%M" -d "${TO_TIME}")'; \
            inputfile='${INPUT}'; \
            outtemp='${OUTTEMP}'; \
            outcirc='${OUTCIRC}'" -p $(dirname $0)/solisart.gnuplot
