set datafile separator ';'
set xdata time
set timefmt "%d/%m/%y %H:%M"


set key autotitle columnhead noenhanced # use the first line as title
#set key outside;
set key left top
set key font ",14"
set key width 10
set format x "%d/%m/%y %H:%M"
set xtics rotate
set grid y

set term pngcairo size 1600, 1200
set output outtemp 

set xrange [xfrom:xto]
#set xrange ["31/12/22 00:00":"31/12/22 23:59"]

set yrange [0:100]
set ytics 5
set ylabel "°C"
#plot inputfile using 1:2 with lines lw 2 axes x1y1
#plot \
#    inputfile using 1:12 with lines lw 2 lt 1, \
#    inputfile using 1:10 with lines lw 2 lt 6 dashtype 4, \
#    inputfile using 1:4 with lines lw 2 lt 3, \
#    inputfile using 1:5 with lines lw 2 lt 7, \
#    inputfile using 1:6 with lines lw 2 lt 2, \
#    inputfile using 1:7 with lines lw 1 lt 8 dashtype 1, \
#    inputfile using 1:8 with lines lw 2 lt 4, \
#    inputfile using 1:9 with lines lw 1 lt 4, \
#    inputfile using 1:2 with lines lw 2 lt 5

plot \
    inputfile using 1:10 with lines lw 2 lt 6 dashtype 4, \
    inputfile using 1:4 with lines lw 2 lt 3, \
    inputfile using 1:2 with lines lw 2 lt 4
#plot for [i=2:8] inputfile using 1:i with lines lw 2, \
#     for [i=9:11] inputfile using 1:i with lines dashtype 4 lw 2, \
#     for [i in "12 16"] inputfile using 1:i with lines dashtype 2 lw 2

set output outcirc 
set ytics 10
set yrange [-5:125]
set ylabel "%"

#plot for [i in "24 25 27 28 31 32 33 34"] inputfile using 1:i with lines lw 2
#plot for [i in "24 25 27 28 31 32 33 34"] inputfile using 1:i with lines lw 2

#set ylabel "On / Off"
#set yrange [-1:5]

#plot for [i=20:25] inputfile using 1:i with lines dashtype 3 lw 1 axes x1y1
