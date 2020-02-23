#proc getdata
file: gantt_Periodic.dat


#proc areadef
rectangle: 0 0.8 5 1.6 
xrange: 0 22
yscaletype: categories
ycategories: datafield 1

#proc xaxis
//       label: time
          stubs: inc 1
//          grid: color=powderblue style=2
          
          tics: none  
          stubhide: yes
#proc yaxis
          stubs: categories

#proc bars 
          horizontalbars: yes
          axis: x
          locfield: 1
          segmentfield: 2 3
          exactcolorfield: 5
          labelfield: 4
	  barwidth: 0.2
          labelmustfit: truncate
          truncate: yes
#proc line
points: 0(s) min  0(s) max

linedetails: color=powderblue style=2

       
#proc line
points: 3(s) min  3(s) max

linedetails: color=powderblue style=2


#proc line
points: 6(s) min  6(s) max

linedetails: color=powderblue style=2   
			  
#proc line
points: 8(s) min  8(s) max

linedetails: color=powderblue style=2

	   
#proc line
points: 10(s) min  10(s) max

linedetails: color=powderblue style=2

#proc line
points: 11(s) min  11(s) max

linedetails: color=powderblue style=2


#proc line
points: 13(s) min  13(s) max

linedetails: color=powderblue style=2
	
	
#proc line
points: 15(s) min  15(s) max

linedetails: color=powderblue style=2	
	  
#proc line
points: 17(s) min  17(s) max

linedetails: color=powderblue style=2  

#proc line
points: 20(s) min  20(s) max

linedetails: color=powderblue style=2 


	

#proc line
points: 0(s) min  0(s) max

linedetails: color=redorange style=2	
#proc line
points: 19(s) min  19(s) max

linedetails: color=redorange style=2

#proc getdata
         file: iprofile_Periodic.dat

#proc areadef
	  rectangle: 0 0 5 0.8
	  xrange: 0 22
	  yrange: 0 25

#proc xaxis
           label:  time
	   selflocatingstubs: datafields 1 4
	   stubomit:  1 2 3 5 6 7 9 10 11 13 14 15 17 18  22
       
#proc yaxis
           label:  inventory 
	   stubs: inc 5

#proc lineplot
	   xfield: 1
	   yfield: 2

	   linedetails: color=blue
           legendlabel:	A
	   stairstep: yes

#proc lineplot
	   xfield: 1
	   yfield: 3
      
	   linedetails: color=red
           legendlabel:	B
	   stairstep: yes

#proc line
points: 0(s) min  0(s) max

linedetails: color=powderblue style=2

       
#proc line
points: 3(s) min  3(s) max

linedetails: color=powderblue style=2


#proc line
points: 6(s) min  6(s) max

linedetails: color=powderblue style=2   
			  
#proc line
points: 8(s) min  8(s) max

linedetails: color=powderblue style=2

	   
#proc line
points: 10(s) min  10(s) max

linedetails: color=powderblue style=2

#proc line
points: 11(s) min  11(s) max

linedetails: color=powderblue style=2


#proc line
points: 13(s) min  13(s) max

linedetails: color=powderblue style=2
	
	
#proc line
points: 15(s) min  15(s) max

linedetails: color=powderblue style=2	
	  
#proc line
points: 17(s) min  17(s) max

linedetails: color=powderblue style=2  

#proc line
points: 20(s) min  20(s) max

linedetails: color=powderblue style=2	


	

#proc line
points: 0(s) min  0(s) max

linedetails: color=redorange style=2	
#proc line
points: 19(s) min  19(s) max

linedetails: color=redorange style=2	

//{ #proc line }
//		      { points:  min 1.5(s)   max 1.5(s) }

//{ linedetails: color=lightorange style=2 }

//{ #proc line }
//{ points:  min 16.5(s)   max 16.5(s) }

//{ linedetails: color=lightorange style=2 }


#proc legend
           format: across
           location:  8(s) 50(s)


			  
	   

