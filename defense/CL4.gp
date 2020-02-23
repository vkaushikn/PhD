 set terminal x11
# set output
set style line 1 lt 1 lw 3 lc 1
set style line 2 lt 1 lw 3 lc 3
set style line 3 lt 1 lw 3
set style line 4 lt 1 lw 3
set style line 5 lt 1 lw 1
set size 1,0.6
set origin 0,0
set multiplot
set size 0.525,0.6
set origin 0,0
set ytics nomirror
set xtics 5
set ytics 10
set ylabel "Retailer-Inventory"
set xlabel "Time"
#set key at first 15, first 35
set key horizontal samplen 2
#unset key
plot "CL4.dat" u 1:2 w l ls 1  t "Multiobjective" , \
"" u 1:3 w l ls 2  t "Tracking"
set size 0.525, 0.6
set origin 0.525,0
unset ylabel
unset ytics
set key horizontal samplen 2
#set key at first 15, second 3
set xtics 5
set y2tics nomirror
set y2label "Manufacturer-Inventory"
set y2tics 10
set xlabel "Time"
plot "CL4.dat" u 4:5 w l ls 1 axis x1y2 notitle,\
"" u 4:6 w l ls 2 axis x1y2 notitle



