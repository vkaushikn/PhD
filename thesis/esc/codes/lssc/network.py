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
Prod_Lead_Time['A'] = {}
Prod_Lead_Time['A']['M1'] = 2
Prod_Lead_Time['B'] = {}
Prod_Lead_Time['B']['M1'] = 3

leadtimes1 = []
[leadtimes1.extend([v[2] for v in Connection[s]]) for s in Products]
leadtimes1.extend([Prod_Lead_Time[s][m] for s in Products\
                       for m in Manufacturer])
tbar = max(leadtimes1)


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


#Inventory and BO targets
#(nput targets obtained from Economic SS problem)
#BO targets are not separated by which node in downstream (for now) 
invT = {'A':{},'B':{}}
ordT = {s:{n:0 for n in Nodes} for s in Products}

invT['A']['M1'] = 70
invT['B']['M1'] = 61
invT['A']['D1'] = 30
invT['B']['D1'] = 29.2
invT['A']['D2'] = 24
invT['B']['D2'] = 15.6
invT['A']['R1'] = 12
invT['B']['R1'] = 16.8
invT['A']['R2'] = 18
invT['B']['R2'] = 12.4
invT['A']['R3'] = 20
invT['B']['R3'] = 5.6
invT['A']['R4'] = 8.0
invT['B']['R4'] = 10
invT['A']['R5'] = 16
invT['B']['R5'] = 16.8

# Economic Cost Parameters
EHoldingCost = {'A':{},'B':{}}
EBackOrderCost = {'A':{},'B':{}}
EShippingCost = {'A':[],'B':[]}
EOrderingCost = {'A':[],'B':[]}

#Tracking Cost Parameters
THoldingCost = {'A':{},'B':{}}
TBackOrderCost = {'A':{},'B':{}}
TShippingCost = {'A':[],'B':[]}
TOrderingCost = {'A':[],'B':[]}

for s in Products:
    for n in Nodes: 
        EHoldingCost[s][n] = 1
        EBackOrderCost[s][n] = 10
        THoldingCost[s][n] = 1
        TBackOrderCost[s][n] = 10
CostList0 = ['EHoldingCost','EBackOrderCost','THoldingCost','TBackOrderCost']

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

TShippingCost['A'] =\
[('M1','D1',0.1),('M1','D2',0.1),\
 ('D1','R1',0.1),('D1','R2',0.1),
 ('R1','R1',0.1),('R2','R2',0.1),\
 ('D2','R3',0.1),('D2','R4',0.1),\
 ('R3','R3',0.1),('R4','R4',0.1),\
 ('M1','R5',0.1),\
 ('R5','R5',0.1)]

TShippingCost['B'] =\
[('M1','D1',0.1),('M1','D2',0.1),\
 ('D1','R1',0.1),('D1','R2',0.1),
 ('R1','R1',0.1),('R2','R2',0.1),\
 ('D2','R3',0.1),('D2','R4',0.1),\
 ('R3','R3',0.1),('R4','R4',0.1),\
 ('M1','R5',0.1),\
 ('R5','R5',0.1)]

TOrderingCost['A'] =\
[('D1','M1',1), ('D2','M1',1),\
 ('R1','D1',1), ('R2','D1',1),\
 ('R3','D2',1), ('R4','D2',1),\
 ('R5', 'M1',1), ('M1','M1',1)]

TOrderingCost['B'] =\
[('D1','M1',0.1), ('D2','M1',0.1),\
 ('R1','D1',0.1), ('R2','D1',0.1),\
 ('R3','D2',0.1), ('R4','D2',0.1),\
 ('R5', 'M1',0.1), ('M1','M1',0.1)]
CostList = ['EShippingCost','EOrderingCost','TShippingCost','TOrderingCost']

#weight given to the economic objective function
eco = 0.4

# Horizon and Time
N = 15
sim_time = 50
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

Inv0['A']['M1'] = 63
Inv0['B']['M1'] = 40
Inv0['A']['D1'] = 14
Inv0['B']['D1'] = 12
Inv0['A']['D2'] = 24
Inv0['B']['D2'] = 7
Inv0['A']['R1'] = 0
Inv0['B']['R1'] = 0
Inv0['A']['R2'] = 2.1
Inv0['B']['R2'] = 1.2
Inv0['A']['R3'] = 3.1
Inv0['B']['R3'] = 1.2
Inv0['A']['R4'] = 3.1
Inv0['B']['R4'] = 0
Inv0['A']['R5'] = 0
Inv0['B']['R5'] =5.2

#Initial lifted states
#lets just set it to the steady-state values when writing the file
#(for starters)
Ship0 = None

#Actual Demands
Actual_Demand = {}
for s in Products:
    Actual_Demand[s] = {}
    for ri in Retailer:
        Actual_Demand[s][ri] = \
            [max(Nominal_Demand[s][ri]+normal(0,Var[s][ri]),0) for j in Time1]
############END SUPPLY CHAIN DEFINITION ############################# 



