$ontext
2 processes TA,TB
Costs include: Changeover cost
	       Holding cost of inventory
Minimum changeover time is also modeled
N is the horizon
Implement terminal constraint
$offtext


$offsymxref
$eolcom #

*$setglobal N 24
$include Nfile
$setglobal MT 3
*MT is the maximum time that we need to lift the variables

scalar TC; # TC = 1 is terminal condition problem, 0 is no TC.
scalar Ctime; #needed for running w/ python to store results at correct "real" time
scalar SSi; # for implementing safety stock constraint.

SETS
t          time /0*%N%/
i          tasks /TA,TB/
s          states /raw,A,B/
RM(s)      raw materials /raw/
FP(s)      finished products /A,B/
s_in(s,i)  if state s goes into task i
s_out(s,i) if state s comes out of task i
tbar       for lifting /1*%MT%/
k          number of periodic solution /0*19/
alias (i,i1)
alias (i,i2)
alias (t,t1)
alias (tbar,tall)
alias (tbar,tbar1)
;


PARAMETERS

*Process parameters
PT(i)     Processing time of task i 
CHT(i,i1) Changeover time from i to i1
DemD(s)   Daily demand of s
DemFre    Frequency of demand
Dem(s,t)  Demand of s at time t
L         Horizon length 
BTmax(i)  Maximum batch size of i
BTmin(i)  Minimum batch size of i
CHC(i,i1) Changeover cost from i to i1
h(s)      Holding cost for s
ro(s,i)   Mass fraction of s in i
PTmax     Max procesing time
CHTmax    Max changing time
maxtime

*Terminal constraint parameters
pW(i,k,tall)   Terminal Constraint
pZ(i,i1,k,tall)
pBT(i,k,tall)
pST(s,k)
pBO(s,k)
pX(i,k)
hW(i,tall) History for t = 1
hZ(i,i1,tall)
hBT(i,tall)
hX(i)


*Initial conditions
ST0(s)     Starting inventory
BO0(s)
Wbar0(i,tbar)
Xbar0(i,tbar)
Ybar0(i,tbar)
Zbar0(i,i1,tbar)
BTbar0(i,tbar)


*These disturbances are added to the system by the User.
*Consistency check of the disturbances is the USER RESPONSIBILITY.
*Delay disturbance
dY(i,t,tbar)

*Breakdown disturbance
*if dZ(i,t,tbar)=>sets the start of the breakdown
*dZL(i,t)=>sets the length of the breakdown
dZ(i,t,tbar)
dZL(t)

*Yield loss disturbance
* will be the loss at i,t,tbar
dC(i,t,tbar)

;

*** SET THE PARAMETERS *******
PT('TA') = 3; PT('TB') = 2; PTmax = 3;
CHT('TA','TB') = 2;  CHT('TB','TA') = 2; CHTmax = 2;
L = %N%+1;
maxtime = max(PTmax,CHTmax);

ro('raw','TA') = -1; ro('A','TA') = 1;
ro('raw','TB') = -1; ro('B','TB')=1;
s_in(s,i) = YES$(ro(s,i) lt 0);
s_out(s,i) = YES$(ro(s,i) gt 0);

BTmax(i) = 10; BTmin(i) = 0.5*BTmax(i);


*costs
CHC('TA','TB') = 10; CHC('TB','TA') = 5;
h('A') = 2; h('B') = 3;

*demands
DemD('A') = 36; DemD('B') = 36;

*hourly demands
DemFre = 24;
Dem(s,t) = (DemD(s)/DemFre)$(mod(ord(t),24/DemFre) eq 0);



dC(i,t,tbar) = 0;
dY(i,t,tbar) = 0;
dZ(i,t,tbar) = 0;
dZL(t) = 0;

$ontext
*introduce delays (change accordingly, or use python script)
dY('TA','0','2') = 0;
*delay is there for 3 hours
dY('TA','1','2') = 0;
dY('TA','2','2') = 0;
dY('TA','3','2') = 0;

*introduce breakdown (change accordingly, or use python script)
dZ('TA','0','2') = 0;

