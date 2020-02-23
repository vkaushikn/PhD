## set terminal
## set output

set key at -0.9, 0.2 left
set xrange [-1:1]
set yrange [-0.25:0.25]
set xlabel "$x_1$"
set ylabel "$x_2$" norot
plot "feasibility_set.dat" ind 0 u 1:2 w filledcurve fs solid 0.2 ti "$\\mathcal{X}_2$", \
"" ind 2 u 1:2 w l lt 2 ti "$\\bbD$", '-' w p lt 2 pt 6 ps 2 ti ""
0 0
