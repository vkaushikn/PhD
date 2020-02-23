"""Inteface with LSSC.gms to run rolling horizon MPC for the supply
chain. 
LSSC.gms is a file for a 5 node supply chain.
There are two produces, A and B
The manufacturer is assumed to have 2 units, one for the production of
A and one for the production of B 
All the parameters are to be entered using this script. Dictionaries
control all the parameters, connections between nodes etc. 
"""
import os
import csv
from network import *


#Write the sets file for GAMS
def makesetstring(s1,list1):
    s1 =s1+' /'
    for l in list1:
        s1+= l+','
    s1 = s1.rstrip(',')+'/ \n'
    return s1

#returns a string enclosed by ' '
strq = lambda strwq: '\''+strwq+'\''


#Parameters initial strings
par0 = 'PARAMETERS \n'
par0+= 'DN(s,n,n1) if n ships s to n1 \n'
par0+= 'UP(s,n,n1) if n orders s to n1 \n'
par0+= 'tau(s,n,n1) Transportation delay for s from n to n1;\n'

cost0 = 'PARAMETERS \n'
cost0+= 'EHoldingCost(s,n) \n'
cost0+= 'EBackOrderCost(s,n) \n'
cost0+= 'EShippingCost(s,n,n1) \n'
cost0+= 'EOrderingCost(s,n,n1) \n'
cost0+= 'THoldingCost(s,n) \n'
cost0+= 'TBackOrderCost(s,n) \n'
cost0+= 'TShippingCost(s,n,n1) \n'
cost0+= 'TOrderingCost(s,n,n1); \n'

const0 = 'PARAMETERS \n'
const0+= 'InvUP(n) Maximum inventory (combined) in node;\n'

targ0 = 'PARAMETERS \n'
targ0+= 'invT(s,n) \n'
targ0+= 'ordT(s,n) \n'
targ0+= 'shipT(s,n,n1) \n'
targ0+= 'orderT(s,n,n1); \n'

ss0 = 'PARAMETERS \n'
ss0+= 'InvSS(s,n) \n'
ss0+= 'BOSS(s,n,n1) \n'
ss0+= 'ShipBarSS(s,n,n1,tbar) \n'
ss0+= 'OrderBarSS(s,n,n1,tbar);\n'

weight0 = 'PARAMETERS \n'
weight0+= 'eco \n'
weight0+= 'track \n'
weight0+= 'sE \n'
weight0+= 'sT; \n' 

init0 = ''
init0+= 'PARAMETERS \n'
init0+= 'Inv0(s,n) \n'
init0+= 'BO0(s,n,n1) \n'
init0+= 'ShipBar0(s,n,n1,tbar) \n'
init0+= 'OrderBar0(s,n,n1,tbar); \n'

#Common Parameter files for both dynamic and steady state problems
#.network,.costs, .constraints

#network
up_conn = ''
dn_conn = ''
delay_str = ''

for s in Products:
    for noc in range(len(Connection[s])):
        ship_from = Connection[s][noc][0]
        ship_to = Connection[s][noc][1]
        delay = str(Connection[s][noc][2])
        dn_conn+=\
            'DN('+strq(s)+','+strq(ship_from)+','+strq(ship_to)+')=1;\n' 
        up_conn+=\
            'UP('+strq(s)+','+strq(ship_to)+','+strq(ship_from)+')=1;\n'
        delay_str+=\
            'tau('+strq(s)+','+strq(ship_from)+','+strq(ship_to)+')='+\
            delay+ ';\n'        
    for m in Manufacturer:
        delay = str(Prod_Lead_Time['A'][m])
        delay_str+=\
            'tau('+strq(s)+','+strq(m)+','+strq(m)+')='+delay+';\n'
f = open('LSSC.network','w')
f.write(par0+up_conn+dn_conn+delay_str)
f.close()
tmp_files = ['LSSC.network']

#costs
coststr = ''

for s in Products:
    for var in CostList:
        Cname = locals()[var] #make a copy of the corrsponding cost vector
        for noc in range(len(Cname[s])):
            ship_from = Cname[s][noc][0]
            ship_to = Cname[s][noc][1]
            costval = str(Cname[s][noc][2])
            print ship_from
            print ship_to
            print costval
            coststr+=\
                var+'('+strq(s)+','+strq(ship_from)+','+strq(ship_to)+')='\
                +costval+';\n' 
    for var in CostList0:
        Cname = locals()[var]
        for n in Nodes:
            costval = str(Cname[s][n])
            coststr+=\
                var+'('+strq(s)+','+strq(n)+')='+costval+';\n'
