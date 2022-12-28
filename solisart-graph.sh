#!/bin/bash

INPUT=$1
OUTPUT=$2

gnuplot -e "xfrom='$(date +%FT%H:%M:%S -d '2 hour ago')'; xto='$(date +%FT%H:%M:%S)'; inputfile='${INPUT}'" -p $(dirname $0)/solisart.gnuplot > ${OUTPUT}
