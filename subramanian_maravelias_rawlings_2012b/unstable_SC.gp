#set terminal x11 
# set output
set size 1,0.6
set origin 0,0
unset key
set xtics 40 nomirror
set ytics 500 nomirror
set yrange [-10:2000]
set ylabel "Backorder -Retailer"
set xlabel "Time"
plot "unstable_SC.dat" u 1:2 w l



