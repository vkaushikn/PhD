$ontext
2 processes TA,TB
Costs include: Changeover cost
	       Holding cost of inventory
Minimum changeover time is also modeled
L is the "periodicity" in this code
$offtext


$offsymxref
$eolcom #

$setglobal no_of_day 1
*$EvalGlobal NoPer ceil(%no_of_day%*24)
$setglobal NoPer 19


SETS
t       time /0*%NoPer%/
i          tasks /TA,TB/
s          states /raw,A,B/
RM(s)      raw materials /raw/
FP(s)      finished products /A,B/
s_in(s,i)  if state s goes into task i
s_out(s,i) if state s comes out of task i
alias (i,i1)
alias (i,i2)
alias (t,t1)
;
*t is large set. Contol it with Horizon length L (parameter)

PARAMETERS
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
;


VARIABLES
W(i,t)      is 1 if batch of task i starts at time t
Y(i,t)      is 1 if batch of task i is running at time t
X(i,t)      is 1 if batch of task i is running at time t or the last batch run before idling was i
Z(i,i1,t)   is 1 if transition from i to i1 takes place at t
ST(s,t)     inventory of state s at time t
BT(i,t)     batch size
BO(s,t)     back order
Ship(s,t)
J           objective function
;

EQUATIONS
CHAss      Christos formulation (assignment)
BS         Sets the status of batch running or not (Y variable)
BSI1       Sets the status of last batch ran (X variable)
BSI2

BC1        Sets the changeover (Z variable)
BC2
BC3
BTS1       Sets the batch size
BTS2
MB         Sets inventory balance equation
BOt        Sets back order equation
ObjFun     Objective function
;

POSITIVE VARIABLE BT, ST, BO, Ship;
BINARY VARIABLE W,Y,X,Z;

*** SET THE PARAMETERS *******
PT('TA') = 3; PT('TB') = 2; PTmax = 3;
CHT('TA','TB') = 2;  CHT('TB','TA') = 2; CHTmax = 2;
L = %NoPer%+1 ;

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
display Dem;

*equations


Chass(t)..sum((i,t1)$(ord(t1) ge ord(t)-PT(i)+1 and ord(t1) le ord(t)), W(i,t1))+
	  sum((i,t1)$(ord(t1)ge L+ord(t)-PT(i)+1 and ord(t1)le L),W(i,t1))+
          sum((i,i1,t1)$(ord(t1) ge ord(t)-CHT(i,i1)+1 and ord(t1) le ord(t) and not sameas(i,i1)),Z(i,i1,t1))+
	  sum((i,i1,t1)$(ord(t1) ge L+ord(t)-CHT(i,i1)+1 and ord(t1) le L and not sameas(i,i1)),Z(i,i1,t1))
	  =L=1;

BS(i,t)..sum(t1$(ord(t1) ge ord(t)-PT(i)+1 and ord(t1) le ord(t)),W(i,t1))+
         sum(t1$(ord(t1) ge L+ord(t)-PT(i)+1 and ord(t1) le L),W(i,t1))=E=Y(i,t);

BSI1(i,t)..X(i,t) =G= Y(i,t);
BSI2(t)..sum(i,X(i,t))=E=1;

BC1(i,i1,t)$(not sameas(i,i1))..Z(i,i1,t)=L=X(i,t--1);
BC2(i,i1,t)$(not sameas(i,i1))..Z(i,i1,t)=L=X(i1,t);
BC3(i,i1,t)$(not sameas(i,i1))..Z(i,i1,t)=G=X(i,t--1)+X(i1,t)-1;



BTS1(i,t)..BT(i,t)=L=W(i,t)*BTmax(i);
BTS2(i,t)..BT(i,t)=G=W(i,t)*BTmin(i);

MB(s,t)$(FP(s))..ST(s,t++1)=E=ST(s,t)+sum(i$(s_in(s,i)),BT(i,t)*ro(s,i))+
	                    sum((i,t1)$(s_out(s,i) and ord(t1) eq ord(t)-PT(i)),BT(i,t1)*ro(s,i))+
                            sum((i,t1)$(s_out(s,i) and ord(t1) eq ord(t)-PT(i)+L and ord(t1) le L),BT(i,t1)*ro(s,i))-
			    Ship(s,t);