f = open('LSSC.costs','w')
f.write(cost0+coststr)
f.close()
tmp_files.append('LSSC.costs')

#constraints
inv_up = ''
for s in Products:
    for n in Nodes:
        up = str(invUP[n])
        inv_up+='InvUP('+strq(n)+')='+up+';\n'
f = open('LSSC.constraints','w')
f.write(const0+inv_up)
f.close()
tmp_files.append('LSSC.constraints')

#state-targets
starg_str = ''
for s in Products:
    for n in Nodes:
        starg = str(invT[s][n])
        starg_str+='invT('+strq(s)+','+strq(n)+')='+starg+';\n'
        starg = str(ordT[s][n])
        starg_str+='ordT('+strq(s)+','+strq(n)+')='+starg+';\n'




############STEADY STATE PROBLEM##################################### 

#nominal demand
dem0 = 'PARAMETER Dem(s,r) ;\n'
dem =  ''
for s in Products:
    for r in Retailer:
        demstr = str(Nominal_Demand[s][r])
        dem+=\
            'Dem('+strq(s)+','+strq(r)+')='+demstr+';\n'
f = open('LSSC.nominal','w')
f.write(dem0+dem)
f.close()
tmp_files.append('LSSC.nominal')

##Create the steady state files
# Sets:
sets = 'SETS \n'
sets1 = 'tbar For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tbar+1)])
sets1 = 's Materials'
sets+= makesetstring(sets1, Products)
sets1 = 'n Nodes'
sets+= makesetstring(sets1, Nodes)
sets1 = 'r(n) Retailer'
sets+= makesetstring(sets1, Retailer)
sets1 = 'd(n) Distributor'
sets+= makesetstring(sets1,Distributer)
sets1 = 'm(n) Manufacturer'
sets+= makesetstring(sets1,Manufacturer) 
sets+='alias(n,n1)\n'
f = open('LSSC_SS.setfile','w')
f.write(sets)
f.close()
tmp_files.append('LSSC_SS.setfile')




### Economic Steady State to find input steady state
#All target are zero for the economic problem.
#We obtain the steady state for the economic problem and the steady
#state inputs are the input targets. 
weight = 'eco = 1;\n'
weight+= 'track = 0;\n'
weight+= 'sE = 1; \n'
weight+= 'sT = 1; \n'
f = open('LSSC.weights','w')
f.write(weight0+weight)
f.close()
tmp_files.append('LSSC.weights')
shiptarg_str = "".join(['shipT('+strq(s)+','+strq(n)+','+strq(n1)+')=0;\n'\
                 for s in Products for n in Nodes for n1 in Nodes])
ordertarg_str ="".join(['orderT('+strq(s)+','+strq(n)+','+strq(n1)+')=0;\n'\
                 for s in Products for n in Nodes for n1 in Nodes])
itarg_str = shiptarg_str+ordertarg_str
f = open('LSSC.targets','w')
f.write(targ0+starg_str+itarg_str)
f.close()
tmp_files.append('LSSC.targets')
os.system('gams LSSC_SS.gms')
#GAMS writes the file input.targets.eco (steady state inputs that
#becpme input targets for the tracking problem
shipT = {s:{n:{n1:0 for n1 in Nodes} for n in Nodes} for s in Products}
orderT = {s:{n:{n1:0 for n1 in Nodes} for n in Nodes} for s in Products}
itarg_str = ''
data = [d for d in csv.DictReader(open('input.targets.eco'))]
for d in data:
    itarg_str+='shipT('+strq(d["s"])+','+strq(d["n"])+','\
        +strq(d["n1"])+')='+d["S"]+';\n'     
    itarg_str+='orderT('+strq(d["s"])+','+strq(d["n"])+','\
        +strq(d["n1"])+')='+d["O"]+';\n' 
    shipT[d["s"]][d["n"]][d["n1"]] = float(d["S"])
    orderT[d["s"]][d["n"]][d["n1"]] = float(d["O"])
f = open('LSSC.targets','w')
f.write(targ0+starg_str+itarg_str)
f.close()
tmp_files.append('input.targets.eco')