*x hour shutdown
dZL('TA','1')=0;
dZL('TA','2')=0;
dZL('TA','3')=0;

*yield loss (change accordingly, or use python script)
*Observe that only 2 tons less arrived than expected at time 1.
dC('TA','1','3') = 2;
$offtext

$include S0.csv
$include PS.csv
$include dist.csv

*increase demand at t=15,16
*if ((Ctime eq 15), Dem(s,'15') = 2.5; Dem(s,'16') = 2.5;);

VARIABLES
*inputs
W(i,t)      is 1 if batch of task i starts at time t
Y(i,t)      is 1 if batch of task i is running at time t
X(i,t)      is 1 if batch of task i is running at time t or the last batch run before idling was i
Z(i,i1,t)   is 1 if transition from i to i1 takes place at t
BT(i,t)     batch size
Ship(s,t)

*states
ST(s,t)     inventory of state s at time t
BO(s,t)     back-order
Wbar(i,t,tbar) lifted variable
Xbar(i,t,tbar)
Zbar(i,i1,t,tbar)
BTbar(i,t,tbar)

*slacks
STslackp(s,t) slack
STslackm(s,t) slack

*terminal constraint
PC(k)       selects the periodic constraint

*objective function
J           objective function
;




POSITIVE VARIABLE BT,ST,Stslackp, STslackm,BO,BTbar,Ship ;
BINARY VARIABLE W,Y,X,Z,PC,Wbar,Zbar,Xbar;

*----------------------------------DETAILS OF VARIABLES-----------------------------------------*
*Inputs: W,X,Z,BT,Ship
*States: ST, BO
*Lifted states: W(k-1),W(k-2),W(k-3),BT(k-1),BT(k-2),BT(k-3),Z(k-1),Z(k-2),Z(k-3),X(k-1)
*Disturbances: dZ,dY,dZL,dC
*-----------------------------------------------------------------------------------------------*
*-----------------------------------Constraints-------------------------------------------------*
*Input (and state) constraints Ex(k)+Fu(k) <= f-Gd(k)
Equations Chass, BS,BSI1,BSI2, BC1, BC2, BC3, BTS1, BTS2;

Chass(t)$(ord(t) lt card(t))..dZL(t)+sum(i,W(i,t))+sum((i,i1)$(not sameas(i,i1)),Z(i,i1,t))+sum((i,tbar)$(ord(tbar) lt PT(i)), Wbar(i,t,tbar))
	                      +sum((i,i1,tbar)$(ord(tbar) lt CHT(i,i1) and not sameas(i,i1)), Zbar(i,i1,t,tbar))=L=1;
BS(i,t)$(ord(t)lt card(t)).. W(i,t)+sum(tbar$(ord(tbar) lt PT(i)),Wbar(i,t,tbar))=E=Y(i,t);
BSI1(i,t)$(ord(t)lt card(t))..X(i,t) =G= Y(i,t);
BSI2(t)$(ord(t)lt card(t))..1*sum(i,X(i,t))=E=1*1;
BC1(i,i1,t)$(not sameas(i,i1) and ord(t) lt card(t))..Z(i,i1,t)=L=Xbar(i,t,'1');
BC2(i,i1,t)$(not sameas(i,i1) and ord(t) lt card(t))..Z(i,i1,t)=L=X(i1,t);
BC3(i,i1,t)$(not sameas(i,i1) and ord(t) lt card(t))..Z(i,i1,t)=G=Xbar(i,t,'1')+X(i1,t)-1;
BTS1(i,t)$(ord(t)lt card(t))..BT(i,t)=L=W(i,t)*BTmax(i);
BTS2(i,t)$(ord(t)lt card(t))..BT(i,t)=G=W(i,t)*BTmin(i);

*-------------------------------------------------------------------------------------------------*
*----------------------------------State Equations------------------------------------------------*
*Dynamic state equations x(k+1) = Ax(k) + Bu(k) + B_d d(k)
Equations MBt, BOt, Wbar1, Wbar2, Xbar1, Zbar1, Zbar2, BTbar1, BTbar2;
MBt(s,t)$(FP(s) and ord(t) lt card(t))..ST(s,t+1)=E=ST(s,t)+sum(i$(s_in(s,i)),BT(i,t)*ro(s,i))+
	                   sum((i,tbar)$(s_out(s,i) and ord(tbar) eq PT(i)),BTbar(i,t,tbar)*ro(s,i)-dC(i,t,tbar))
			    -Dem(s,t)+STslackp(s,t)-STslackm(s,t);                          			    

