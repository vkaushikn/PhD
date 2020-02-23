# set terminal x11 
# set output
set style line 1 lt 4 lw 2
set style line 2 lt 5 lw 2
set style line 3 lt 2 lw 2
set style line 4 lt 1 lw 2
set style line 5 lt 6 lw 1

set size 1,0.6
set origin 0,0
set xtics 2
set xlabel "Time"
set ytics nomirror
#set ytics 20
#set yrange [27.9:30.1]
set ylabel "log $(V_N^\\beta(\\cdot))$"
#set xrange [0:10]
#set key horizontal
#set key at first 50, first 70 samplen 2
#unset key
set key
plot "Sequential.dat" index 1 u 1:(log($2)) w l ls 1 t "cent",\
"" index 1 u 1:(log($5)) w l ls 2 t "GSJ",\
"" index 1 u 1:(log($4)) w l ls 3 t "Jacobi"

