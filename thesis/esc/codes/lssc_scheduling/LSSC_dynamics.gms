*sets: t,tbar,i,s,n,r,d,m
$include LSSC.setfile


*network
$include LSSC.network

*objective
$include LSSC.costs

*constraints
$include LSSC.constraints

*terminal constraint
$include LSSC.steadystate

*varies with simulation time!

*demands
$include LSSC.demands

*initial conditions
$include LSSC.initial






Variables
	Ship(s,n,n1,t) shipment made from n to n1
	Order(s,n,n1,t) orders placed from n1 to n
	Inv(s,n,t)
	BO(s,n,n1,t)
	ShipBar(s,n,n1,t,tbar)
	OrderBar(s,n,n1,t,tbar)
	ellE
	VN
	W(s,t)
	X(s,t)
	Z(s,s1,t)
	Y(s,t)
	Wbar(s,t,tpast)
	Xbar(s,t,tpast)
	Zbar(s,s1,t,tpast)
	ellW
	PC
;

Positive variable Ship,Order,Inv,BO;
Binary variable W,X,Z,Y,PC;

Equations
	InvBM
	InvBD
	InvBR
	OrdBM
	OrdBD
	OrdBR
	ShipLift0
	ShipLift1
	OrderLift0
	OrderLift1
	Inv0e
	Ord0e
	Shipe
	Ordere
	Const
	economic
	terminalInv
	terminalBO
	terminalShipBar
	terminalOrderBar
	Obj
	Chass
	BS
	BSI1
	BSI2
	BC1
	BC2
	BC3
	BTS1
	BTS2
	WLift0
	WLift1
	XLift0
	XLift1
	ZLift0
	ZLift1
	Wbare
	Xbare
	Zbare
	terminalPC
	terminalWbar
	terminalXbar
	terminalZbar
	ProdCost
;

*Assignment
Chass(t)$(ord(t) lt card(t))..sum(s,W(s,t))+ sum((s,s1)$(not sameas(s,s1)),Z(s,s1,t))+
          sum((s,tpast)$(ord (tpast) le PT(s)-1),Wbar(s,t,tpast))+
	  sum((s,s1,tpast)$(ord (tpast) le CHT(s,s1)-1 and not sameas(s,s1)),Zbar(s,s1,t,tpast))=L=1;
BS(s,t)$(ord(t) lt card(t)).. W(s,t)+ sum((tpast)$(ord (tpast) le PT(s)-1),Wbar(s,t,tpast))=E=Y(s,t);
BSI1(s,t)$(ord(t) lt card(t))..X(s,t) =G= Y(s,t);
BSI2(t)$(ord(t) lt card(t))..sum(s,X(s,t))=E=1;
BC1(s,s1,t)$(not sameas(s,s1) and ord(t) lt card(t))..Z(s,s1,t)=L=Xbar(s,t,'1');
BC2(s,s1,t)$(not sameas(s,s1) and ord(t) lt card(t))..Z(s,s1,t)=L=X(s1,t);
BC3(s,s1,t)$(not sameas(s,s1) and ord(t) lt card(t))..Z(s,s1,t)=G=Xbar(s,t,'1')+X(s1,t)-1;

BTS1(s,m,t)$(ord(t) lt card(t))..Order(s,m,m,t)=L=W(s,t)*BTmax(s)*10;
BTS2(s,m,t)$(ord(t) lt card(t))..Order(s,m,m,t)=G=W(s,t)*BTmin(s)*0;

*Dynamics
InvBM(s,m,t)$(ord(t) lt card(t))..
	Inv(s,m,t+1)=E=Inv(s,m,t)+ sum(tbar$(ord(tbar) eq PT(s)),OrderBar(s,m,m,t,tbar))-
	sum(n1$(DN(s,m,n1)eq 1),Ship(s,m,n1,t));
OrdBM(s,m,n1,t)$(ord(t) lt card(t) and DN(s,m,n1) eq 1)..
	BO(s,m,n1,t+1)=E=BO(s,m,n1,t)+Order(s,n1,m,t)-Ship(s,m,n1,t);
InvBR(s,r,t)$(ord(t) lt card(t))..
	Inv(s,r,t+1)=E=Inv(s,r,t)+sum((n1,tbar)$(UP(s,r,n1) eq 1 and ord(tbar) eq tau(s,n1,r)),ShipBar(s,n1,r,t,tbar))-
	Ship(s,r,r,t);
OrdBR(s,r,t)$(ord(t) lt card(t))..
	BO(s,r,r,t+1)=E=BO(s,r,r,t)+Dem(s,r,t)-Ship(s,r,r,t);