BOt(s,t)$(FP(s) and ord(t) lt card(t))..BO(s,t+1)=E=BO(s,t)-Ship(s,t)+Dem(s,t);
Wbar1(i,t)$(ord(t)lt card(t))..Wbar(i,t+1,'1')=E=W(i,t)+dY(i,t,'1');
Wbar2(i,t,tbar)$(ord(tbar) gt 1 and ord(t) lt card(t))..Wbar(i,t+1,tbar)=E=sum(tbar1$(ord(tbar1) eq ord(tbar)-1),Wbar(i,t,tbar1)-dY(i,t,tbar1)-dZ(i,t,tbar1))+dY(i,t,tbar);
Xbar1(i,t)$(ord(t)lt card(t))..1*Xbar(i,t+1,'1')=E=1*X(i,t);
Zbar1(i,i1,t)$(not sameas(i,i1) and ord(t) lt card(t))..Zbar(i,i1,t+1,'1')=E=Z(i,i1,t);
Zbar2(i,i1,t,tbar)$(ord(tbar) gt 1 and not sameas(i,i1) and ord(t) lt card(t))..Zbar(i,i1,t+1,tbar)=E=sum(tbar1$(ord(tbar1) eq ord(tbar)-1),Zbar(i,i1,t,tbar1));
BTbar1(i,t)$(ord(t)lt card(t))..BTbar(i,t+1,'1')=E=BT(i,t)+dY(i,t,'1')*BTbar(i,t,'1');
BTbar2(i,t,tbar)$(ord(tbar) gt 1 and ord(t) lt card(t))..BTbar(i,t+1,tbar)=E=sum(tbar1$(ord(tbar1) eq ord(tbar)-1),BTbar(i,t,tbar1)-(dY(i,t,tbar1)+dZ(i,t,tbar1))*BTbar(i,t,tbar1))+dY(i,t,tbar)*BTbar(i,t,tbar);

*----------------------------------------------------------------------------------------------------*
*---------------------------------Initial Conditions-------------------------------------------------*
*Assign the initial state
Equations MB0,BO0t,Wbar0t,Xbar0t,BTbar0t,Zbar0t;

MB0(s)$(FP(s))..ST(s,'0')=E=ST0(s);
BO0t(s)$(FP(s))..BO(s,'0')=E=BO0(s);
Wbar0t(i,tbar).. Wbar(i,'0',tbar)=E=Wbar0(i,tbar);
Xbar0t(i).. Xbar(i,'0','1')=E=Xbar0(i,'1');
BTbar0t(i,tbar).. BTbar(i,'0',tbar)=E=BTbar0(i,tbar);
Zbar0t(i,i1,tbar)$(not sameas(i,i1)).. Zbar(i,i1,'0',tbar)=E=Zbar0(i,i1,tbar);

*-----------------------------------------------------------------------------------------------------*
*---------------------------------Terminal Conditions-------------------------------------------------*
*Fix the final state 
Equations selectK,fixpST,fixpW,fixpZ,fixpBT,fixpX;

selectK.. sum(k,PC(k))=E=1;
fixpW(i,t,tbar,tall)$(ord(t) eq card(t) and ord(tall) eq ord(tbar)   and TC eq 1)..Wbar(i,t,tbar)=E=sum(k,pW(i,k,tbar)*PC(k));
fixpZ(i,i1,t,tbar,tall)$(not sameas(i,i1) and ord(t) eq card(t) and ord(tall) eq ord(tbar)   and TC eq 1)..Zbar(i,i1,t,tbar)=E=sum(k,pZ(i,i1,k,tall)*PC(k));
fixpBT(i,t,tbar,tall)$(ord(t) eq card(t) and ord(tall) eq ord(tbar)  and TC eq 1)..BTbar(i,t,tbar)=E=sum(k,pBT(i,k,tall)*PC(k));
fixpX(i,t)$(ord(t) eq card(t) and TC eq 1)..Xbar(i,t,'1')=E=sum(k,pX(i,k)*PC(k));
fixpST(s,t)$(ord(t)eq card(t) and TC eq 1 and FP(s))..ST(s,t)=E=sum(k,pST(s,k)*PC(k));