### Tracking Steady State
weight = 'eco = 0;\n'
weight+= 'track = 1;\n'
weight+= 'sE = 1; \n'
weight+= 'sT = 1; \n'
f = open('LSSC.weights','w')
f.write(weight0+weight)
f.close()
os.system('gams LSSC_SS.gms')
f = open('scale.ss')
data = f.read().split('\n')
track_opt = float(data[1])
eco_nadir = float(data[0])
f.close()
tmp_files.append('scale.ss')

## Resolve Economic problem to find the worst tracking cost for the
#economic problem
weight = 'eco = 1;\n'
weight+= 'track = 0;\n'
weight+= 'sE = 1; \n'
weight+= 'sT = 1; \n'
f = open('LSSC.weights','w')
f.write(weight0+weight)
f.close()
os.system('gams LSSC_SS.gms')
f = open('scale.ss')
data = f.read().split('\n')
eco_opt = float(data[0])
track_nadir = float(data[1])
f.close()

### Mixed Steady State 
### LSSC.weights gets fixed here
eco_scale = eco_nadir-eco_opt
track_scale = track_nadir-track_opt
weight = 'eco ='+str(eco)+';\n'
weight+= 'track ='+str(1-eco)+';\n'
weight+= 'sE ='+ str(eco_scale)+ ';\n'
weight+= 'sT ='+ str(track_scale)+'; \n'
f = open('LSSC.weights','w')
f.write(weight0+weight)
f.close()
os.system('gams LSSC_SS.gms')
##Get the steady state file
InvSS = {s:{n:0 for n in Nodes} for s in Products}
BOSS = {s:{n:{n1:0 for n1 in Nodes} for n in Nodes} for s in Products}
ShipBarSS = {s:{n:{n1:{tt:0\
                      for tt in [str(ttt) for ttt in range(1,tbar+1)]}\
                   for n1 in Nodes}\
                for n in Nodes}\
             for s in Products}
OrderBarSS = {s:{n:{n1:{tt:0\
                      for tt in [str(ttt) for ttt in range(1,tbar+1)]}\
                   for n1 in Nodes}\
                for n in Nodes}\
             for s in Products}
sswrite = ''
data = [d for d in csv.DictReader(open('steadystate.ss'))]
for d in data:
    vtypar = locals()[d['type']+'SS']
    if d['type'] == 'Inv':
        sswrite+=  d['type']+'SS('+\
            strq(d['prod'])+','+strq(d['node'])+')='+d['val']+';\n'
        vtypar[d['prod']][d['node']]=float(d['val'])
    else:
        if d['type'] == 'BO':
            sswrite+=  d['type']+'SS('+\
                strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])+')='+d['val']+';\n'
            vtypar[d['prod']][d['node']][d['node1']] =float(d['val'])
        else:
            sswrite+= d['type']+'SS('+\
                strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                +','+strq(d['tbar'])+')='+d['val']+';\n'
            vtypar[d['prod']][d['node']][d['node1']][d['tbar']] =\
                                                 float(d['val'])  
f = open('LSSC.steadystate','w')
f.write(ss0+sswrite)
f.close()
tmp_files.append('steadystate.ss')
tmp_files.append('LSSC.steadystate')


####################################################################################

###### Dynamic Problem#######
#Initial lifted states
#lets just set it to the steady-state values when writing the file
#(for starters)


## make the files
### LSSC.{network,costs,weights,constraints,targets,steadysate} are
##already made when we solved the final steadystate problem
initwrite = ''
if Ship0 == None:
    #initialize past inputs with steady state values
    data = [d for d in csv.DictReader(open('steadystate.ss'))]
    for d in data:
        if d['type'] == 'Inv' or d['type'] == 'BO':
            continue                                     
        else:
            initwrite+= d['type']+'0('+\
                strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                +','+strq(d['tbar'])+')='+d['val']+';\n'

for s in Products:
    for n in Nodes:
        initwrite+='Inv0('+strq(s)+','+strq(n)+')='+str(Inv0[s][n])+';\n'
        for n1 in Nodes:
            initwrite+='BO0('+strq(s)+','+strq(n)+','+strq(n1)+')='+str(BO0[s][n][n1])+';\n'

f = open('LSSC.initial','w')
f.write(init0+initwrite)
f.close()
tmp_files.append('LSSC.initial')

