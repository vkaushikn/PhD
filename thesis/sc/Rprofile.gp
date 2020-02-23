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
set xtics 1
set ytics nomirror
#set ytics 20
#set yrange [27.9:30.1]
set ylabel "Inventory-R1"
#set key horizontal
#set key at first 50, first 70 samplen 2
#unset key
set xlabel "Time"
set key
plot "Sequential.dat" index 6 u 1:2 w l ls 1 notitle,\
"" index 6 u 1:3 w l ls 2 notitle,\
"" index 6 u 1:4 w l ls 3 notitle

set size 0.525,0.6
set origin 0.525,0
unset ylabel
unset ytics
set xtics 1
set y2tics nomirror
set y2label "Inventory-R2"
set xlabel "Time"
set key top
plot "Sequential.dat" index 7 u 1:2 w l ls 1 axis x1y2 t "cent",\
"" index 7 u 1:3 w l ls 2 axis x1y2 t "GSJ",\
"" index 7 u 1:4 w l ls 3 axis x1y2 t "Jacobi"



