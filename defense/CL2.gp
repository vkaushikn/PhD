# set terminal x11 
# set output
set style line 1 lt 4 lw 2
set style line 2 lt 5 lw 2
set style line 3 lt 2 lw 2
set style line 4 lt 1 lw 2
set style line 5 lt 6 lw 1
set size 1,0.6
set origin 0,0
set ytics nomirror
set xtics 10
set ytics 10
set xrange [0:30]
set ylabel "Inventory at Retailer"
set xlabel "Time"
set key horizontal bottom
#set key horizontal samplen 2
#unset key
set arrow from 14,32.765 to 20,25
set label "Nominal state reset" at 20,25
plot "CL2.dat" index 0 u 1:2 w l ls 1  t "Actual",\
"" index 0 u 1:3 w points t "Nominal"


