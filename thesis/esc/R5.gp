#set terminal X11
#set output
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
#set ylabel ""
set xlabel "Time"
set key 
plot "R5.dat" u 1:2 w l ls 1 t "Customer demand", \
"" u 1:3 w l ls 2 t "Orders placed-MPC",\
"" u 1:4 w l ls 3 t "Orders placed-$(\\sigma,\\Sigma)$"
