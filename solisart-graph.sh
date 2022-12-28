#!/bin/bash

INPUT=$1
OUTPUT_DIR=$2

FROM_TIME="${3:-2 hour ago}"
TO_TIME="${4:-now}"

gnuplot -e "xfrom='$(date +%FT%H:%M:%S -d "${FROM_TIME}")'; \
    xto='$(date +%FT%H:%M:%S -d "${TO_TIME}")'; \
    inputfile='${INPUT}'; \
    outputdir='${OUTPUT_DIR}'" -p $(dirname $0)/solisart.gnuplot
