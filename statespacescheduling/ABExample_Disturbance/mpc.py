#Script will interface with GAMS to implement rolling horizon.
#Add delays to the system
import os
def implementMPC(TC):
  #TC is a string containing 'TC=1;' or 'TC=0;' for T/NT.
  os.system('cp IC1.csv S0.csv')
  schedule = dict()
  disturb = dict()
  TotTime = 25;
  le = 0;
  de = 0;
  STA = '-1 1.5;\n \n'
  STB = '-1 16.5; \n \n'
  BOA = '-1 0;\n \n'
  BOB = '-1 0;\n \n'
  writestr1 = ''
  writestr = ''
  ws = ''
  f = open('allgantt.dat','w')
  f.close();
  for nsim in range(0,TotTime):
   #introduce disturbance
   f = open('S0.csv')
   dd = f.readlines();
   f.close()
   #add delays accordingly
   writestr2 = ''
   # 1.] A loading error
   if (le == 0 and nsim >13):
    BTbarA = float(dd[22].split('=')[1].rstrip(';\n'))
    if BTbarA > 0:
     writestr2+='dC(\'TA\',\'0\',\'3\')=2;\n'
     le = 1;
     ws+= 'loading error at time(A) ' + str(nsim)+';\n'
    #end
    BTbarB = float(dd[34].split('=')[1].rstrip(';\n'))
    if BTbarB > 0:
     writestr2+='dC(\'TB\',\'0\',\'3\')=3;\n'
     le = 1;
     ws+= 'loading error at time(B) ' + str(nsim)+';\n'
    #end
   #end
   # 2.] A delay
   if de == 0 and nsim >3:
    BTbarA = float(dd[14].split('=')[1].rstrip(';\n'))
    if BTbarA > 0:
     writestr2+='dY(\'TA\',\'0\',\'2\')=1;\n'
     de = 1;
     disturb[nsim] = ('dY','TA')
     ws+='1hr dist (A) at time ' + str(nsim) +';\n'
    #end
    BTbarB = float(dd[32].split('=')[1].rstrip(';\n'))
    if BTbarB > 0:
     writestr2+='dY(\'TB\',\'0\',\'3\')=1;\n'
     disturb[nsim] = ('dY','TB')
     de = 1;
     ws+='1hr dist (B) at time ' + str(nsim) +';\n'
    #end
   #end
   # 3.] A Breakdown
   ws+='3hr breakdown at time 10;\n'
   #from nsim = 10 to nsim = 13
   if nsim == 10:
    writestr2+='dZL(\'0\')=1;\ndZL(\'1\')=1;\ndZL(\'2\')=1;\n'
   if nsim == 11:
     writestr2+='dZL(\'0\')=1;\ndZL(\'1\')=1;\n'
   if nsim == 11:
     writestr2+='dZL(\'0\')=1;\n'
   # 4.] Demand change
   ws+='Demand spike at t=15;\n'
   # hard coded in the gams file
   f = open('dist.csv','w')
   f.write(writestr2)
   f.close()
   f = open('S0.csv','a')
   f.write(TC)
   f.write('SSi = 0;\n')
   f.write('Ctime ='+str(nsim)+';\n')  
   f.close()
   os.system('gams AB_delay.gms')
   f = open('S0.csv')
   dd = f.readlines()
   STAv = dd[0].split('=')[1]
   BOAv = dd[2].split('=')[1]
   STBv = dd[4].split('=')[1]
   BOBv = dd[6].split('=')[1]
   STA+=str(nsim)+' '+  STAv + '\n'
   BOA+=str(nsim)+' '+  BOAv + '\n'
   STB+=str(nsim)+' '+  STBv + '\n'
   BOB+=str(nsim)+' '+  BOBv + '\n'
   f.close()
   f = open('gantt.dat')
   dd1 = f.readlines()
   f.close()
   writestr = ''
   for i in range(0,len(dd1)):
    if i%2 == 0:
     dat = dd1[i].split()
     if int(float(dat[0])) == nsim:
      writestr1+=dd1[i]
     #endif
     writestr+='t='+str(nsim)+' '+dd1[i]
    #endif
   #endfor
   f = open('allgantt.dat','a')
   f.write(writestr)
   f.close()
   #write the input at time t
   f = open('input.dat')
   r = f.readlines(); #make use of the fact that it will have at most two lines or just contain "dummy"
   f.close()
   inp = len(r)
   if inp>2:
    #input moves have been made at this time
    WL = r[2].split('=')[1].split()[0]
    TAB = r[2].split('=')[0].split(' ')[0]
    BTL =  r[2].split('=')[1].split()[1]
    schedule[nsim] = (TAB,WL,BTL)
   #endif

  #endfor    
  f = open('implementgantt.dat','w')
  f.write(writestr1)
  f.close()
  f = open('STA.dat','w')
  f.write(STA)
  f.close()
  f = open('STB.dat','w')
  f.write(STB)
  f.close()
  f = open('BOA.dat','w')
  f.write(BOA)
  f.close()
  f =open('BOB.dat','w')
  f.write(BOB)
  f.close()
  f = open('timedist.dat','w')
  f.write(ws)
  f.close()

  PT = dict()
  PT['TA'] = 3;
  PT['TB'] = 2;
  CT = dict()
  CT['TA'] = 2;
  CT['TB'] = 2;
  color = dict()
  color['TA'] = 'blue'
  color['TB'] = 'red'
  Zcolor = dict()
  Zcolor['TA'] = 'skyblue'
  Zcolor['TB'] = 'lightorange'
  #write the implemented schedule
  writestr = '0 1 oceanblue 10 \n'
  nsim = 0
  for nsim in range(0,TotTime):
    if schedule.get(nsim):
     #what was the event
     if schedule[nsim][1] == 'W':
      # started a batch
      nodist = 0
      for tfut in range(0,PT[schedule[nsim][0]]+1):
       if disturb.get(nsim+tfut):
        nodist+=1
        #delay or breakdown
        if disturb[nsim+tfut][0] == 'dY':
         writestr+=str(nsim)+' '+str(nsim+tfut)+ ' '+ color[schedule[nsim][0]] +' '+ schedule[nsim][2]+ '\n'
         writestr+=str(nsim+tfut)+ ' '+str(nsim+tfut+1)+ ' ' + 'lavender' + ' -\n'
         writestr+=str(nsim+tfut+1)+ ' '+str(nsim+PT[schedule[nsim][0]]+1)+ ' '+ color[schedule[nsim][0]]+ ' -\n'
        else:
         #breakdown
         writestr+=str(nsim)+' '+str(nsim+tfut)+ ' '+ color[schedule[nsim][0]] + ' -\n'
        #endif
       #endif
      #endfor
      if nodist == 0: 
      #no disturbance
       writestr+=str(nsim)+' '+str(nsim+PT[schedule[nsim][0]])+' '+color[schedule[nsim][0]] +' '+ schedule[nsim][2] +'\n'
      #endif
     else:
      #changeover
      writestr+=str(nsim)+' '+str(nsim+CT[schedule[nsim][0]])+' '+Zcolor[schedule[nsim][0]]+' '+ schedule[nsim][2] +'\n'
     #endif
    #endif 
  #endfor
  #hard code for this example
  writestr+=str(10)+' '+str(12)+' '+'gray(0.8)'+' -\n'
  f = open('schedule.dat','w')
  f.write(writestr)
  f.close()
  return
