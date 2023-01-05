#!/bin/bash

INPUT=$1
FROM_TIME="${2:-2 hour ago}"
TO_TIME="${3:-now}"

OUTTEMP="${4:-/tmp/temperatures.png}"
OUTCIRC="${5:-/tmp/circulateurs.png}"


gnuplot -e "xfrom='$(date +"%d/%m/%y %H:%M" -d "${FROM_TIME}")'; \
            xto='$(date +"%d/%m/%y %H:%M" -d "${TO_TIME}")'; \
            inputfile='${INPUT}'; \
            outtemp='${OUTTEMP}'; \
            outcirc='${OUTCIRC}'" -p $(dirname $0)/solisart.gnuplot
