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
par0+= 'tau(s,n,n1) Transportation delay for s from n to n1 \n'
par0+= 'BTmax(s) \n'
par0+= 'BTmin(s) \n'
par0+= 'PT(s) \n'
par0+= 'CHT(s,s1); \n'

cost0 = 'PARAMETERS \n'
cost0+= 'EHoldingCost(s,n) \n'
cost0+= 'EBackOrderCost(s,n) \n'
cost0+= 'EShippingCost(s,n,n1) \n'
cost0+= 'EOrderingCost(s,n,n1) \n'
cost0+= 'costW(s) \n'
cost0+= 'costZ(s,s1); \n'

const0 = 'PARAMETERS \n'
const0+= 'InvUP(n) Maximum inventory (combined) in node;\n'


ss0 = 'PARAMETERS \n'
ss0+= 'InvSS(s,n,k) \n'
ss0+= 'BOSS(s,n,n1,k) \n'
ss0+= 'ShipBarSS(s,n,n1,tbar,k) \n'
ss0+= 'OrderBarSS(s,n,n1,tbar,k)\n'
ss0+= 'WbarSS(s,tpast,k) \n'
ss0+= 'XbarSS(s,tpast,k) \n'
ss0+= 'ZbarSS(s,s1,tpast,k); \n'

init0 = ''
init0+= 'PARAMETERS \n'
init0+= 'Inv0(s,n) \n'
init0+= 'BO0(s,n,n1) \n'
init0+= 'ShipBar0(s,n,n1,tbar) \n'
init0+= 'OrderBar0(s,n,n1,tbar) \n'
init0+= 'Wbar0(s,tpast) \n'
init0+= 'Xbar0(s,tpast) \n'
init0+= 'Zbar0(s,s1,tpast); \n'

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
btstr = ''
lead =''
for s in Products:
    btstr+= 'BTmax('+strq(s)+')='+str(BTmax[s])+';\n'
    btstr+= 'BTmin('+strq(s)+')='+str(0.25*BTmax[s])+';\n'
    lead+='PT('+strq(s)+')='+str(Prod_Lead_Time[s])+';\n'
    for s1 in Products:
        lead+='CHT('+strq(s)+','+strq(s1)+')='+str(Change_Time[s][s1])+';\n'
f = open('LSSC.network','w')
f.write(par0+up_conn+dn_conn+delay_str+btstr+lead)
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
for s in Products:
    costval = str(Prodcost[s])
    coststr+=\
        'costW('+strq(s)+')='+costval+';\n'
    for s1 in Products:
        costval = str(ChangeCost[s][s1])
        coststr+=\
            'costZ('+strq(s)+','+strq(s1)+')='+costval+';\n'
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

############STEADY STATE PROBLEM##################################### 
#nominal demand
dem0 = 'PARAMETER Dem(s,r,t) ;\n'
dem =  ''
for s in Products:
    for r in Retailer:
        demstr = str(Nominal_Demand[s][r])
        for t in range(N_period):
            dem+=\
                'Dem('+strq(s)+','+strq(r)+','+strq(str(t))+')='+demstr+';\n'
f = open('LSSC.nominal','w')
f.write(dem0+dem)
f.close()
tmp_files.append('LSSC.nominal')

##Create the steady state files
# Sets:
sets = 'SETS \n'
sets1 = 't'
sets+= makesetstring(sets1,[str(i) for i in range(0,N_period)])
sets1 = 'tbar For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tbar+1)])
sets1 = 'tpast for lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tpast+1)])
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
sets+='alias(s,s1);\n'
f = open('LSSC_SS.setfile','w')
f.write(sets)
f.close()
tmp_files.append('LSSC_SS.setfile')




### Economic Steady State to find input steady state
os.system('gams LSSC_SS.gms')
##Get the steady state file
InvSS = {s:{n:[] for n in Nodes} for s in Products}
BOSS = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
ShipBarSS = {s:{n:{n1:{tt:[]\
                      for tt in [str(ttt) for ttt in range(1,tbar+1)]}\
                   for n1 in Nodes}\
                for n in Nodes}\
             for s in Products}
OrderBarSS = {s:{n:{n1:{tt:[]\
                      for tt in [str(ttt) for ttt in range(1,tbar+1)]}\
                   for n1 in Nodes}\
                for n in Nodes}\
             for s in Products}
WbarSS = {s:{tt:[] for tt in [str(ttt) for ttt in range(1,tpast+1)]}\
             for s in Products}