#end function

def makeplots():
  # make the plots
  # add "utility" to the schedule.dat file
  writestr = ''
  f = open('schedule.dat')
  data = f.readlines()
  f.close()
  for i in range(0,len(data)):
   writestr+='U '+data[i]
  #endfor
  f = open('schedule.dat','w')
  f.write(writestr)
  f.close()
  #remove the ';' and blank lines from STA, STB, BOA, BOB
  files = ['STA','BOA','STB','BOB']
  for file1 in files:
   f = open(file1+'.dat')
   data = f.readlines()
   f.close()
   writestr = ''
   for i in range(0,len(data),2):
    data1=data[i].rstrip(';\n')
    d = data1.split()
    d[0] = str(int(d[0])+1-1)
    writestr+=d[0]+' '+d[1]+'\n'
   #endfor i
   f = open(file1+'.dat','w')
   f.write(writestr)
   f.close()
  #endfor file1
  os.system('ploticus -eps inventoryprofile.p')
  os.system('epstopdf inventoryprofile.eps')

  #selected time gantt charts
  selectt = ['t=5','t=6', 't=7','t=9','t=10','t=11','t=13','t=14','t=15','t=16']
  writestr = ''
  f = open('allgantt.dat')
  data = f.readlines()
  f.close()
  for i in range(0,len(data)):
   d = data[i].split()
   if len(d)==4:
    d.append('-')
   #endif
   for selector in selectt:
    if d[0] == selector:
     if d[3] == 'black':
      d[3] == 'gray(0.8)'
     #endif
     writestr1 = ''
     for j in range(0,len(d)):
      writestr1+=d[j]+' '
     #endfor
     writestr+=writestr1+'\n'
    #endif 
   #endfor
  #endfor
  f = open('selectgantt.dat','w')
  f.write(writestr)
  f.close()
  os.system('ploticus -eps selectgantt_with.p')
  os.system('epstopdf selectgantt_with.eps')
  return
#end makeplots

def mpcclean():
  #clean all files except the final files
  #os.system('rm -f *.dat')
  os.system('rm -f *.eps')
  os.system('rm -f *.lst')
  os.system('rm -f S0.csv')
  os.system('rm -f status.csv')
  os.system('rm -f dist.csv')
  os.system('rm -f inventoryprofile.pdf')
  os.system('rm -f selectgantt_with.pdf')
  return
#end mpcclean

TC = 'TC=0;\n'
implementMPC(TC)
makeplots()
os.system('cp STA.dat STA_NT_disturbance.dat')
os.system('cp STB.dat STB_NT_disturbance.dat')
os.system('cp BOA.dat BOA_NT_disturbance.dat')
os.system('cp BOB.dat BOB_NT_disturbance.dat')
mpcclean()

TC = 'TC=1;\n'
implementMPC(TC)
makeplots()
os.system('cp STA.dat STA_T_disturbance.dat')
os.system('cp STB.dat STB_T_disturbance.dat')
os.system('cp BOA.dat BOA_T_disturbance.dat')
os.system('cp BOB.dat BOB_T_disturbance.dat')
mpcclean()
  

