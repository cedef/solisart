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

#set term pngcairo size 1600, 1200
set term canvas size 1600, 1200
set output outtemp

set xrange [xfrom:xto]

#set multiplot
set multiplot layout 6,1
#set multiplot title "SolisArt Installation"


set yrange [-5:125]
set ylabel "%"

unset xlabel
unset xtics

set grid x
set style histogram cluster gap 1
set style fill solid border -1
set boxwidth 0.9

plot \
    inputfile using 1:24 with lines lw 2 lt 3, \
           '' using 1:31 with lines lw 2 lt 1, \
           '' using 1:32 with lines lw 2 lt 2, \
           '' using 1:34 with lines lw 2 lt 3, \
           '' using 1:35 with lines lw 2 lt 4, \
           '' using 1:36 with lines lw 2 lt 5, \
           '' using 1:44 with lines lw 2 lt 6, \
           '' using 1:45 with lines lw 2 lt 7, \
           '' using 1:25 with lines lw 2 lt 8

#set style lines

set yrange [0:100]
set ytics 5
set ylabel "°C"
#set xlabel ""

#set y2range [-5:125]
#set y2label "%"
set format x "%d/%m/%y %H:%M"
set xtics rotate


set bmargin at screen 0.10
plot \
    inputfile using 1:10 with lines lw 2 lt 6, \
           '' using 1:4 with lines lw 3 lt 3 dashtype 3, \
           '' using 1:5 with lines lw 3 lt 7 dashtype 3,  \
           '' using 1:12 with lines lw 2 lt 1, \
           '' using 1:6 with lines lw 2 lt 2, \
           '' using 1:8 with lines lw 1 lt 6 dashtype 5, \
           '' using 1:9 with lines lw 1 lt 7 dashtype 5, \
           '' using 1:2 with lines lw 2 lt 4

#set size 1,0.20

