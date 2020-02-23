# set terminal x11 
# set output
set clip one
unset clip two
set bar 1.000000
set border 31 front linetype -1 linewidth 1.000 
set xdata
set ydata
set zdata
set x2data
set y2data
#set style fill solid 0.1  border
set style rectangle back fc lt -3 fillstyle  solid .5 border -1
set dummy x,y
set format x "% g"
set format y "% g"
set format x2 "% g"
set format y2 "% g"
set format z "% g"
set format cb "% g"
set xzeroaxis linetype -1 linewidth 1.000 
set yzeroaxis linetype -1 linewidth 1.000 
set zzeroaxis linetype -2 linewidth 1.000 
set x2zeroaxis linetype -2 linewidth 1.000 
set y2zeroaxis linetype -2 linewidth 1.000 
set xlabel "Inventory-Retailer"
set ylabel "Inventory-Manufacturer" 
GNUTERM = "wxt"
plot "Xf4.dat"u 1:2 w filledcu lt -1 fs solid 0.2 notitle


