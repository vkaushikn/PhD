## set terminal
## set output

set key at -0.8, 0.1 left
set xrange [-1:1]
set yrange [-0.25:0.25]
#set label 1 "$\\mathcal{X}_1$" at -0.05, 0.175 right
#set label 2 "$\\mathcal{X}_2$" at -0.05, 0.1 right
set label 3 "$\\mathcal{X}_3=\\bbR^2$" at -0.74, 0.125 left
set xlabel "$x_1$"
set ylabel "$x_2$" norot
plot "feasibility_set.dat" \
ind 0 u 1:2 w filledcurve fs solid 0.2 lt 1 ti "$\\mathcal{X}_2$", \
"" ind 1 u 1:2 w l lt 2 ti "$\\mathcal{X}_1$"


