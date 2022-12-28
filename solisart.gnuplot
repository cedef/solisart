set datafile separator ','
set xdata time
set timefmt "%Y-%m-%dT%H:%M:%S"


set key autotitle columnhead # use the first line as title
#set key outside;
set key left top
set key font ",14"
set key width 10
set format x "%d %b %H:%M"
set xtics rotate
set grid y

set term pngcairo size 1600, 1200
set output "/tmp/temperatures.png"

set xrange [xfrom:xto]

set yrange [0:100]
set ytics 5
set ylabel "°C"
plot for [i=2:8] inputfile using 1:i with lines lw 2 axes x1y1, \
     for [i=9:11] inputfile using 1:i with lines dashtype 4 lw 2 axes x1y1

set output "/tmp/circulateurs.png"
set ytics 10
set yrange [-5:125]
set ylabel "%"

plot for [i=12:19] inputfile using 1:i with lines lw 2
#
#set ylabel "On / Off"
#set yrange [-1:5]
#
#plot for [i=20:25] inputfile using 1:i with lines dashtype 3 lw 1 axes x1y1
