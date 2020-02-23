import cPickle
import numpy as np
import network
fd = cPickle.load(open('CL_data2.dump'))

#will only work with this particular network file...not general
#bullwhip effect file
actual = fd['ActualDemand']
CO = fd['CL_Order']
PO = fd['PCL_Order']

plotvars = ['R1','R5','D1','D2','M1']

std =np.std
ary = np.array

csvwrite = []
data = {}
s = 'A'
data['name'] = 'R1'
data['order_in'] = str(std(ary(actual[s]['R1'])))
data['order_MPC'] = str(std(ary(CO[s]['R1']['D1'])))
data['order_sS'] = str(std(ary(PO[s]['R1']['D1'])))
csvwrite.append(data)
data = {}
data['name'] = 'R5'
data['order_in'] = str(std(ary(actual[s]['R5'])))
data['order_MPC'] = str(std(ary(CO[s]['R5']['M1'])))
data['order_sS'] = str(std(ary(PO[s]['R5']['M1'])))
csvwrite.append(data)
data = {}
data['name'] = 'D1'
data['order_in'] = str(std(ary(actual[s]['R1']+actual[s]['R2'])))
data['order_MPC'] = str(std(ary(CO[s]['D1']['M1'])))
data['order_sS'] = str(std(ary(PO[s]['D1']['M1'])))
csvwrite.append(data)
data = {}
data['name'] = 'D2'
data['order_in'] = str(std(ary(actual[s]['R3']+actual[s]['R4'])))
data['order_MPC'] = str(std(ary(CO[s]['D2']['M1'])))
data['order_sS'] = str(std(ary(PO[s]['D2']['M1'])))
csvwrite.append(data)

import csv
f = open('temp.dat','w')
output = csv.DictWriter(f,fieldnames = data.keys(),delimiter =' ')
output.writerow({d:d for d in ['name','order_in','order_MPC','order_sS']})
for row in csvwrite:
    output.writerow(row)
f.close()

f = open('temp.dat')
read = csv.DictReader(f,delimiter = ' ')
writestr = 'name order_in order_MPC order_sS \n'
for d in read:
    writestr+=d['name']+' ' + d['order_in']+' '+ d['order_MPC'] + ' ' + d['order_sS']+'\n'
f.close()
f = open('bullwhip.dat','w')
f.write(writestr)
f.close()



#for the plots
#plotting Inventory (combined) and BO (for each product) for product B at R3
#plotting Ordering by R5 for product A
#

CS = fd['CL_Ship']
PS = fd['PCL_Ship']
writestr ='# Time,Dem-A,Order-A-MPC, Order-A-Pol\n'
for i in range(len(CO['A']['R3']['D2'])):
     writestr+=\
         str(i) + ' ' + str(actual['A']['R3'][i]) + \
         ' ' + str(CO['A']['R3']['D2'][i])+\
         ' ' + str(PO['A']['R3']['D2'][i])+'\n'
f = open('R5.dat','w')
f.write(writestr)
f.close()

CI = fd['CL_Inv']
PI = fd['PCL_Inv']
CO = fd['CL_BO']
PO = fd['PCL_BO']

writestr ='# Time,Inv-MPC,Inv-Pol,BO-A-MPC, BO-A-Pol, BO-B-MPC, BO-B-Pol\n'
for i in range(len(CI['A']['R3'])):
     writestr+=\
         str(i) + ' ' + str(CI['A']['R3'][i]) + \
         ' ' + str(PI['A']['R3'][i]) + \
         ' ' + str(CO['A']['R3']['R3'][i])+\
         ' ' + str(PO['A']['R3']['R3'][i])+\
         ' ' + str(CO['B']['R3']['R3'][i])+\
         ' ' + str(PO['B']['R3']['R3'][i])+'\n'
f = open('R3.dat','w')
f.write(writestr)
f.close()

#data for the average inventory and BO table
writestr = ' &$M1$&$D1$&$D2$&$R1$&$R2$&$R3$&$R4$&$R5$\\\\ \\midrule\n'
writestr+='MPC&'
for n in network.Nodes:
    writestr+=\
        str(np.mean(fd['CL_Inv']['A'][n]))+'&'
writestr= writestr.rstrip('&')+'\\\\ \n Policy&'
for n in network.Nodes:
    writestr+=\
        str(np.mean(fd['PCL_Inv']['A'][n]))+'&'
writestr = writestr.rstrip('&')+'\\bottomrule \n \n'
f = open('table_A.dat','w')
f.write(writestr)
f.close()

writestr = ' &$M1$&$D1$&$D2$&$R1$&$R2$&$R3$&$R4$&$R5$\\\\ \\midrule\n'
writestr+='MPC&'
for n in network.Nodes:
    writestr+=\
        str(np.mean(fd['CL_Inv']['B'][n]))+'&'
writestr= writestr.rstrip('&')+'\\\\ \n Policy&'
for n in network.Nodes:
    writestr+=\
        str(np.mean(fd['PCL_Inv']['B'][n]))+'&'
writestr = writestr.rstrip('&')+'\\bottomrule \n \n'
f = open('table_B.dat','w')
f.write(writestr)
f.close()
