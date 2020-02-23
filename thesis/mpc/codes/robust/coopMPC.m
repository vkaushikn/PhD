function [ u_next ] = coopMPC( cmpc,model, warm_start)
%options = optimset('Display','off');
%options = optimset(options,'Diagnostics','off');
%options = optimset(options,'Algorithm','interior-point-convex');
A = model.A; B = model.B;  Bd = model.Bd ;
nx = model.nx; nu = model.nu; 
N = model.N;
x0 = model.IC;
SS = length(cmpc); pmax = model.pmax;
ws = warm_start ; %we have to send an initial warmstart to the function
w = 1/SS;

parameter.x = x0;
u = ws;  
%warm start is always going to be feasible
u1 = u;
for p = 1:pmax
  for ss = 1:SS
    send_mpc = cmpc{ss};
    parameter.u_fix = u(cmpc{ss}.ot);%other subsystem inputs
    parameter.u0 = u(cmpc{ss}.uloc); %starting point for optimization
    [z1 obj info] = optimize(send_mpc,parameter);
    z1 = (1-w)*z1+(w)*u(cmpc{ss}.uloc); %convex combination
    u1(cmpc{ss}.uloc) = z1; %the updated inputs are stored in u1
  end
  u = u1(:); %the input after the step has been taken
end 
u = u1(:);
u_next = u;
end

