#set terminal X11
#set output
set boxwidth 0.75 absolute
set style fill pattern 2 
#solid 1.00 border -1
set style histogram clustered gap 2 title offset character 0,0,0
set datafile missing '-'
set style data histograms
set key  below
set xtics nomirror rotate by -45
set ylabel "Standard deviation of Orders"
#unset xlabel
set yrange [0:2]
plot 'bullwhip.dat' index 0  using 2:xtic(1) ti col, '' u 3 ti col
