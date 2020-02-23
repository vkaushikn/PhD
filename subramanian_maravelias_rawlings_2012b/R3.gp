
#set terminal x11
# set output
set style line 1 lt 1 lw 2
set style line 2 lt 3 lw 2
set style line 3 lt 2 lw 2
set style line 4 lt 4 lw 2
set style line 5 lt 5 lw 1
set size 1,0.6
set origin 0,0
set multiplot
set size 0.525,0.6
set origin 0,0
set ytics nomirror
set xtics 10 nomirror
set ytics 10
set xlabel "Time"
set xrange [-2:*]
set yrange [-2:15]
set key 
plot "R3.dat" u 1:2 w l ls 1  t "Inventory",\
"" u 1:4 w l ls 2 t "Backorder"
set size 0.525, 0.6
set origin 0.525,0
unset ylabel
unset ytics
set key horizontal samplen 2
#set key at first 7, second 14
set xtics 10
set y2tics nomirror
#set y2label "Backorder"
set y2tics 10
#set y2range [-1:5]
set xrange [-2:*]
set xlabel "Time"
plot "R5.dat" u 1:2 w l ls 1 axis x1y2 t "Customer demand",\
"" u 1:3 w l ls 2 axis x1y2 t "Orders placed"