InvBD(s,d,t)$(ord(t) lt card(t))..
	Inv(s,d,t+1)=E=Inv(s,d,t)+sum((n1,tbar)$(UP(s,d,n1) and ord(tbar) eq tau(s,n1,d)),ShipBar(s,n1,d,t,tbar))-
	sum(n1$(DN(s,d,n1) eq 1),Ship(s,d,n1,t));
OrdBD(s,d,n1,t)$(ord(t) lt card(t) and DN(s,d,n1) eq 1)..
	BO(s,d,n1,t+1)=E=BO(s,d,n1,t)+Order(s,n1,d,t)-Ship(s,d,n1,t);

*Lifting
ShipLift0(s,n,n1,t,tbar)$(ord(tbar) eq 1 and ord(t) lt card(t))..
	ShipBar(s,n,n1,t+1,tbar)=E=Ship(s,n,n1,t);
ShipLift1(s,n,n1,t,tbar)$(ord(tbar) gt 1 and ord(t) lt card(t))..
	ShipBar(s,n,n1,t+1,tbar)=E=ShipBar(s,n,n1,t,tbar-1);
OrderLift0(s,n,n1,t,tbar)$(ord(tbar) eq 1 and ord(t) lt card(t))..
	OrderBar(s,n,n1,t+1,tbar)=E=Order(s,n,n1,t);
OrderLift1(s,n,n1,t,tbar)$(ord(tbar) gt 1 and ord(t) lt card(t))..
	OrderBar(s,n,n1,t+1,tbar)=E=OrderBar(s,n,n1,t,tbar-1);
WLift0(s,t)$(ord(t) lt card(t))..Wbar(s,t+1,'1')=E=W(s,t);
WLift1(s,t,tpast)$(ord(tpast) gt 1 and ord(t) lt
    card(t))..Wbar(s,t+1,tpast)=E=Wbar(s,t,tpast-1);
XLift0(s,t)$(ord(t) lt card(t))..Xbar(s,t+1,'1')=E=X(s,t);
XLift1(s,t,tpast)$(ord(tpast) gt 1 and ord(t) lt
    card(t))..Xbar(s,t+1,tpast)=E=Xbar(s,t,tpast-1);
ZLift0(s,s1,t)$(ord(t) lt card(t))..Zbar(s,s1,t+1,'1')=E=Z(s,s1,t);
ZLift1(s,s1,t,tpast)$(ord(tpast) gt 1 and ord(t) lt
    card(t))..Zbar(s,s1,t+1,tpast)=E=Zbar(s,s1,t,tpast-1);

*Initial states
Inv0e(s,n,t)$(ord(t) eq 1)..
	Inv(s,n,t)=E=Inv0(s,n);
Ord0e(s,n,n1,t)$(ord(t) eq 1)..
	BO(s,n,n1,t)=E=BO0(s,n,n1);
Shipe(s,n,n1,t,tbar)$(ord(t) eq 1)..
	ShipBar(s,n,n1,t,tbar)=E=ShipBar0(s,n,n1,tbar);
Ordere(s,n,n1,t,tbar)$(ord(t) eq 1)..
	OrderBar(s,n,n1,t,tbar)=E=OrderBar0(s,n,n1,tbar);
Wbare(s,t,tpast)$(ord(t) eq 1)..Wbar(s,t,tpast)=E=Wbar0(s,tpast);
Xbare(s,t,tpast)$(ord(t) eq 1)..Xbar(s,t,tpast)=E=Xbar0(s,tpast);
Zbare(s,s1,t,tpast)$(ord(t) eq 1)..Zbar(s,s1,t,tpast)=E=Zbar0(s,s1,tpast);

*Constraint
Const(n,t)..sum(s,Inv(s,n,t))=L=InvUP(n);

*Stage cost
economic(t).. ellE(t)=E=(sum((s,n),EHoldingCost(s,n)*Inv(s,n,t)))+
	     (sum((s,n,n1),EBackOrderCost(s,n)*BO(s,n,n1,t)))+
	     (sum((s,n,n1),EShippingCost(s,n,n1)*Ship(s,n,n1,t)))+
	     (sum((s,n,n1),EOrderingCost(s,n,n1)*Order(s,n,n1,t)));

ProdCost(t).. ellW(t)=E=sum(s, costW(s)*W(s,t))+sum((s,s1)$(not sameas(s,s1)),costZ(s,s1)*Z(s,s1,t));

*Terminal Constraint

terminalPC$(tc_on eq 1)..sum(k,PC(k))=E=1;
terminalInv(s,n,t)$(ord(t) eq card(t) and tc_on eq 1).. Inv(s,n,t)=E=sum(k,PC(k)*InvSS(s,n,k));
terminalBO(s,n,n1,t)$(ord(t) eq card(t) and tc_on eq 1 and stoc eq 0).. BO(s,n,n1,t)=E=sum(k,PC(k)*BOSS(s,n,n1,k));
terminalShipBar(s,n,n1,t,tbar)$(ord(t) eq card(t) and tc_on eq 1)..ShipBar(s,n,n1,t,tbar)
    =E=sum(k,PC(k)*ShipBarSS(s,n,n1,tbar,k));