XbarSS = {s:{tt:[] for tt in [str(ttt) for ttt in range(1,tpast+1)]}\
              for s in Products}
ZbarSS = {s:{s1:{tt:[] for tt in [str(ttt) for ttt in range(1,tpast+1)]}\
             for s1 in Products}\
                 for s in Products}
sswrite = ''
data = [d for d in csv.DictReader(open('steadystate.ss'))]
for d in data:
    vtypar = locals()[d['type']+'SS']
    if d['type'] == 'Inv':
        sswrite+=  d['type']+'SS('+\
            strq(d['prod'])+','+strq(d['node'])+','+strq(d['t'])+')='+d['val']+';\n'
        vtypar[d['prod']][d['node']].append(float(d['val']))
    if d['type'] == 'BO':
        sswrite+=  d['type']+'SS('+\
            strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])+','+strq(d['t'])+')='+d['val']+';\n'
        vtypar[d['prod']][d['node']][d['node1']].append(float(d['val']))
    if d['type'] == 'ShipBar' or d['type'] == 'OrderBar':
        sswrite+= d['type']+'SS('+\
            strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
            +','+strq(d['tbar'])+','+strq(d['t'])+')='+d['val']+';\n'
        vtypar[d['prod']][d['node']][d['node1']][d['tbar']].append(float(d['val']))
    if d['type'] == 'Wbar' or d['type'] == 'Xbar':
        sswrite+=  d['type']+'SS('+\
           strq(d['prod'])+','+strq(d['tbar'])+','+strq(d['t'])+')='+d['val']+';\n'
        vtypar[d['prod']][d['tbar']].append(float(d['val']))
    if d['type'] == 'Zbar':
         sswrite+=  d['type']+'SS('+\
           strq(d['prod'])+','+ strq(d['node'])+','+strq(d['tbar'])+','+strq(d['t'])+')='+d['val']+';\n'
         vtypar[d['prod']][d['node']][d['tbar']].append(float(d['val']))
f = open('LSSC.steadystate','w')
f.write(ss0+sswrite)
f.close()
tmp_files.append('steadystate.ss')
tmp_files.append('LSSC.steadystate')

ss_gantt = ''
data = [d for d in csv.DictReader(open('steadystate.gantt'))]
for d in data:
    color = 'red' if d['prod'] == 'A' else 'blue'
    ss_gantt+='U '+d['start']+' '+d['end']+ ' '+ color+ ' ' + d['val'] + '\n'
f = open('SS_gantt.dat','w')
f.write(ss_gantt)
f.close()
tmp_files.append('steadystate.gantt')
    


#####################################################################################
###### Dynamic Problem#######
####################1.] NOMINAL DEMAND #######################################
## Response to nominal demands
#Actual Demands
stoc = 0;
Actual_Demand = {}
for s in Products:
    Actual_Demand[s] = {}
    for ri in Retailer:
        Actual_Demand[s][ri] = \
            [max(Nominal_Demand[s][ri]+stoc*normal(0,Var[s][ri]),0) for j in Time1]


############WITH TERMINAL CONSTRAINTS##############################################
tc_on = 1 #terminal conditions enforced
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
            if d['t'] == '0':
                if d['type'] == 'ShipBar' or d['type'] == 'OrderBar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                        +','+strq(d['tbar'])+')='+d['val']+';\n'
                if d['type'] == 'Wbar' or d['type'] == 'Xbar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['tbar'])+')='+d['val']+';\n'
                if d['type'] == 'Zbar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['tbar'])+')='+d['val']+';\n'

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
sets1 = 'tpast For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tpast+1)])
sets1 = 'k For terminal'
sets+= makesetstring(sets1,[str(i) for i in range(N_period)])
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
sets+='alias(s,s1)\n'
sets+='alias(t,t1);\n'
sets+='Parameter tc_on toggle terminal constraint /'+str(tc_on) +'/; \n'
sets+='Parameter stoc if demand stochastic /'+str(stoc) +'/; \n'
f = open('LSSC.setfile','w')
f.write(sets)
f.close()
tmp_files.append('LSSC.setfile')
dem0 = 'PARAMETER Dem(s,r,t) ;\n'

status = []
optimal = []

