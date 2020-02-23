#set terminal x11
# set output
set style line 1 lt 1 lw 2
set style line 2 lt 3 lw 2
set style line 3 lt 2 lw 2
set style line 4 lt 4 lw 2
set style line 5 lt 6 lw 1
set size 1,0.6
set origin 0,0
set multiplot
set size 0.525,0.6
set origin 0,0
set ytics nomirror
set xtics 2
set ytics 10
set ylabel "Inventory"
set xlabel "Time"
set key at first 7, first 35
set key horizontal samplen 2
set label "$\\omega = 0.8$" at first 8, first 15
#unset key
plot "CL8.dat" u 1:2 w l ls 1  notitle, \
"" u 1:3 w l ls 2 notitle
set size 0.525, 0.6
set origin 0.525,0
unset ylabel
unset ytics
unset label
set key horizontal samplen 2
set key at first 7, second 14
set xtics 2
set y2tics nomirror
set y2label "Inventory"
set y2tics 10
set xlabel "Time"
plot "CL8.dat" u 4:5 w l ls 1 axis x1y2 notitle,\
"" u 4:6 w l ls 2 axis x1y2  notitle