*---------------------------------Objective function--------------------------------------------------*
Equations ObjFun;

ObjFun..J=E= (sum((s,t)$(FP(s)),h(s)*ST(s,t)) +
	     sum(t$(ord(t) le L),sum((i,i1)$(not sameas(i,i1)),Z(i,i1,t)*CHC(i,i1))))+
	     sum((t,i), 0.05*W(i,t))+
	     sum((s,t)$(FP(s)),1e5*STslackp(s,t)+1e5*STslackm(s,t)+BO(s,t)*1e2);

*-----------------------------------------------------------------------------------------------------*

*
MODEL STN /All/;

*OPTION SOLPRINT = OFF ;
*OPTION SYSOUT = OFF ;
OPTION LIMROW = 10000 ;
OPTION LIMCOL = 0 ;
OPTION RESLIM = 12000 ;
OPTION OPTCR = 0.01 ;
OPTION MIP = CPLEX ;


file sfile /S0.csv/;

STN.holdfixed = 1;
solve STN minimizing J using MIP;

display PC.l;
display W.l;
display Z.l;
display ST.l;
display BT.l;
display Ship.l;
display BTbar.l;
display Wbar.l;
display STslackp.l;
display STslackm.l;


*$ontext
*save data for next simulation
scalar bin;
put sfile ;
sfile.nd = 10;
loop(s$FP(s),
 put "ST0('"; put s.tl; put "')="; put ST.l(s,'1'); put ';'; put //;
 put "BO0('"; put s.tl; put "')="; put BO.l(s,'1'); put ';'; put //;	
);
loop((i,i1,tbar)$(not sameas(i,i1)),
 put "Wbar0('"; put i.tl; put "','"; put tbar.tl; put "')="; put Wbar.l(i,'1',tbar); put ';'; put //;
* put "Ybar0('"; put i.tl; put "','"; put tbar.tl; put "')="; put Ybar.l(i,'1',tbar); put ';'; put //;
 put "BTbar0('"; put i.tl; put "','"; put tbar.tl; put "')="; put BTbar.l(i,'1',tbar); put ';'; put //;
 put "Zbar0('"; put i.tl; put "','"; put i1.tl; put "','"; put tbar.tl; put "')="; put Zbar.l(i,i1,'1',tbar); put ';'; put //;
);
loop((i,tbar)$(ord(tbar) eq 1),
 put "Xbar0('"; put i.tl; put "','"; put tbar.tl; put "')="; put Xbar.l(i,'1',tbar); put ';'; put //;
);
scalar infeas1;
infeas1 = 0;
file statfile /status.csv/;
put statfile;
put STN.modelstat;
Put //;
put STN.solvestat;
put //;
infeas1 = 0;
loop(s$(FP(s)),
loop(t,
infeas1 = infeas1 + STslackp.l(s,t);
);
);
put infeas1;
put //;
infeas1 = 0;
loop(s$(FP(s)),
loop(t,
infeas1 = infeas1 + STslackm.l(s,t);
);
);
put infeas1;
put //;
loop((s,t)$(FP(s) and ord(t) eq 1),
 put STslackp.l(s,t);
 put //;
);
if(TC eq 1,
 loop(k$(PC.l(k) eq 1),
	 put k.tl
	 put //;
     );
);
putclose;
*$offtext

*File for making the Gantt charts
set color  /red,blue,lightorange,skyblue,tan1,lavender,black/;
parameter colorW(i,color);
colorW('TA','blue') = 1;
colorW('TB','red') = 1;

parameter colorZ(i,i1,color);
colorZ('TA','TB','skyblue') = 1;
colorZ('TB','TA','lightorange') = 1;

