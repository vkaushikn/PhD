function [z obj info] = optimize(mpc,parameter)
%options = optimset('Display','on');
%options = optimset(options,'Diagnostics','on');
%options = optimset(options,'TolFun',1e-9);
%options = optimset(options,'Algorithm','interior-point-convex');
LB = mpc.LB; UB = mpc.UB;
H = mpc.H;
qR_u = mpc.qR_u;
u = parameter.u_fix;
x = parameter.x;
q = mpc.q*x;
q = q(mpc.uloc) + qR_u*u; %part of u'gam'qqphi*x that depends on other
			  %input is removed
[z obj info] = qp(parameter.u0,H,q,[],[],LB,UB);
%quadprog(H,q,[],[],[],[],LB,UB,[],options);
info
end