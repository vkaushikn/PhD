function [z obj info] = optimize(mpc,parameter)
 or = 1-parameter.omega;
 oe = parameter.omega;
 LB = mpc.LB; UB = mpc.UB;
 Ain = mpc.Ain; bin_c = mpc.bin_c; bin_x = mpc.bin_x; bin_d = mpc.bin_d;
 H = or*mpc.H; qR_x =or*mpc.qR_x; qR_d = or*mpc.qR_d; qR_c = or*mpc.qR_c; qE = \
     oe*mpc.qE;
 x = parameter.x; d = parameter.d;
 %keyboard
 q = qE+qR_c+qR_x*x+qR_d*d;
 q = qR_x*x;
 bin = bin_c-bin_x*x-bin_d*d;
 if isfield(mpc,'qR_u')
  qR_u = or*mpc.qR_u;
  u = parameter.u;
  q = q+qR_u*u;
 end
 [z obj info] = qp([],H,q,[],[],LB,UB,[],Ain,bin);
 info;
end