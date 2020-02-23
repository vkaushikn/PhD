*sets: t,tbar,i,s,n,r,d,m
$include LSSC.setfile


*network
$include LSSC.network

*objective
$include LSSC.costs
$include LSSC.weights


$include LSSC.constraints
$include LSSC.targets

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
	ellT
	VN
	
;

Parameter
	inv_next
	bo_next
	ship_toall
	total_order
	ShipFX(s,n)
	OrderFX(s,n)
;

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
*	Const
	economic
	tracking
	terminalInv
	terminalBO
	terminalShipBar
	terminalOrderBar
	SumShipping
	Obj
;

Positive variable Ship,Order,Inv,BO;

*Implement Policy
*Retailer observes demands and places orders
*works only for Retailer selling to 1 customer and ordering to 1 DC/Manuf-facility
loop((s,r),
	inv_next = Inv0(s,r)+sum((n1,tbar)$(UP(s,r,n1) eq 1 and ord(tbar) eq tau(s,n1,r)),ShipBar0(s,n1,r,tbar));
	if((inv_next-(Dem(s,r,'0')+BO0(s,r,r))) ge 0,
		ShipFX(s,r) = Dem(s,r,'0')+BO0(s,r,r);
		Ship.FX(s,r,r,'0') = ShipFX(s,r);
	else
		ShipFX(s,r) = inv_next;
		Ship.FX(s,r,r,'0') = ShipFX(s,r);
	);
	inv_next = inv_next-ShipFX(s,r);
	bo_next = BO0(s,r,r)-ShipFX(s,r)+Dem(s,r,'0');
	loop(n1$(UP(s,r,n1) eq 1),
		if(((inv_next-bo_next) ge 0.7*InvSS(s,r)),
			OrderFX(s,r)=0;
			Order.FX(s,r,n1,'0')=OrderFX(s,r);
		else
			OrderFX(s,r)= InvSS(s,r)-(inv_next-bo_next);
			Order.FX(s,r,n1,'0')=OrderFX(s,r);
		);
	);
);


*Distributor observes the retailer orders and makes its decisions
loop((s,d),
	total_order = sum(n1$(DN(s,d,n1) eq 1), OrderFX(s,n1));
	inv_next =Inv0(s,d)+sum((n1,tbar)$(UP(s,d,n1) eq 1 and ord(tbar) eq tau(s,n1,d)),ShipBar0(s,n1,d,tbar));
	if((inv_next-sum(n1$(DN(s,d,n1) eq 1), BO0(s,d,n1))-total_order) gt 0,
		ShipFX(s,d) = total_order + sum(n1$(DN(s,d,n1) eq 1), BO0(s,d,n1));
	else
		ShipFX(s,d) = inv_next;
	);
	inv_next = inv_next-ShipFX(s,d);
	bo_next = sum(n1$(DN(s,d,n1) eq 1), BO0(s,d,n1))-ShipFX(s,d)+total_order;
	loop(n1$(UP(s,d,n1) eq 1),
		if(((inv_next-bo_next) ge 0.7*InvSS(s,d)),
			OrderFX(s,d)=0;
		else
			OrderFX(s,d)= InvSS(s,d)-(inv_next-bo_next);
		);
		Order.FX(s,d,n1,'0')=OrderFX(s,d);
	);
);


*manufacturerer does not do (s,S)
*Dynamics
InvBM(s,m,t)$(ord(t) lt card(t))..
	Inv(s,m,t+1)=E=Inv(s,m,t)+ sum(tbar$(ord(tbar) eq tau(s,m,m)),OrderBar(s,m,m,t,tbar))-
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

*Initial states
Inv0e(s,n,t)$(ord(t) eq 1)..
	Inv(s,n,t)=E=Inv0(s,n);
Ord0e(s,n,n1,t)$(ord(t) eq 1)..
	BO(s,n,n1,t)=E=BO0(s,n,n1);
Shipe(s,n,n1,t,tbar)$(ord(t) eq 1)..
	ShipBar(s,n,n1,t,tbar)=E=ShipBar0(s,n,n1,tbar);
Ordere(s,n,n1,t,tbar)$(ord(t) eq 1)..
	OrderBar(s,n,n1,t,tbar)=E=OrderBar0(s,n,n1,tbar);

*Constraint
*Const(n,t)..sum(s,Inv(s,n,t))=L=InvUP(n);

*Stage cost
economic(t).. ellE(t)=E=eco/sE*(sum((s,n),EHoldingCost(s,n)*Inv(s,n,t)))+
	     eco/sE*(sum((s,n,n1),EBackOrderCost(s,n)*BO(s,n,n1,t)))+
	     eco/sE*(sum((s,n,n1),EShippingCost(s,n,n1)*Ship(s,n,n1,t)))+
	     eco/sE*(sum((s,n,n1),EOrderingCost(s,n,n1)*Order(s,n,n1,t)));

tracking(t).. ellT(t)=E=track/sT*(sum((s,n),THoldingCost(s,n)*(Inv(s,n,t)-invT(s,n))*(Inv(s,n,t)-invT(s,n))))+
	     track/sT*(sum((s,n,n1),TBackOrderCost(s,n)*(BO(s,n,n1,t)-ordT(s,n))*(BO(s,n,n1,t)-ordT(s,n))))+
	     track/sT*(sum((s,n,n1),TShippingCost(s,n,n1)*(Ship(s,n,n1,t)-shipT(s,n,n1))*(Ship(s,n,n1,t)-shipT(s,n,n1))))+
	     track/sT*(sum((s,n,n1),TOrderingCost(s,n,n1)*(Order(s,n,n1,t)-orderT(s,n,n1))*(Order(s,n,n1,t)-orderT(s,n,n1))));

*Terminal Constraint
terminalInv(s,n,t)$(ord(t) eq card(t)).. Inv(s,n,t)=E=InvSS(s,n);
terminalBO(s,n,n1,t)$(ord(t) eq card(t)).. BO(s,n,n1,t)=E=BOSS(s,n,n1);
terminalShipBar(s,n,n1,t,tbar)$(ord(t) eq card(t))..ShipBar(s,n,n1,t,tbar)=E=ShipBarSS(s,n,n1,tbar);
terminalOrderBar(s,n,n1,t,tbar)$(ord(t) eq card(t))..OrderBar(s,n,n1,t,tbar)=E=OrderBarSS(s,n,n1,tbar);

*SS policy fixing
SumShipping(s,d).. sum(n1$DN(s,d,n1),Ship(s,d,n1,'0'))=E=ShipFX(s,d);


*Objective
Obj.. VN =E= sum((t),ellE(t)+ellT(t));



MODEL MPC /All/;

OPTION SOLPRINT = OFF ;
OPTION SYSOUT = OFF ;
OPTION LIMROW = 0 ;
OPTION LIMCOL = 0 ;
OPTION RESLIM = 12000 ;
OPTION OPTCR = 0.01 ;
OPTION NLP = COINIPOPT ;



solve MPC minimizing VN using NLP;

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
putclose;

scalar objfn
*write objective and status
file stts /status.dynamics/;
put stts;
stts.nd = 10;
stts.pc = 5;
put MPC.modelstat;
put /;
objfn =ellE.L('0')+ellT.L('0');
put objfn;
putclose;