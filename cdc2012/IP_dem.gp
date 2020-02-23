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
set xtics 10
set ytics nomirror
set ytics 20
set yrange [*:60]
set ylabel "Inventory-Retailer"
set key horizontal
set key at first 50, first 70 samplen 2
#unset key
plot "IP_dem.dat" u 1:2 w l ls 1 t "dec",\
"" u 1:4 w l ls 2 t "ncoop",\
"" u 1:6 w l ls 3 notitle ,\
"" u 1:8 w l ls 4 notitle 
#"" u 1:10 w l lt 5 notitle
set size 0.525,0.6
set origin 0.525,0
unset ylabel
unset ytics
set key horiz
set key at first 50, second 53 samplen 2
set xtics 10
set y2tics nomirror
set y2label "Inventory-Manufacturer"
set y2tics 10
plot "IP_dem.dat" u 1:3 w l ls 1 axis x1y2 notitle,\
"" u 1:5 w l ls 2 axis x1y2 notitle,\
"" u 1:7 w l ls 3 axis x1y2 t "coop",\
"" u 1:9 w l ls 4 axis x1y2 t "cent"
#"" u 1:11 w l lt 5  notitle

