#proc getdata
file: TS_gantt.dat


#proc areadef
rectangle: 0 0 5 0.8
          xrange: 0 50
          yscaletype: categories
          ycategories: datafield 1
	  frame: yes

#proc xaxis
          label: time
          stubs: inc 4
          tics: none  

#proc yaxis
          stubs: categories


#proc legendentry
sampletype: color
label: TB
details: gray(0.8)
tag: gray(0.8)
	  
#proc legendentry
sampletype: color
label: TA
details: gray(0.9)
tag: gray(0.9)



#proc bars 
          horizontalbars: yes
          axis: x
          locfield: 1
          segmentfield: 2 3
          exactcolorfield: 4
          labelfield: 5
	  barwidth: 0.2
	  labelmustfit: truncate
          truncate: yes


#proc legend
format: across
	  location:  10(s) 0.8
  
