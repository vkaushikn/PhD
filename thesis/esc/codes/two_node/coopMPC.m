function [ res ] = coopMPC( cmpc,model,mpc)
%centMPC centralized MPC
options = optimset('Display','off');
options = optimset(options,'Diagnostics','off');
options = optimset(options,'Algorithm','interior-point-convex');
omega(1) = model.omega;
omega(2) = 1-omega(1);
A = model.A; B = model.B; nx = model.nx; nu = model.nu; Bd = model.Bd ;
d0 = model.distEstimate;
N = model.N;
d = repmat(d0,[N 1]);
simtime = model.simtime;
x0 = model.IC;
actD = model.actD;
SS = length(cmpc); pmax = model.pmax;
ws = model.ws ; %we have to send an initial warmstart to the function
 w = 1/SS;
res.X = [x0];
res.U = [];
res.info = [];
res.Xp = [];
res.V = [];
res.Z = [];

parameter.omega = omega(1);
parameter.d = d;
for k = 1:simtime
 parameter.x = x0;
 u = ws;  
 %check if ws is feasible or not
 lhs = mpc.Ain*ws;
 rhs = mpc.bin_c-mpc.bin_d*d-mpc.bin_x*x0;
 find(lhs>rhs)
 u1 = u;
 for p = 1:pmax
   for ss = 1:SS
    send_mpc = cmpc{ss};
    parameter.u = u(cmpc{ss}.ot);
    parameter.u0 = u(cmpc{ss}.uloc);
    [z1 obj info] = optimize(send_mpc,parameter);
    z1 = w*z1+(1-w)*u(cmpc{ss}.uloc);
    u1(cmpc{ss}.uloc) = z1;
    %u = u1(:);
   end
 end 
  u = u1(:);
  u0 = u;
  u = u(1:nu);
  xp = mpc.phi*x0+mpc.gam*u0+mpc.gamd*d;
  x0 = A*x0+B*u+Bd*actD(k);
  ws = [u0(nu+1:end);model.K*(xp(end-nx+1:end)-model.x_ss)+model.u_ss];  
  res.X = [res.X x0];
  res.U = [res.U u];
  res.info = [res.info info];
  res.V = [res.V obj];
  res.Z = [res.Z u0];
  res.Xp = [res.Xp xp];
end

