set datafile separator ','
set xdata time
set timefmt "%Y-%m-%dT%H:%M:%S"

set key autotitle columnhead # use the first line as title
set key outside;
set key right top;
#set term pbm size 1024, 768
set term canvas size 1600, 900
#set size 0.5, 0.5
set format x "%d %b %H:%M"
set xtics rotate
set grid y2

set yrange [0:100]

set y2tics 5 nomirror
set ytics 20 nomirror

set ylabel "Pourcentages"
set y2label "Temperatures"
set xlabel 'Date'

set xrange [xfrom:xto]

plot for [i=2:8] inputfile using 1:i with lines lw 2 axes x1y2, \
     for [i=9:11] "" using 1:i with lines dashtype 4 lw 2 axes x1y2, \
     for [i=12:18] "" using 1:i with lines dashtype 3 lw 1 axes x1y1
