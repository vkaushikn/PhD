#proc getdata
file: schedule.dat

#proc areadef
rectangle: 0 0.8 5 1.6
xrange: 0 30
yscaletype: categories
ycategories: datafield 1
//frame: yes

#proc xaxis
//label: time
//stubs: inc 4
tics: none  
axisline: none

#proc yaxis
stubs: categories
axisline: none

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
location:  12(s) 1.5
  
#proc areadef
rectangle: 0 0 5 0.8
xrange: 0 30
yrange: 0 30

#proc xaxis
stubs: inc 4
label: Time
axisline: width=1.2 color=black

#proc yaxis
label:  Inventory 
stubs: inc 5	  
stubomit: 0
axisline: width=1.2 color=black

#proc getdata
file: STA.dat
select: @@1 >= 0
	
#proc lineplot
xfield: 1
yfield: 2
linedetails: color=blue width=0.8

legendlabel: A-Inv
stairstep: yes

// To remove inv = 0 data
#proc getdata
file: STA.dat
select: @@2 == 0
	   
#proc lineplot
xfield: 1
yfield: 2
linedetails: color=black width=0.8
stairstep: yes
	   
#proc getdata
file: STB.dat
select: @@1 >= 0

#proc lineplot
xfield: 1
yfield: 2
linedetails: color=red width=0.8
legendlabel: B-Inv
stairstep: yes

#proc getdata
file: STB.dat
select: @@2 <= 0.1
	   
#proc lineplot
xfield: 1
yfield: 2
linedetails: color=black width=0.8
stairstep: yes


#proc legend
format: across
location:  12(s) 1.5