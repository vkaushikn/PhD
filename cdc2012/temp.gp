#!/usr/bin/gnuplot -persist
#
#    
#    	G N U P L O T
#    	Version 4.0 patchlevel 0
#    	last modified Thu Apr 15 14:44:22 CEST 2004
#    	System: Linux 2.4.27-2-k7
#    
#    	Copyright (C) 1986 - 1993, 1998, 2004
#    	Thomas Williams, Colin Kelley and many others
#    
#    	This is gnuplot version 4.0.  Please refer to the documentation
#    	for command syntax changes.  The old syntax will be accepted
#    	throughout the 4.0 series, but all save files use the new syntax.
#    
#    	Type `help` to access the on-line reference manual.
#    	The gnuplot FAQ is available from
#    		http://www.gnuplot.info/faq/
#    
#    	Send comments and requests for help to
#    		<gnuplot-info@lists.sourceforge.net>
#    	Send bugs, suggestions and mods to
#    		<gnuplot-bugs@lists.sourceforge.net>
#    
#set terminal x11 
# set output
#set xrange [0:90]
#set yrange [50:80]
set style line 1 linetype 1 linewidth 5.000 
set style line 2 linetype 2 linewidth 5.000
set style line 3 linetype 3 linewidth 5.000
set style line 4 linetype 4 linewidth 5.000
set style line 5 linetype 1 linewidth 5.000 pointtype 4
set style line 6 linetype 2 linewidth 5.000 pointtype 4
plot "data.dat" u 1:2 w l lt 1 lw 1 notitle




