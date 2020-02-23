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
set ytics nomirror
set xtics 10
set ytics 10
set xrange [0:30]
set ylabel "Inventory at Retailer"
set xlabel "Time"
set key horizontal bottom
#set key horizontal samplen 2
#unset key
plot "CL2.dat" index 0 u 1:2 w l ls 1  t "Actual",\
"" index 0 u 1:3 w points t "Nominal"
set size 0.525, 0.6
set origin 0.525,0
unset ylabel
unset ytics
set key horizontal top
set xtics 5
set xrange [0:30]
set xlabel "Time"
set y2tics nomirror
set y2label "Cost"
#set y2tics 100
set label "$\\times 10^{5}$" at graph 1.2,1
plot "CL2.dat" index 1 u 1:($2/100000) w l ls 1 axis x1y2 t "$V_N^\\beta(x,\\tilde{\\mathbf{v}})$",\
"" index 1 u 1:($3/100000) w l ls 3 axis x1y2 t "$V_N^\\beta(z,\\tilde{\\mathbf{v}})$",\
"" index 1 u 1:($4/100000) w l ls 4 axis x1y2 t "$\\bar{V}$"