file g1 /gantt.dat/;
scalar endtime;
scalar starttime;
put g1;
g1.pc = 3;
loop(t$(ord(t) gt 1),
 if ((dZL(t) eq 1),
  starttime = ord(t)-1+Ctime;
  endtime = ord(t)-1+Ctime+1;
  put starttime; put " ";put endtime;put " "; put "gray(0.8)"; put //;	 
 );
 loop(i,
  if ((W.L(i,t) eq 1),
   starttime = ord(t)-1+Ctime;
   endtime = ord(t)-1+Ctime+PT(i);
   loop(color$(colorW(i,color) eq 1),
    put starttime; put " ";put endtime;put " "; put color.tl; put " "; put BT.L(i,t); put //;
   ); 	   
  );
 );
 loop((i,i1)$(not sameas(i,i1)),
  if ((Z.L(i,i1,t) eq 1),
   starttime = ord(t)-1+Ctime;
   endtime = ord(t)-1+Ctime+CHT(i,i1);
   loop(color$(colorZ(i,i1,color) eq 1),
    put starttime; put " ";put endtime;put" "; put color.tl; put " " ; put "-"; put //;
   );
  );
 );   
);
* at t = 0
loop((i,i1,tbar)$(not sameas(i,i1) and ord(tbar) lt PT(i)),
 if ((dY(i,'0',tbar) eq 1),
  starttime = Ctime;
  endtime = Ctime+1;
  put starttime; put " ";put endtime;put " lavender"; put //
 );
 if ((dZ(i,'0',tbar) eq 1),
  starttime = Ctime;
  endtime = Ctime+1;
  put starttime; put " ";put endtime;put " gray(0.8)"; put //
 );
 if ((Wbar0(i,tbar) eq 1 and ( (dY(i,'0',tbar) lt 1) ) ),
  starttime = Ctime;
  endtime = Ctime+PT(i)-ord(tbar);
  loop(color$(colorW(i,color) eq 1),
   put starttime; put " ";put endtime;put " "; put color.tl; put //;
  );
 );
*to get the correct times at which we need the task to be running
 if ((Wbar0(i,tbar) eq 1 and ( (dY(i,'0',tbar) eq 1) or (dZ(i,'0',tbar) eq 1) ) ),
  starttime = Ctime+1;
  endtime = Ctime+1+PT(i)-ord(tbar);
  loop(color$(colorW(i,color) eq 1),
   put starttime; put " ";put endtime;put " "; put color.tl; put BTbar0(i,tbar); put //;
  );
 );
 if ((W.L(i,'0') eq 1),
  starttime = Ctime;
  endtime = Ctime+PT(i);
  loop(color$(colorW(i,color) eq 1),
   put starttime; put " ";put endtime;put " "; put color.tl; put BT.L(i,'0'); put //;
  );
 ); 
 if ((Zbar0(i,i1,tbar) eq 1 and ord(tbar) lt CHT(i,i1)),
  starttime = Ctime;
  endtime = Ctime+CHT(i,i1)-ord(tbar);
  loop(color$(colorZ(i,i1,color) eq 1),
   put starttime; put " ";put endtime;put " "; put color.tl; put " "; put "-"; put //;
  );	 
 );
  if ((Z.L(i,i1,'0') eq 1),
  starttime = Ctime;
  endtime = Ctime+CHT(i,i1);
  loop(color$(colorZ(i,i1,color) eq 1),
   put starttime; put " ";put endtime;put " "; put color.tl; put " "; put "-"; put //;
  );	 
 ); 
);

if(dZL('0') eq 1,
 starttime = Ctime;
 endtime = starttime+1;
 put starttime; put " ";put endtime;put " gray(0.8)"; put //
);
putclose;


file inp /input.dat/;
scalar endtime;
scalar starttime;
put inp;
inp.pc = 3;
put "dummy"; put  //;
loop((i,i1)$(not sameas(i,i1)),
 if (W.L(i,'0') eq 1, put i.tl; put "="; put "W"; put BT.L(i,'0'););
 if (Z.L(i,i1,'0') eq 1, put i.tl;put "="; put "Z";put " -";);
);
putclose;