#make the dictionaries to store the closed-loop data
TNS_CL_Inv = {s:{n:[] for n in Nodes} for s in Products}
TNS_CL_BO = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
TNS_CL_Ship = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
TNS_CL_Order = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
TNS_CL_W = {s:[] for s in Products} 
TNS_CL_Z = {s:{s1:[] for s1 in Products} for s in Products}
for curr_time in range(sim_time): #range(sim_time):
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
            if d['type'] == 'BO':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                    +')='+d['val']+';\n'
            if d['type'] == 'ShipBar' or d['type'] == 'OrderBar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                    +','+strq(d['tbar'])+')='+d['val']+';\n'
            if d['type'] == 'Xbar' or d['type'] == 'Wbar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['tbar'])+')='+d['val']+';\n'
            if d['type'] == 'Zbar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['tbar'])+')='+d['val']+';\n'
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
        tvaryp = locals()['TNS_CL_'+d['type']]
        s = d['prod']
        n = d['node']
        n1 = d['node1']
        val = float(d['val'])
        if d['type'] == 'Inv':
            tvaryp[s][n].append(val)
        if d['type'] == 'Order' or d['type'] == 'Ship' or d['type'] == 'BO':
            tvaryp[s][n][n1].append(val)
        if d['type'] == 'W':
            tvaryp[s].append(val)
        if d['type'] == 'Z':
            tvaryp[s][n].append(val)
            

tmp_files.append('LSSC.demands')
tmp_files.append('status.dynamics')
tmp_files.append('data.dynamics')
tmp_files.append('nextstate.dynamic')

TNS_optimal = optimal
TNS_status = status



##################WITHOUT TERMINAL CONSTRAINTS#####################3
tc_on = 0 #terminal conditions enforced
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
            if d['t'] == '0':
                if d['type'] == 'ShipBar' or d['type'] == 'OrderBar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                        +','+strq(d['tbar'])+')='+d['val']+';\n'
                if d['type'] == 'Wbar' or d['type'] == 'Xbar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['tbar'])+')='+d['val']+';\n'
                if d['type'] == 'Zbar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['tbar'])+')='+d['val']+';\n'

for s in Products:
    for n in Nodes:
        initwrite+='Inv0('+strq(s)+','+strq(n)+')='+str(Inv0[s][n])+';\n'
        for n1 in Nodes:
            initwrite+='BO0('+strq(s)+','+strq(n)+','+strq(n1)+')='+str(BO0[s][n][n1])+';\n'

f = open('LSSC.initial','w')
f.write(init0+initwrite)
f.close()


#sets file
#time in sets file is 0,1,...N
sets = 'SETS \n'
sets1 = 't Time'
sets+= makesetstring(sets1,Hor)
sets1 = 'tbar For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tbar+1)])
sets1 = 'tpast For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tpast+1)])
sets1 = 'k For terminal'
sets+= makesetstring(sets1,[str(i) for i in range(N_period)])
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
sets+='alias(s,s1)\n'
sets+='alias(t,t1);\n'
sets+='Parameter tc_on toggle terminal constraint /'+str(tc_on) +'/; \n'
sets+='Parameter stoc if demand stochastic /'+str(stoc) +'/; \n'
f = open('LSSC.setfile','w')
f.write(sets)
f.close()
dem0 = 'PARAMETER Dem(s,r,t) ;\n'

status = []
optimal = []

#make the dictionaries to store the closed-loop data
NTNS_CL_Inv = {s:{n:[] for n in Nodes} for s in Products}
NTNS_CL_BO = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
NTNS_CL_Ship = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
NTNS_CL_Order = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
NTNS_CL_W = {s:[] for s in Products} 
NTNS_CL_Z = {s:{s1:[] for s1 in Products} for s in Products}
for curr_time in range(sim_time): #range(sim_time):
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
            if d['type'] == 'BO':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                    +')='+d['val']+';\n'
            if d['type'] == 'ShipBar' or d['type'] == 'OrderBar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                    +','+strq(d['tbar'])+')='+d['val']+';\n'
            if d['type'] == 'Xbar' or d['type'] == 'Wbar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['tbar'])+')='+d['val']+';\n'
            if d['type'] == 'Zbar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['tbar'])+')='+d['val']+';\n'
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
        tvaryp = locals()['NTNS_CL_'+d['type']]
        s = d['prod']
        n = d['node']
        n1 = d['node1']
        val = float(d['val'])
        if d['type'] == 'Inv':
            tvaryp[s][n].append(val)
        if d['type'] == 'Order' or d['type'] == 'Ship' or d['type'] == 'BO':
            tvaryp[s][n][n1].append(val)
        if d['type'] == 'W':
            tvaryp[s].append(val)
        if d['type'] == 'Z':
            tvaryp[s][n].append(val)
            
NTNS_optimal = optimal
NTNS_status = status


