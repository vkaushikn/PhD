#set terminal x11 
#set output
set style line 1 lt 4 lw 2
set style line 2 lt 5 lw 2
set style line 3 lt 2 lw 2
set style line 4 lt 1 lw 2
set style line 5 lt 6 lw 1
set size 1,0.6
set origin 0,0
set multiplot
set size 0.525,0.6
set origin 0,0
set ytics nomirror
set xtics 1
set ytics 10
set ylabel "Inventory"
set xlabel "$\\omega$"
set xrange [0:1]
set yrange [-2:40]
set key 
#unset key
plot "SS_omega.dat" u 1:2 w l ls 1 t "Retailer"
set size 0.525, 0.6
set origin 0.525,0
unset ylabel
unset ytics
set key 
set xtics 1
set y2tics nomirror
set y2label "Inventory"
set y2tics 10
set xrange [0:1]
set xlabel "$\\omega$"
set y2range [-2:45]
plot "SS_omega.dat" u 1:3  w l ls 2 axis x1y2 t "Manufacturer"



