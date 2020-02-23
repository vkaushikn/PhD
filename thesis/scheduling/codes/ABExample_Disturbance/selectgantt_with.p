#proc getdata
file: selectgantt.dat


#proc areadef
          rectangle: 0 0 5 5
          xrange: 0 42
          yscaletype: categories
          ycategories: datafield 1
	  //frame: yes

#proc xaxis
          label: Time
          stubs: inc 4
          tics: none  

#proc yaxis
          stubs: categories

	
#proc legendentry
sampletype: color
label: TA
details: blue
tag: blue
	  
#proc legendentry
sampletype: color
label: TB
details: red
tag: red



#proc legendentry
sampletype: color
label: Delay
details: lavender
tag: lavender

#proc legendentry
sampletype: color
label: Breakdown
details: gray(0.8)
tag: gray(0.8)

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
location:  3(s) 5

#proc annotate
text: 1 hour delay observed

textdetails: size=8

location: 19(s) t=9(s)+0.65

#proc annotate
text: 3 hour breakdown observed

textdetails: size=8
location: 17(s) t=13(s)+0.65

#proc annotate
text: Loading error observed

     textdetails: size=8    
location: 34(s) t=15(s)+0.65

#proc annotate
text: Demand spike observed

textdetails: size=8
location: 36(s) t=16(s)+0.65

     
  
