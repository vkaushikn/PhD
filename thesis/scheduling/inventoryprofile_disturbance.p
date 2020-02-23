#proc areadef
rectangle: 0 0.8 5 1.6
xrange: -1 26
yrange: 0 25

#proc xaxis
stubs: none
ticincrement: 4
axisline: width=1.2 color=black

#proc yaxis
label:  inventory 
stubs: inc 5	  
stubomit: 0
axisline: width=1.2 color=black

#proc getdata
file: STA.dat
	
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

#proc areadef
rectangle: 0 0 5 0.8
xrange: -1 26
yrange: 0 25

#proc xaxis
label:  time
stubs: inc 4
axisline: width=1.2 color=black

#proc yaxis
label:  back order 
stubs: inc 5	   
stubomit: 25
axisline: width=1.2 color=black

#proc getdata
file: BOA.dat
	    
#proc lineplot
xfield: 1
yfield: 2
linedetails: color=skyblue width=0.8
stairstep: yes
legendlabel: A-BO

#proc getdata
file: BOA.dat
select: @@2 == 0
	   
#proc lineplot
xfield: 1
yfield: 2
linedetails: color=black width=0.8
stairstep: yes

#proc getdata
file: BOB.dat

#proc lineplot
xfield: 1
yfield: 2
linedetails: color=redorange width=0.8
legendlabel: B-BO
stairstep: yes

#proc getdata
file: BOB.dat
select: @@2 == 0
	   
#proc lineplot
xfield: 1
yfield: 2
linedetails: color=black width=0.8
stairstep: yes

#proc legend
format: across
location:  3(s) 50(s)


			  
	   

    