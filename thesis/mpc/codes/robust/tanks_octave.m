load Model.dat
load Penalty.dat
load Constraint.dat
load sims.dat
%define the subsystems
constraint.barV = 100;
constraint.a = 1;
constraint.beta = 100;
sim.x0 = [-8;20]
sim.N = 15;
subsystem{1}.uloc = [1 2];
subsystem{2}.uloc = [3];

%make the centralized MPC matrices
nominal.Bd = eye(2);
nominal.nx = 2;
nominal.nu = 3;
nominal.nd = 2;
nominal.N = sim.N;
nominal.eps = sim.eps;
nominal.pmax = sim.pmax;
nominal.IC = sim.x0;
[mpc] = centralized(nominal,penalty,constraint);

%making the cooperative MPC matrices
[cmpc] = cooperative(mpc,subsystem);

%find an initial feasible warm-start distributedly
nominal.pmax = 1;
nominal.ws = zeros(nominal.N*3,1);
FLAG = 0;
iter = 0;
while (FLAG==0)
  %optimize from this really bad point
  u_next = coopMPC(cmpc,nominal,nominal.ws);
  %find out the cost
  cost = 1/2*u_next'*mpc.H*u_next + 1/2*nominal.IC'*mpc.QQ*nominal.IC ...
      + u_next'*mpc.q*nominal.IC;
  %check if the cost is less than \bar{V}
  if cost <= constraint.barV
    %double check, see the terminal cost
    bx = mpc.phi*nominal.IC+mpc.gam*u_next;
    xN = bx(end-nominal.nx+1:end);
    cost1 = 1/2*xN'*penalty.P*xN
    FLAG = 1;
    nominal.ws = u_next;
  else
    iter = iter + 1;
    nominal.ws = u_next;
  end
  if iter >300
    FLAG = 1;
  end
end
nominal.ws0 = nominal.ws;
%robust cooperative MPC
tsim = 0
z = sim.x0;
x = sim.x0;
res.x(:,1) = x;
res.z(:,1) = z;
while (tsim < sim.time)
  %find the input vector
  cost_z =  1/2*nominal.ws'*mpc.H*nominal.ws + 1/2*z'*mpc.QQ*z \
      + nominal.ws'*mpc.q*z;
  cost_x =  1/2*nominal.ws'*mpc.H*nominal.ws + 1/2*x'*mpc.QQ*x \
      + nominal.ws'*mpc.q*x;
  if cost_x <= cost_z
    z = x;
    flag = 1;
  else
    flag = 0;
  end
  nominal.IC = z;  
  v_next = coopMPC(cmpc,nominal,nominal.ws);
  Ncost_z =  1/2*v_next'*mpc.H*v_next + 1/2*z'*mpc.QQ*z \
     + v_next'*mpc.q*z;
  %find input
  v = v_next(1:nominal.nu);
  u = v + nominal.K*(x-z);
  %move forward nominal system
  z = nominal.A*z + nominal.B*v;
  %realize a disturbance
  d = [-0.1+rand*0.2;-5+rand*10];
  x = nominal.A*x + nominal.B*u + d;
  %find the warm start
  bz = mpc.phi*nominal.IC+mpc.gam*v_next;
  zN = bz(end-nominal.nx+1:end);
  cost1 = zN'*penalty.P*zN;
  vplus = nominal.K*zN;
  nominal.ws = [v_next(nominal.nu+1:end);vplus];
  res.costx(tsim+1) = cost_x;
  res.costz(tsim+1) = cost_z;
  res.reset(tsim+1) = flag;
  res.v(:,tsim+1) = v;
  res.u(:,tsim+1) = u;
  res.d(:,tsim+1) = d;
  res.x(:,tsim+2) = x;
  res.z(:,tsim+2) = z;
  tsim = tsim+1;  
end

results{1} = res;

# %modified algorithm with forced restart
sim.Restart = 10;
tsim = 0
z = sim.x0;
x = sim.x0;
res.x(:,1) = x;
res.z(:,1) = z;
last_reset = -100;
nominal.ws = nominal.ws0; %for the original state
cost1 = 0; %to set z=x for the first time!
while (tsim < sim.time)
  %find the input vector
  cost_z =  1/2*nominal.ws'*mpc.H*nominal.ws + 1/2*z'*mpc.QQ*z \
      + nominal.ws'*mpc.q*z;
  cost_x =  1/2*nominal.ws'*mpc.H*nominal.ws + 1/2*x'*mpc.QQ*x \
      + nominal.ws'*mpc.q*x;
  if cost_x <= cost_z
    z = x;
    flag = 1;
    last_reset = tsim;
  else
    if (tsim-last_reset)>=sim.Restart && cost_x <= constraint.barV && cost1 <= constraint.a
      z = x;
      last_reset = tsim;
      flag = 1;
    else
       flag = 0;
    end
  end
  nominal.IC = z;  
  v_next = coopMPC(cmpc,nominal,nominal.ws);
  Ncost_z =  1/2*v_next'*mpc.H*v_next + 1/2*z'*mpc.QQ*z \
     + v_next'*mpc.q*z;
  %find input
  v = v_next(1:nominal.nu);
  u = v + nominal.K*(x-z);
  %move forward nominal system
  z = nominal.A*z + nominal.B*v;
  x = nominal.A*x + nominal.B*u + results{1}.d(:,tsim+1);
  %find the warm start
  bz = mpc.phi*nominal.IC+mpc.gam*v_next;
  zN = bz(end-nominal.nx+1:end);
  cost1 = zN'*penalty.P*zN;
  vplus = nominal.K*zN;
  nominal.ws = [v_next(nominal.nu+1:end);vplus];
  res.costx(tsim+1) = cost_x;
  res.costz(tsim+1) = cost_z;
  res.reset(tsim+1) = flag;
  res.v(:,tsim+1) = v;
  res.u(:,tsim+1) = u;
  res.x(:,tsim+2) = x;
  res.z(:,tsim+2) = z;
  tsim = tsim+1;  
end

results{2} = res;


%for the plots:
t = 0:sim.time;
t1 =0:sim.time-1;

data1 = [t(:) results{1}.x(2,:)'+sim.xSS(2) \
	 results{1}.z(2,:)'+sim.xSS(2) \
	 (sim.xSS(2)+15)*ones(length(t),1) \
	 (sim.xSS(2)-15)*ones(length(t),1)];

data2 = [t1(:) results{1}.costx(:) results{1}.costz(:) \
	 constraint.barV*ones(length(t1),1)];


data3 = [t(:) results{2}.x(1,:)'+sim.xSS(1) \
	 results{2}.z(1,:)'+sim.xSS(1)\
	 (sim.xSS(1)+3.5)*ones(length(t),1) \
	 (sim.xSS(1)-3.5)*ones(length(t),1)];


data4 = [t1(:) results{2}.costx(:) results{2}.costz(:) \
	 constraint.barV*ones(length(t1),1)];

save  CL1.dat data1 data2
save  CL2.dat data3 data4 