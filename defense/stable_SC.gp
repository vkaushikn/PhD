 set terminal x11
# set output
set style line 1 lt 1 lw 3 lc rgb "red"
set style line 2 lt 1 lw 3 lc rgb "blue"
set style line 3 lt 1 lw 3
set style line 4 lt 1 lw 3
set style line 5 lt 1 lw 1
set size 1,0.6
set origin 0,0
set origin 0,0
set ytics nomirror
set xtics 2
set ytics 10
set ylabel "Inventory"
set xlabel "Time"
set xrange [0:10]
set yrange [-2:30]
#set key at first 7, first 35
#set key horizontal samplen 2
#unset key
plot "stable_SC.dat" u 1:2 w l ls 1 t "Retailer",\
"" u 5:6 w l ls 2 t "Manufacturer"




