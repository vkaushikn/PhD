#set terminal x11 
# set output
set style line 1 lt 1 lw 2 lc rgb "red"
set style line 2 lt 1 lw 2 lc rgb "blue"
set style line 3 lt 2 lw 2
set style line 4 lt 1 lw 2
set style line 5 lt 6 lw 1
set size 1,0.6
set origin 0,0
set key
set xtics 10
set ytics nomirror
set ytics 10
set yrange [-0.5:100]
set ylabel "Backorder -Retailer"
set xlabel "Time"
plot "BOprofile.dat" u 1:4 w l ls 1 t "Without terminal constraint",\
"" u 1:5 w l ls 2 t "With terminal constraint"



