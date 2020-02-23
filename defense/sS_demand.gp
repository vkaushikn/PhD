# set terminal x11 
# set output
set linestyle 1 lt 1 lw 3 lc 1
set linestyle 2 lt 1 lw 3 lc 3
set linestyle 3 lt 3  lw 3 lc 3
set linestyle 4 lt 3  lw 3 lc 1
set size 1,0.6
set origin 0,0
set multiplot
set size 0.525,0.6
set origin 0,0
set ytics nomirror
set xtics 10
set ytics 10
set ylabel "Inventory-Retailer"
set xlabel "Time"
set key horizontal samplen 1 at 50,54
#unset key
plot "sS_demand.dat"  u 1:4 w l ls 2 t "Ord",\
"IP_dem.dat" u 1:4 w l ls 3 t "IP",\
"sS_demand.dat" u 1:6 w l ls 4  notitle,\
"sS_demand.dat" u 1:8 w l ls 1  notitle

set size 0.525, 0.6
set origin 0.525,0
unset ylabel
unset ytics
set key horizontal samplen 1 at first 50, second 54
#set key at first 50, second 54
set xtics 10
set xlabel "Time"
set y2tics nomirror
set y2label "Inventory-Manufacturer"
set y2tics 10
plot "sS_demand1.dat" u 1:5 w l ls 2 axis x1y2 notitle,\
"IP_dem.dat" u 1:5 w l ls 3 axis x1y2 notitle,\
"sS_demand.dat" u 1:7 w l ls 4 axis x1y2 t "coop",\
"sS_demand1.dat" u 1:9 w l ls 1 axis x1y2 t "cent"

