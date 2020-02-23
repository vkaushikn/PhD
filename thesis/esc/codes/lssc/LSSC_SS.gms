*sets: t,tbar,i,s,n,r,d,m
$include LSSC_SS.setfile


*network
$include LSSC.network

*costs
$include LSSC.costs
$include LSSC.weights

*constraints
$include LSSC.constraints
$include LSSC.targets

*demands
$include LSSC.nominal





Variables
	Ship(s,n,n1)
	Order(s,n,n1)
	Inv(s,n)
	BO(s,n,n1)
	ShipBar(s,n,n1,tbar)
	OrderBar(s,n,n1,tbar)
	ellE
	ellT
	ell;

Positive Variable Ship, Order, Inv, BO
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
	tracking
	Obj;

*fix ship and order to zero in unconnected nodes
loop((s,n,n1),
	if ((DN(s,n,n1) eq 0 and not sameas(n,n1)),
		Ship.fx(s,n,n1)=0;
		Order.fx(s,n1,n)=0;
	);
);
loop((s,r),
	Order.fx(s,r,r)=0;
);

loop((s,m), Ship.fx(s,m,m)=0;)

loop((s,d),
	Ship.fx(s,d,d)=0;
	Order.fx(s,d,d)=0;
);

*steady state equality
InvBM(s,m)..
	0=E= sum(tbar$(ord(tbar) eq tau(s,m,m)),Orderbar(s,m,m,tbar))-
	sum(n1$(DN(s,m,n1)eq 1),Ship(s,m,n1));
OrdBM(s,m,n1)$(DN(s,m,n1) eq 1)..
	0=E=Order(s,n1,m)-Ship(s,m,n1);
InvBR(s,r)..
	0=E= sum((n1,tbar)$(UP(s,r,n1) eq 1 and ord(tbar) eq tau(s,n1,r)),ShipBar(s,n1,r,tbar))-
	Ship(s,r,r);
OrdBR(s,r)..
	0=E=Dem(s,r)-Ship(s,r,r);
InvBD(s,d)..
	0=E=sum((n1,tbar)$(UP(s,d,n1) and ord(tbar) eq tau(s,n1,d)),ShipBar(s,n1,d,tbar))-
	sum(n1$(DN(s,d,n1) eq 1),Ship(s,d,n1));
OrdBD(s,d,n1)$(DN(s,d,n1) eq 1 )..
	0=E=Order(s,n1,d)-Ship(s,d,n1);

*steady state equality for lifted states
ShipLift0(s,n,n1,tbar)$(ord(tbar) eq 1)..
	ShipBar(s,n,n1,tbar)=E=Ship(s,n,n1);
ShipLift1(s,n,n1,tbar)$(ord(tbar) gt 1)..
	ShipBar(s,n,n1,tbar)=E=ShipBar(s,n,n1,tbar-1);
OrderLift0(s,n,n1,tbar)$(ord(tbar) eq 1)..
	OrderBar(s,n,n1,tbar)=E=Order(s,n,n1);
OrderLift1(s,n,n1,tbar)$(ord(tbar) gt 1)..
	OrderBar(s,n,n1,tbar)=E=OrderBar(s,n,n1,tbar-1);

*Constraint
Const(n)..sum(s,Inv(s,n))=L=InvUP(n);
*stage costs
economic.. ellE=E=eco/sE*(sum((s,n),EHoldingCost(s,n)*Inv(s,n)))+
	eco/sE*(sum((s,n,n1),EBackOrderCost(s,n)*BO(s,n,n1)))+
	eco/sE*(sum((s,n,n1),EShippingCost(s,n,n1)*Ship(s,n,n1)))+
	eco/sE*(sum((s,n,n1),EOrderingCost(s,n,n1)*Order(s,n,n1)));

tracking.. ellT=E=track/sT*(sum((s,n),THoldingCost(s,n)*(Inv(s,n)-invT(s,n))*(Inv(s,n)-invT(s,n))))+
	track/sT*(sum((s,n,n1),TBackOrderCost(s,n)*(BO(s,n,n1)-ordT(s,n))*(BO(s,n,n1)-ordT(s,n))))+
	track/sT*(sum((s,n,n1),TShippingCost(s,n,n1)*(Ship(s,n,n1)-shipT(s,n,n1))*(Ship(s,n,n1)-shipT(s,n,n1))))+
	track/sT*(sum((s,n,n1),TOrderingCost(s,n,n1)*(Order(s,n,n1)-orderT(s,n,n1))*(Order(s,n,n1)-orderT(s,n,n1))));

*objective
Obj.. ell =E= ellE+ellT;

MODEL SS /All/;

OPTION SOLPRINT = OFF ;
OPTION SYSOUT = OFF ;
OPTION LIMROW = 0 ;
OPTION LIMCOL = 0 ;
OPTION RESLIM = 12000 ;
OPTION OPTCR = 0.01 ;
OPTION NLP = COINIPOPT ;


SS.holdfixed = 1;
solve SS minimizing ell using NLP;

display Ship.L,  Order.L;
display ellE.L;
display Inv.L;
file targs /input.targets.eco/;
put targs;
targs.nd = 10;
targs.pc = 5;
put 's','n','n1','O','S';
put /
loop((s,n,n1),
	put s.tl, n.tl, n1.tl,Order.L(s,n,n1),Ship.L(s,n,n1);
	put /
);
putclose;

file scale /scale.ss/;
put scale;
scale.nd = 10;
scale.pc = 5;
scalar ellEN;
scalar ellTN;

ellTN = (sum((s,n),THoldingCost(s,n)*(Inv.L(s,n)-invT(s,n))*(Inv.L(s,n)-invT(s,n))))+
	(sum((s,n,n1),TBackOrderCost(s,n)*(BO.L(s,n,n1)-ordT(s,n))*(BO.L(s,n,n1)-ordT(s,n))))+
	(sum((s,n,n1),TShippingCost(s,n,n1)*(Ship.L(s,n,n1)-shipT(s,n,n1))*(Ship.L(s,n,n1)-shipT(s,n,n1))))+
	(sum((s,n,n1),TOrderingCost(s,n,n1)*(Order.L(s,n,n1)-orderT(s,n,n1))*(Order.L(s,n,n1)-orderT(s,n,n1))));
ellEN = (sum((s,n),EHoldingCost(s,n)*Inv.L(s,n)))+
	(sum((s,n,n1),EBackOrderCost(s,n)*BO.L(s,n,n1)))+
	(sum((s,n,n1),EShippingCost(s,n,n1)*Ship.L(s,n,n1)))+
	(sum((s,n,n1),EOrderingCost(s,n,n1)*Order.L(s,n,n1)));
put ellEN; put /;
put ellTN; put /;
putclose;

file ss11 /steadystate.ss/;
put ss11;
ss11.nd = 10;
ss11.pc = 5;

put 'type','prod','node','node1','tbar','val';
put /;
loop((s,n),
	put 'Inv', s.tl, n.tl, 0,0,Inv.L(s,n);
	put /;
	
);
loop((s,n,n1),
	put 'BO', s.tl, n.tl, n1.tl,0, BO.L(s,n,n1);
	put /;
);
loop((s,n,n1,tbar),
	put 'ShipBar', s.tl, n.tl, n1.tl, tbar.tl, ShipBar.L(s,n,n1,tbar);
	put /;
	put 'OrderBar', s.tl, n.tl, n1.tl, tbar.tl, OrderBar.L(s,n,n1,tbar);
	put /;
);

putclose;
     
     