#sets file
#time in sets file is 0,1,...N
sets = 'SETS \n'
sets1 = 't Time'
sets+= makesetstring(sets1,Hor)
sets1 = 'tbar For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tbar+1)])
sets1 = 's Materials'
sets+= makesetstring(sets1, Products)
sets1 = 'n Nodes'
sets+= makesetstring(sets1, Nodes)
sets1 = 'r(n) Retailer'
sets+= makesetstring(sets1, Retailer)
sets1 = 'd(n) Distributor'
sets+= makesetstring(sets1,Distributer)
sets1 = 'm(n) Manufacturer'
sets+= makesetstring(sets1,Manufacturer) 
sets+='alias(n,n1)\n'
sets+='alias(t,t1);\n'
f = open('LSSC.setfile','w')
f.write(sets)
f.close()
tmp_files.append('LSSC.setfile')
dem0 = 'PARAMETER Dem(s,r,t) ;\n'

status = []
optimal = []

#make the dictionaries to store the closed-loop data
CL_Inv = {s:{n:[] for n in Nodes} for s in Products}
CL_BO = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
CL_Ship = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
CL_Order = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
for curr_time in range(sim_time):
    #demands file
    dem_str = ''
    for s in Products:
        for r in Retailer:
            for t in Hor:
                if t == '0' or t == '1' or t == '2':
                    #write the acutal demand
                    dem = str(Actual_Demand[s][r][curr_time+int(t)])
                else:
                    dem = str(Nominal_Demand[s][r])
                dem_str+=\
                    'Dem('+strq(s)+','+strq(r)+','+strq(t)+')='+dem+';\n'
    f = open('LSSC.demands','w')
    f.write(dem0+dem_str)
    f.close()
    
    #initial condition
    if curr_time >0:
        #for the first time we have already created LSSC.initial
        #the subsequent state is stored in nextstate.dynamic
        #from the GAMS simulation
        initwrite = ''
        data = [d for d in csv.DictReader(open('nextstate.dynamic'))]
        for d in data:
            if d['type'] == 'Inv':
                initwrite+=  d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+')='+d['val']+';\n'
            else:
                if d['type'] == 'BO':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                        +')='+d['val']+';\n'
                else:
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                        +','+strq(d['tbar'])+')='+d['val']+';\n'
        f = open('LSSC.initial','w')
        f.write(init0+initwrite)
        f.close()
    
    #Optimization
    os.system('gams LSSC_dynamics.gms')
    #Post porcessing
    #status.dynamics contains solver status and optimal objective value
    f = open('status.dynamics')
    r = f.read().split('\n')
    
    status.append(float(r[0]))
    optimal.append(float(r[1]))
    
    #data.dynamics contains the current state and input(shipbars are
    #not written because it can inferred from the data itself)
    data = [d for d in csv.DictReader(open('data.dynamics'))]
    for d in data:
        tvaryp = locals()['CL_'+d['type']]
        s = d['prod']
        n = d['node']
        n1 = d['node1']
        val = float(d['val'])
        if d['type'] == 'Inv':
            tvaryp[s][n].append(val)
        else:
            tvaryp[s][n][n1].append(val)

tmp_files.append('LSSC.demands')
tmp_files.append('status.dynamics')
tmp_files.append('data.dynamics')
tmp_files.append('nextstate.dynamic')

cloptimal = optimal
clstatus = status
###### Dynamic Problem with Operating Policy#######
#Initial lifted states
#lets just set it to the steady-state values when writing the file
#(for starters)


## make the files
### LSSC.{network,costs,weights,constraints,targets,steadysate} are
##already made when we solved the final steadystate problem
initwrite = ''
if Ship0 == None:
    #initialize past inputs with steady state values
    data = [d for d in csv.DictReader(open('steadystate.ss'))]
    for d in data:
        if d['type'] == 'Inv' or d['type'] == 'BO':
            continue                                     
        else:
            initwrite+= d['type']+'0('+\
                strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                +','+strq(d['tbar'])+')='+d['val']+';\n'

for s in Products:
    for n in Nodes:
        initwrite+='Inv0('+strq(s)+','+strq(n)+')='+str(Inv0[s][n])+';\n'
        for n1 in Nodes:
            initwrite+='BO0('+strq(s)+','+strq(n)+','+strq(n1)+')='+str(BO0[s][n][n1])+';\n'

f = open('LSSC.initial','w')
f.write(init0+initwrite)
f.close()
tmp_files.append('LSSC.initial')

