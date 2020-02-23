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
set key horiz samplen 2 noreverse spacing 1 width 0
set key at first 30, second 3
set origin 0,0
set xtics 10
set ytics nomirror
set ytics 0,5,20
set yrange [0:10]
set ylabel "Level -1"
plot "unstable_x.dat" u 1:2 w l ls 2 t "ncoop",\
"" u 1:3 w l ls 3 t "coop",\
"" u 1:4 w l ls 4 t  "cent"

set size 0.525,0.5
set origin 0.525,0
unset ylabel
unset ytics
unset key
set y2tics nomirror
set y2label "Level-2"
set y2tics 0,5,20
set y2range [0:10]
plot "unstable_x.dat" u 1:5 w l ls 2 axis x1y2,\
"" u 1:6 w l ls 3 axis x1y2,\
"" u 1:7 w l ls 4 axis x1y2