####################2.] STOCHASTIC DEMAND #######################################
## Response to nominal demands
#Actual Demands
stoc = 1;
Actual_Demand = {}
for s in Products:
    Actual_Demand[s] = {}
    for ri in Retailer:
        Actual_Demand[s][ri] = \
            [max(Nominal_Demand[s][ri]+stoc*normal(0,Var[s][ri]),0) for j in Time1]


############WITH TERMINAL CONSTRAINTS##############################################
tc_on = 1 #terminal conditions enforced
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
            if d['t'] == '0':
                if d['type'] == 'ShipBar' or d['type'] == 'OrderBar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                        +','+strq(d['tbar'])+')='+d['val']+';\n'
                if d['type'] == 'Wbar' or d['type'] == 'Xbar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['tbar'])+')='+d['val']+';\n'
                if d['type'] == 'Zbar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['tbar'])+')='+d['val']+';\n'

for s in Products:
    for n in Nodes:
        initwrite+='Inv0('+strq(s)+','+strq(n)+')='+str(Inv0[s][n])+';\n'
        for n1 in Nodes:
            initwrite+='BO0('+strq(s)+','+strq(n)+','+strq(n1)+')='+str(BO0[s][n][n1])+';\n'

f = open('LSSC.initial','w')
f.write(init0+initwrite)
f.close()

#sets file
#time in sets file is 0,1,...N
sets = 'SETS \n'
sets1 = 't Time'
sets+= makesetstring(sets1,Hor)
sets1 = 'tbar For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tbar+1)])
sets1 = 'tpast For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tpast+1)])
sets1 = 'k For terminal'
sets+= makesetstring(sets1,[str(i) for i in range(N_period)])
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
sets+='alias(s,s1)\n'
sets+='alias(t,t1);\n'
sets+='Parameter tc_on toggle terminal constraint /'+str(tc_on) +'/; \n'
sets+='Parameter stoc if demand stochastic /'+str(stoc) +'/; \n'
f = open('LSSC.setfile','w')
f.write(sets)
f.close()

dem0 = 'PARAMETER Dem(s,r,t) ;\n'

status = []
optimal = []

#make the dictionaries to store the closed-loop data
TS_CL_Inv = {s:{n:[] for n in Nodes} for s in Products}
TS_CL_BO = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
TS_CL_Ship = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
TS_CL_Order = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
TS_CL_W = {s:[] for s in Products} 
TS_CL_Z = {s:{s1:[] for s1 in Products} for s in Products}
for curr_time in range(sim_time): #range(sim_time):
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
            if d['type'] == 'BO':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                    +')='+d['val']+';\n'
            if d['type'] == 'ShipBar' or d['type'] == 'OrderBar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                    +','+strq(d['tbar'])+')='+d['val']+';\n'
            if d['type'] == 'Xbar' or d['type'] == 'Wbar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['tbar'])+')='+d['val']+';\n'
            if d['type'] == 'Zbar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['tbar'])+')='+d['val']+';\n'
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
        tvaryp = locals()['TS_CL_'+d['type']]
        s = d['prod']
        n = d['node']
        n1 = d['node1']
        val = float(d['val'])
        if d['type'] == 'Inv':
            tvaryp[s][n].append(val)
        if d['type'] == 'Order' or d['type'] == 'Ship' or d['type'] == 'BO':
            tvaryp[s][n][n1].append(val)
        if d['type'] == 'W':
            tvaryp[s].append(val)
        if d['type'] == 'Z':
            tvaryp[s][n].append(val)
            



TS_optimal = optimal
TS_status = status



##################WITHOUT TERMINAL CONSTRAINTS#####################3
tc_on = 0 #terminal conditions enforced
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
            if d['t'] == '0':
                if d['type'] == 'ShipBar' or d['type'] == 'OrderBar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                        +','+strq(d['tbar'])+')='+d['val']+';\n'
                if d['type'] == 'Wbar' or d['type'] == 'Xbar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['tbar'])+')='+d['val']+';\n'
                if d['type'] == 'Zbar':
                    initwrite+= d['type']+'0('+\
                        strq(d['prod'])+','+strq(d['node'])+','+strq(d['tbar'])+')='+d['val']+';\n'

for s in Products:
    for n in Nodes:
        initwrite+='Inv0('+strq(s)+','+strq(n)+')='+str(Inv0[s][n])+';\n'
        for n1 in Nodes:
            initwrite+='BO0('+strq(s)+','+strq(n)+','+strq(n1)+')='+str(BO0[s][n][n1])+';\n'

f = open('LSSC.initial','w')
f.write(init0+initwrite)
f.close()


