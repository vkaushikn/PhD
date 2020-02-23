#############SUPPLY CHAIN#DEFINITION#################################
import random
normal = random.normalvariate
#Nodes
Nodes = ['M1','D1','D2','R1','R2','R3','R4','R5']
Retailer = ['R1','R2','R3','R4','R5']
Distributer = ['D1','D2']
Manufacturer = ['M1']

#Products
Products = ['A','B']

#Connections
Connection = {}
#Each tuple consists of Upsteram,Downstream,Transportation tinme
Connection['A'] =\
[('M1','D1',2),('M1','D2',1),\
 ('D1','R1',1),('D1','R2',1),\
 ('D2','R3',2),('D2','R4',1),\
 ('M1','R5',4)]
Connection['B'] =\
[('M1','D1',2),('M1','D2',1),\
 ('D1','R1',1),('D1','R2',1),\
 ('D2','R3',2),('D2','R4',1),\
 ('M1','R5',4)]    


#Production Times
Prod_Lead_Time = {}
Change_Time = {s:{} for s in Products}
Prod_Lead_Time['A'] = 3
Change_Time['A']['B'] = 0
Change_Time['A']['A'] = 0

Prod_Lead_Time['B'] = 2
Change_Time['B']['A'] = 0
Change_Time['B']['B'] = 0
leadtimes1 = []
[leadtimes1.extend([v[2] for v in Connection[s]]) for s in Products]
tbar = max(leadtimes1)
leadtimes1 = []
leadtimes1.extend([Prod_Lead_Time[s] for s in Products])
leadtimes1.extend([Change_Time[s][s1] for s in Products for s1 in Products])
tpast = max(leadtimes1)                       

#Nominal demands
Nominal_Demand  = {}
Nominal_Demand['A'] = {}
Nominal_Demand['A']['R1'] = 3.0
Nominal_Demand['A']['R2'] = 4.5
Nominal_Demand['A']['R3'] = 5.0
Nominal_Demand['A']['R4'] = 2.0
Nominal_Demand['A']['R5'] = 4.0
Nominal_Demand['B'] ={}
Nominal_Demand['B']['R1'] = 4.2
Nominal_Demand['B']['R2'] = 3.1
Nominal_Demand['B']['R3'] = 1.4
Nominal_Demand['B']['R4'] = 2.5
Nominal_Demand['B']['R5'] = 4.2

#Inventory Limits (modeled as combined inventory space in each node) 
invUP = {}
invUP['M1'] = 140
invUP['D1'] = 80
invUP['D2'] = 50
invUP['R1'] = 40
invUP['R2'] = 40
invUP['R3'] = 30
invUP['R4'] = 25
invUP['R5'] = 45




# Economic Cost Parameters
EHoldingCost = {'A':{},'B':{}}
EBackOrderCost = {'A':{},'B':{}}
EShippingCost = {'A':[],'B':[]}
EOrderingCost = {'A':[],'B':[]}



for s in Products:
    for n in Nodes: 
        EHoldingCost[s][n] = 1
        EBackOrderCost[s][n] = 10
CostList0 = ['EHoldingCost','EBackOrderCost']

EShippingCost['A'] =\
[('M1','D1',4),('M1','D2',1),\
 ('D1','R1',1),('D1','R2',1),
 ('R1','R1',1),('R2','R2',1),\
 ('D2','R3',2),('D2','R4',1.5),\
 ('R3','R3',1),('R4','R4',1),\
 ('M1','R5',5),\
 ('R5','R5',1)]

EShippingCost['B'] =\
[('M1','D1',2),('M1','D2',2),\
 ('D1','R1',1),('D1','R2',1),
 ('R1','R1',1),('R2','R2',1),\
 ('D2','R3',2),('D2','R4',1.5),\
 ('R3','R3',1),('R4','R4',1),\
 ('M1','R5',4),\
 ('R5','R5',1)]
#Flip M,D for ordering because ordering happens in the reverse
#direction 
EOrderingCost['A'] =\
[('D1','M1',1), ('D2','M1',1),\
 ('R1','D1',1), ('R2','D1',1),\
 ('R3','D2',1), ('R4','D2',1),\
 ('R5', 'M1',0.5), ('M1','M1',10)]
EOrderingCost['B'] =\
[('D1','M1',1), ('D2','M1',1),\
 ('R1','D1',1), ('R2','D1',1),\
 ('R3','D2',1), ('R4','D2',1),\
 ('R5', 'M1',0.5), ('M1','M1',4)]


CostList = ['EShippingCost','EOrderingCost']

#Production cost
Prodcost = {}
Prodcost['A'] = 10
Prodcost['B'] = 6
ChangeCost = {s:{} for s in Products}
ChangeCost['A']['B'] = 10
ChangeCost['A']['A'] = 0
ChangeCost['B']['A'] = 5
ChangeCost['B']['B'] = 0

#production constraint
BTmax = {}
BTmax['A'] = 20
BTmax['B'] = 20
# Horizon and Time
N = 12
sim_time = 50
N_period = 24
Hor = [str(i) for i in range(N)]
Time = [str(i) for i in range(0,sim_time)]
Time1 =[str(i) for i in range(0,sim_time+N)]
# Demand Variance
Var = {}
Var['A'] = {}
Var['A']['R1'] = 1.1
Var['A']['R2'] = 1.3
Var['A']['R3'] = 1.1
Var['A']['R4'] = 1.2
Var['A']['R5'] = 1.4
Var['B'] = {}
Var['B']['R1'] = 1.3
Var['B']['R2'] = 1.4
Var['B']['R3'] = 1.1
Var['B']['R4'] = 1.1
Var['B']['R5'] = 1.4

#initial state
#Initial inventory
Inv0 = {'A':{},'B':{}}
BO0 = {s:{n:{n1:0 for n1 in Nodes} for n in Nodes} for s in Products}

Inv0['A']['M1'] = 01*63
Inv0['B']['M1'] = 01*40
Inv0['A']['D1'] = 01*14
Inv0['B']['D1'] = 01*12
Inv0['A']['D2'] = 01*24
Inv0['B']['D2'] = 01*7
Inv0['A']['R1'] = 01*0
Inv0['B']['R1'] = 01*0
Inv0['A']['R2'] = 01*2.1
Inv0['B']['R2'] = 01*1.2
Inv0['A']['R3'] = 01*3.1
Inv0['B']['R3'] = 01*1.2
Inv0['A']['R4'] = 01*3.1
Inv0['B']['R4'] = 01*0
Inv0['A']['R5'] = 01*0
Inv0['B']['R5'] = 01*5.2

#Initial lifted states
#lets just set it to the steady-state values when writing the file
#(for starters)
Ship0 = None
############END SUPPLY CHAIN DEFINITION ############################# 



