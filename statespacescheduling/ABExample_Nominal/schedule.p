#proc getdata
file: schedule.dat


#proc areadef
rectangle: 0 0 5 0.8
          xrange: 0 30
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
details: red
tag: red

#proc legendentry
sampletype: color
label: TA
details: blue
tag: blue

#proc legendentry
sampletype: color
label: Setup
details: lightorange
tag: lightorange

#proc legendentry
sampletype: color
label: Setup
details: skyblue
tag: skyblue

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
	  location:  12(s) 0.8
  
