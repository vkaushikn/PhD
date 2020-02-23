*sets: t,tbar,i,s,n,r,d,m
$include LSSC_SS.setfile


*network
$include LSSC.network

*objective
$include LSSC.costs

*constraints
$include LSSC.constraints

*demands
$include LSSC.nominal


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
;

Positive variable Ship,Order,Inv,BO;
Binary variable W,X,Z,Y;

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
	ProdCost
	terminalWbar
	terminalXbar
	terminalZbar
	
;
*loop((s,t,tpast),
*    Z.FX(s,s1,t)=0;
*    Zbar.FX(s,s,t,tpast)=0;
*);

*Xbar.FX('A','0','1')=1;
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

*Constraint
Const(n,t)..sum(s,Inv(s,n,t))=L=InvUP(n);

*Stage cost
economic(t).. ellE(t)=E=(sum((s,n),EHoldingCost(s,n)*Inv(s,n,t)))+
	     (sum((s,n,n1),EBackOrderCost(s,n)*BO(s,n,n1,t)))+
	     (sum((s,n,n1),EShippingCost(s,n,n1)*Ship(s,n,n1,t)))+
	     (sum((s,n,n1),EOrderingCost(s,n,n1)*Order(s,n,n1,t)));

ProdCost(t).. ellW(t)=E=sum(s, costW(s)*W(s,t))+sum((s,s1)$(not sameas(s,s1)),costZ(s,s1)*Z(s,s1,t));


*Terminal Constraint
terminalInv(s,n,t)$(ord(t) eq card(t)).. Inv(s,n,t)=E=Inv(s,n,'0');
terminalBO(s,n,n1,t)$(ord(t) eq card(t)).. BO(s,n,n1,t)=E=BO(s,n,n1,'0');
terminalShipBar(s,n,n1,t,tbar)$(ord(t) eq card(t))..ShipBar(s,n,n1,t,tbar)
    =E=ShipBar(s,n,n1,'0',tbar);
terminalOrderBar(s,n,n1,t,tbar)$(ord(t) eq card(t))..OrderBar(s,n,n1,t,tbar)
    =E=OrderBar(s,n,n1,'0',tbar);
terminalWbar(s,t,tpast)$(ord(t) eq card(t))..Wbar(s,t,tpast)
    =E=Wbar(s,'0',tpast);
terminalXbar(s,t,tpast)$(ord(t) eq card(t))..Xbar(s,t,tpast)
    =E=Xbar(s,'0',tpast);
terminalZbar(s,s1,t,tpast)$(ord(t) eq card(t))..Zbar(s,s1,t,tpast)
    =E=Zbar(s,s1,'0',tpast);

*Objective
Obj.. VN =E= sum((t),ellE(t)+ellW(t));



MODEL MPC /All/;

OPTION SOLPRINT = OFF ;
OPTION SYSOUT = OFF ;
OPTION LIMROW = 1000 ;
OPTION LIMCOL = 1000 ;
OPTION RESLIM = 12000 ;
OPTION OPTCR = 0.01 ;
OPTION MIP = CPLEX ;

MPC.holdfixed = 1;

solve MPC minimizing VN using MIP;

display BO.L, Inv.L, Ship.L, Order.L, OrderBar.L;
display W.L, Z.L;
*write the state to a csv file

file ss11 /steadystate.ss/;
put ss11;
ss11.nd = 10;
ss11.pc = 5;

put 'type','prod','node','node1','tbar','t','val';
put /;
loop((s,n,t),
	put 'Inv', s.tl, n.tl, 0,0,t.tl,Inv.L(s,n,t);
	put /;
	
);
loop((s,n,n1,t),
	put 'BO', s.tl, n.tl, n1.tl,0,t.tl, BO.L(s,n,n1,t);
	put /;
);
loop((s,n,n1,tbar,t),
	put 'ShipBar', s.tl, n.tl, n1.tl, tbar.tl, t.tl, ShipBar.L(s,n,n1,t,tbar);
	put /;
	put 'OrderBar', s.tl, n.tl, n1.tl, tbar.tl,t.tl, OrderBar.L(s,n,n1,t,tbar);
	put /;
);
loop((s,t,tpast),
        put 'Wbar',s.tl,0,0,tpast.tl,t.tl,Wbar.L(s,t,tpast);
        put /;
        put 'Xbar',s.tl,0,0,tpast.tl,t.tl,Xbar.L(s,t,tpast);
	put /;
	loop(s1,
	     put 'Zbar',s.tl,s1.tl,0,tpast.tl,t.tl,Zbar.L(s,s1,t,tpast);
	     put /;
	);
);
putclose;

scalar tend;
alias (t,t1);
file ss12 /steadystate.gantt/;
put ss12;
ss12.nd = 10;
ss12.pc = 5;
put 'prod','start','end','val';
put /;
loop((s,t),
    if ((W.L(s,t) gt 0),
	tend = ord(t)+PT(s);
	loop((m,t1)$(ord(t1) eq tend),
	    put s.tl,t.tl,t1.tl,Order.L(s,m,m,t);
	    put /;
	);
    );
);
putclose;

	

	

	





