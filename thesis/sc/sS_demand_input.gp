# set terminal x11 
# set output
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
set xlabel "Time"
set xtics 10
set ytics nomirror
set ytics 10
set ylabel "Order-Retailer"
#set key bottom right
unset key
plot "sS_demand_input.dat" u 1:2 w steps ls 1 t "Decentralized",\
"" u 1:4 w steps ls 2 t " Non Cooperative",\
"" u 1:6 w steps ls 3 t " Cooperative",\
"" u 1:8 w steps ls 4 t  "Centralized"

set size 0.525,0.6
set origin 0.525,0
unset ylabel
unset ytics
unset key
set xtics 10
set xlabel "Time"
set y2tics nomirror
set y2label "Production-Manufacturer"
set y2tics 10
plot "sS_demand_input.dat" u 1:3 w steps ls 1 axis x1y2,\
"" u 1:5 w steps ls 2 axis x1y2,\
"" u 1:7 w steps ls 3 axis x1y2,\
"" u 1:9 w steps ls 4 axis x1y2