terminalOrderBar(s,n,n1,t,tbar)$(ord(t) eq card(t) and tc_on eq 1)..OrderBar(s,n,n1,t,tbar)
    =E=sum(k,PC(k)*OrderBarSS(s,n,n1,tbar,k));
terminalWbar(s,t,tpast)$(ord(t) eq card(t) and tc_on eq 1)..Wbar(s,t,tpast)
    =E=sum(k,PC(k)*WbarSS(s,tpast,k));
terminalXbar(s,t,tpast)$(ord(t) eq card(t) and tc_on eq 1)..Xbar(s,t,tpast)
    =E=sum(k,PC(k)*XbarSS(s,tpast,k));
terminalZbar(s,s1,t,tpast)$(ord(t) eq card(t) and tc_on eq 1)..Zbar(s,s1,t,tpast)
    =E=sum(k,PC(k)*ZbarSS(s,s1,tpast,k));

*Objective
Obj.. VN =E= sum((t),ellE(t)+ellW(t));



MODEL MPC /All/;

OPTION SOLPRINT = OFF ;
OPTION SYSOUT = OFF ;
OPTION LIMROW = 0 ;
OPTION LIMCOL = 0 ;
OPTION RESLIM = 12000 ;
OPTION OPTCR = 0.01 ;
OPTION MIP = CPLEX;



solve MPC minimizing VN using MIP;
display W.L, Z.L;
display BO.L, Order.L, Ship.L, Dem;
*write the state to a csv file
file ss11 /nextstate.dynamic/;
put ss11;
ss11.nd = 10;
ss11.pc = 5;
put 'type','prod','node','node1','tbar','val';
put /;
loop((s,n),
	put 'Inv', s.tl, n.tl, 0,0,Inv.L(s,n,'1');
	put /;
);
loop((s,n,n1),
	put 'BO', s.tl, n.tl, n1.tl,0, BO.L(s,n,n1,'1');
	put /;
);
loop((s,n,n1,tbar),
	put 'ShipBar', s.tl, n.tl, n1.tl, tbar.tl, ShipBar.L(s,n,n1,'1',tbar);
	put /;
	put 'OrderBar', s.tl, n.tl, n1.tl, tbar.tl, OrderBar.L(s,n,n1,'1',tbar);
	put /;
);

loop((s,tpast),
	put 'Wbar', s.tl, 0, 0, tpast.tl, Wbar.L(s,'1',tpast);
	put /;
	put 'Xbar', s.tl, 0,0, tpast.tl, Xbar.L(s,'1',tpast);
	put /;
);
loop((s,s1,tpast),
	put 'Zbar', s.tl, s1.tl, 0, tpast.tl, Zbar.L(s,s1,'1',tpast);
	put /;
);
putclose;


*write the current-time data to a csv file
file cct /data.dynamics/;
put cct;
cct.nd = 10;
cct.pc = 5;
put 'type','prod','node','node1','val';
put /;
loop((s,n),
	put 'Inv',s.tl,n.tl,0,Inv.L(s,n,'0');
	put /;
);
loop((s,n,n1),
	if ((DN(s,n,n1) eq 1),
		put 'Ship',s.tl,n.tl,n1.tl,Ship.L(s,n,n1,'0');
		put /;
		put 'Order',s.tl,n1.tl,n.tl,Order.L(s,n1,n,'0');
		put /;
		put 'BO', s.tl,n.tl,n1.tl,BO.L(s,n,n1,'0');
		put /;
	);
);
loop((s,n,m),
	if (sameas(n,m),
		put 'Order',s.tl,n.tl,n.tl,Order.L(s,n,n,'0');
		put /;
	);
);
loop((s,n,r),
	if ((sameas(n,r)),
		put 'Ship',s.tl,n.tl,n.tl,Ship.L(s,n,n,'0');
		put /;
		put 'BO', s.tl,n.tl,n.tl,BO.L(s,n,n,'0');
		put /;
	);
	
);
loop((s),
	put 'W',s.tl,0,0,W.L(s,'0');
        put /;
        loop(s1 $ (not sameas(s,s1)),
	    put 'Z',s.tl,s1.tl,0,Z.L(s,s1,'0');
	    put /;
	);
);

putclose;

*write objective and status
scalar objfn;
file stts /status.dynamics/;
put stts;
stts.nd = 10;
stts.pc = 5;
put MPC.modelstat;
put /;
objfn =  ellE.L('0')+ellW.l('0');
put objfn;
putclose;
  




	

	

	