#sets file
#time in sets file is 0,1,...N
sets = 'SETS \n'
sets1 = 't Time'
sets+= makesetstring(sets1,Hor)
sets1 = 'tbar For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tbar+1)])
sets1 = 'tpast For lifting'
sets+= makesetstring(sets1,[str(i) for i in range(1,tpast+1)])
sets1 = 'k For terminal'
sets+= makesetstring(sets1,[str(i) for i in range(N_period)])
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
sets+='alias(s,s1)\n'
sets+='alias(t,t1);\n'
sets+='Parameter tc_on toggle terminal constraint /'+str(tc_on) +'/; \n'
sets+='Parameter stoc if demand stochastic /'+str(stoc) +'/; \n'
f = open('LSSC.setfile','w')
f.write(sets)
f.close()
dem0 = 'PARAMETER Dem(s,r,t) ;\n'

status = []
optimal = []

#make the dictionaries to store the closed-loop data
NTS_CL_Inv = {s:{n:[] for n in Nodes} for s in Products}
NTS_CL_BO = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
NTS_CL_Ship = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
NTS_CL_Order = {s:{n:{n1:[] for n1 in Nodes} for n in Nodes} for s in Products}
NTS_CL_W = {s:[] for s in Products} 
NTS_CL_Z = {s:{s1:[] for s1 in Products} for s in Products}
for curr_time in range(sim_time): #range(sim_time):
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
            if d['type'] == 'BO':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                    +')='+d['val']+';\n'
            if d['type'] == 'ShipBar' or d['type'] == 'OrderBar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['node1'])\
                    +','+strq(d['tbar'])+')='+d['val']+';\n'
            if d['type'] == 'Xbar' or d['type'] == 'Wbar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['tbar'])+')='+d['val']+';\n'
            if d['type'] == 'Zbar':
                initwrite+= d['type']+'0('+\
                    strq(d['prod'])+','+strq(d['node'])+','+strq(d['tbar'])+')='+d['val']+';\n'
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
        tvaryp = locals()['NTS_CL_'+d['type']]
        s = d['prod']
        n = d['node']
        n1 = d['node1']
        val = float(d['val'])
        if d['type'] == 'Inv':
            tvaryp[s][n].append(val)
        if d['type'] == 'Order' or d['type'] == 'Ship' or d['type'] == 'BO':
            tvaryp[s][n][n1].append(val)
        if d['type'] == 'W':
            tvaryp[s].append(val)
        if d['type'] == 'Z':
            tvaryp[s][n].append(val)
            
NTS_optimal = optimal
NTS_status = status



tmp_files.append('*.lst')
tmp_files.append('*.pyc')

#clearing temporary files
for fil in tmp_files:
    os.system('rm '+ fil)


#Preparing for writing data files for final plots
NTNS_BO = [ sum([NTNS_CL_BO[s][r][r][t] for s in Products for r in Retailer]) for t in range(sim_time)] 
TNS_BO = [ sum([TNS_CL_BO[s][r][r][t] for s in Products for r in Retailer]) for t in range(sim_time)]
NTS_BO = [ sum([NTS_CL_BO[s][r][r][t] for s in Products for r in Retailer]) for t in range(sim_time)]
TS_BO = [ sum([TS_CL_BO[s][r][r][t] for s in Products for r in Retailer]) for t in range(sim_time)]
#for closed loop gantt charts
sims = ['NTNS','TNS','NTS','TS']
for sim in sims:
    simwrite = ''
    Wvar = locals()[sim+'_CL_W']
    Ovar = locals()[sim+'_CL_Order']                   
    for t in range(sim_time):
        sched = 1 if (Wvar['A'][t] == 1 or Wvar['B'][t] == 1) else 0
        if sched == 1:
            task = 'A' if (Wvar['A'][t] == 1) else 'B'
            color = 'red' if task == 'A' else 'blue'
            endtime = t+Prod_Lead_Time[task]
            simwrite+='U '+ str(t) + ' ' + str(endtime) + ' ' + color + ' '+str(Ovar[task]['M1']['M1'][t])+'\n'
    f = open(sim+'_gantt.dat','w')
    f.write(simwrite)
    f.close()
simwrite = '#t NTNS TNS NTS TS \n'
for t in range(sim_time):
    simwrite+= str(t)+' '
    for sim in sims:
        var = locals()[sim+'_BO']
        simwrite+= str(var[t]) + ' '
    simwrite+='\n'
f = open('BOproflie.dat','w')
f.write(simwrite)
f.close()

        
        

