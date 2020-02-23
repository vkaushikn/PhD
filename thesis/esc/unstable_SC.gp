#set terminal x11 
# set output
set style line 1 lt 4 lw 2
set style line 2 lt 5 lw 2
set style line 3 lt 2 lw 2
set style line 4 lt 1 lw 2
set style line 5 lt 6 lw 1
set size 1,0.6
set origin 0,0
set key horiz samplen 2 noreverse spacing 1 width 0
set key at first 30, second 3
set xtics 50
set ytics nomirror
set ytics 250
set yrange [-10:2000]
set ylabel "Backorder -Retailer"
set xlabel "Time"
plot "unstable_SC.dat" u 1:2 w l ls 2 notitle;