#sets file
#Hor = ['0','1','2','3','4']
#time in sets file is 0,1,...N
sets = 'SETS \n'
sets1 = 't Time'
sets+= makesetstring(sets1,Hor)
sets1 = 'tbar For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tbar+1)])
sets1 = 's Materials'
sets+= makesetstring(sets1, Products)
sets1 = 'n Nodes'
sets+= makesetstring(sets1, Nodes)
sets1 = 'r(n) Retailer'
sets+= makesetstring(sets1, Retailer)
sets1 = 'd(n) Distributor'
sets+= makesetstring(sets1,Distributer)
sets1 = 'm(n) Manufacturer'
sets+= makesetstring(sets1,Manufacturer) 
sets+='alias(n,n1)\n'
sets+='alias(t,t1);\n'
f = open('LSSC.setfile','w')
f.write(sets)
f.close()
tmp_files.append('LSSC.setfile')
dem0 = 'PARAMETER Dem(s,r,t) ;\n'

status = []
optimal = []

#make the dictionaries to store the closed-loop data
PCL_Inv = {s:{n:[] for n in Nodes} for s in Products}
PCL_BO = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
PCL_Ship = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
PCL_Order = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}

for curr_time in range(sim_time):
    #demands file
    dem_str = ''
    for s in Products:
        for r in Retailer:
            for t in Hor:
                if t == '0':
                    #write the acutal demand
                    dem = str(Actual_Demand[s][r][curr_time])
                else:
                    dem = str(Nominal_Demand[s][r])
                dem_str+=\
                    'Dem('+strq(s)+','+strq(r)+','+strq(t)+')='+dem+';\n'
    f = open('LSSC.demands','w')
    f.write(dem0+dem_str)
    f.close()
    
    #initial condition
    if curr_time >0:
        #for the first time we have already created LSSC.initial
        #the subsequent state is stored in nextstate.dynamic
        #from the GAMS simulation
        initwrite = ''
        data = [d for d in csv.DictReader(open('nextstate.dynamic'))]
        #import pdb; pdb.set_trace()
        for d in data:
            if d['type'] == 'Inv':
                initwrite+=  d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+')='+d['val']+';\n'
            else:
                if d['type'] == 'BO':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                        +')='+d['val']+';\n'
                else:
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                        +','+strq(d['tbar'])+')='+d['val']+';\n'
        f = open('LSSC.initial','w')
        f.write(init0+initwrite)
        f.close()
    
    #Optimization
    os.system('gams LSSC_policy.gms')
    #import pdb;pdb.set_trace()
    #Post porcessing
    #status.dynamics contains solver status and optimal objective value
    f = open('status.dynamics')
    r = f.read().split('\n')
    
    status.append(float(r[0]))
    optimal.append(float(r[1]))
    
    #data.dynamics contains the current state and input(shipbars are
    #not written because it can inferred from the data itself)
    data = [d for d in csv.DictReader(open('data.dynamics'))]
    for d in data:
        tvaryp = locals()['PCL_'+d['type']]
        s = d['prod']
        n = d['node']
        n1 = d['node1']
        val = float(d['val'])
        if d['type'] == 'Inv':
            tvaryp[s][n].append(val)
        else:
            tvaryp[s][n][n1].append(val)

# saving data
import cPickle
finaldict = {}
finaldict['CL_Inv'] = CL_Inv
finaldict['CL_BO'] = CL_BO
finaldict['CL_Ship'] = CL_Ship
finaldict['CL_Order'] = CL_Order
finaldict['PCL_Inv'] = PCL_Inv
finaldict['PCL_BO'] = PCL_BO
finaldict['PCL_Ship'] = PCL_Ship
finaldict['PCL_Order'] = PCL_Order
finaldict['Inv_Target'] = invT
finaldict['BO_Target'] = ordT
finaldict['Ship_Target'] = shipT
finaldict['Order_Target'] = orderT
finaldict['Inv_SS'] = InvSS
finaldict['BO_SS'] = BOSS
finaldict['ShipBar_SS'] = ShipBarSS
finaldict['OrderBar_SS'] = OrderBarSS
finaldict['ActualDemand'] = Actual_Demand
finaldict['CL_objective'] = cloptimal
finaldict['CL_status'] = clstatus
finaldict['PCL_objective'] = optimal
finaldict['PcL_status'] = status
finaldict['info'] = 'Simulation with N='+str(N)+'for'+\
'omega='+str(eco)+'no constraints to compare with sS policy'
sim_no = 2;
cPickle.dump(finaldict,open('CL_data'+str(sim_no)+'.dump','w'))


tmp_files.append('*.lst')
tmp_files.append('*.pyc')

#clearing temporary files
#for fil in tmp_files:
#    os.system('rm '+ fil)

