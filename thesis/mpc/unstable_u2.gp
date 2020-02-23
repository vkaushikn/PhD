# set terminal x11 
# set output
set style line 1 lt 4 lw 2
set style line 2 lt 5 lw 2
set style line 3 lt 2 lw 2
set style line 4 lt 1 lw 2
set style line 5 lt 6 lw 1
set size 1,0.5
set origin 0,0
set multiplot
set size 0.525,0.5
set origin 0,0
set xtics 10
set xlabel "Time"
set ytics nomirror
set ytics 2
set yrange [-0.5:*]
set ylabel "Tank-2 Cheap valve"
unset key
plot "unstable_u2.dat" u 1:5 w steps ls 2 t "Noncooperative",\
"" u 1:6 w steps ls 3 t "Cooperative",\
"" u 1:7 w steps ls 4 t  "Centralized"
set size 0.525,0.5
set origin 0.525,0
unset ylabel
unset ytics
unset key
set xtics 10
set xlabel "Time"
set y2range [-0.5:*]
set y2tics nomirror
set y2label "Tank-2 Expensive valve"
set y2tics 1
plot "unstable_u2.dat" u 1:2 w steps ls 2 notitle axis x1y2,\
"" u 1:3 w steps ls 3 axis x1y2,\
"" u 1:4 w steps ls 4 axis x1y2