BOt(s,t)..BO(s,t++1)=E=BO(s,t)-Ship(s,t)+Dem(s,t);




ObjFun..J=E= (sum((s,t)$(FP(s)),h(s)*ST(s,t) + 100*BO(s,t)) +
	     sum(t$(ord(t) le L),sum((i,i1)$(not sameas(i,i1)),Z(i,i1,t)*CHC(i,i1))))+
	     sum((t,i), 0.05*W(i,t));



MODEL STN /CHASS, BS, BSI1, BSI2, BC1, BC2, BC3, BTS1, BTS2, MB, ObjFun, BOt/;

OPTION SOLPRINT = OFF ;
OPTION SYSOUT = OFF ;
OPTION LIMROW = 0 ;
OPTION LIMCOL = 0 ;
OPTION RESLIM = 12000 ;
OPTION OPTCR = 0.01 ;
OPTION MIP = CPLEX ;



solve STN minimizing J using MIP;
*solve STN1 minimixing J using MIP;
display W.L, Y.L, X.L, Z.L, BT.L, ST.L, Ship.L, BO.L;

scalar maxtime;
maxtime = max(CHTmax,PTmax);

* Write the peridoic solution
Set tall to store /1*10/;

file ps /PS.csv/;
put ps;
ps.nd = 5;

*put the steady state inventory at t
loop((t,s)$(FP(s)),
 put "pST('"; put s.tl;put "','";put t.tl;put "')=";put ST.l(s,t);put ";" //;
 put "pBO('"; put s.tl;put "','";put t.tl;put "')=";put BO.l(s,t);put ";" //;	
);

*put the steady state X at t
loop((t,t1,i)$((ord(t1) eq L and ord(t)-1 eq 0)or (ord(t1) eq ord(t)-1)),
 put "pX('";put i.tl;put "','";put t.tl;put "')=";put X.l(i,t1);put ";" //;
);


* put W(TA,t-tpast),W(TB,t-tpast),Z(TA,TB,t-tpast),Z(TB,TA,t-tpast),BT(TA,t-tpast),BT(TB,t-tpast)
scalar  tpast;
tpast = 1;
scalar tpast1;
tpast1 = 0;
while((tpast le maxtime),	
  loop((t,t1,tall,i,i1)$((ord(t1) eq ord(t)-tpast and ord(tall) eq tpast and not sameas(i,i1)) or (ord(t1) eq L+ord(t)-tpast and ord(t1) le L and ord(tall) eq tpast and not sameas(i,i1))),	  
    put "pW('"; put i.tl; put "','"; put t.tl; put "','";  put tall.tl;  put "')=";  put W.l(i,t1);  put ";" // ;
    put "pBT('"; put i.tl; put "','"; put t.tl; put "','";  put tall.tl;  put "')=";  put BT.l(i,t1);  put ";" //;
    put "pZ('"; put i.tl; put "','"; put i1.tl; put "','"; put t.tl; put "','";put tall.tl; put "')="; put Z.l(i,i1,t1); put ";" //;
    
  );
 tpast = tpast+1;
);





putclose;
scalar Ctime;
Ctime = 0;

##File for making the Gantt charts
file g1 /gantt_periodic.dat/;
scalar endtime;
put g1;
g1.pc = 3;
loop(t,
 loop(i$(W.L(i,t) eq 1),
  put 'U1 ';
  endtime = ord(t)-1+Ctime;
  put endtime;
  put ' ';
  endtime = Ctime+ord(t)-1+PT(i);
  put endtime;
  put ' ';
  put i.tl;
  if ((ord(t) lt card(t)), put ' red');
  if ((ord(t) eq card(t)), put ' red');
  put /;
 );
);



file g122 /iprofile_periodic.dat/;
put g122;
scalar actinv;
g122.nd = 2;
 loop(t,
  endtime = ord(t)-1+Ctime;
  put endtime;
  put ' ';
 loop(s$(FP(s)),
  actinv =  ST.L(s,t);
  put actinv;
  put ' ';
 );
  put //;
);
    