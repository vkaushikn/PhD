load B0.dat;
load Bd1.dat;
load B1.dat;
load B2.dat;
load ssdata1;

[model.nx0 model.nu0] = size(B0);
[model.nx0 model.nd0] = size(Bd1);
model.A = [eye(model.nx0) B1 B2;...
           zeros(model.nu0,model.nx0)  zeros(model.nu0)	   zeros(model.nu0);...
           zeros(model.nu0,model.nx0)  eye(model.nu0)      zeros(model.nu0)];
model.B = [B0;eye(model.nu0);zeros(model.nu0)]; model.Bd = [Bd1;zeros(model.nu0,model.nd0);zeros(model.nu0,model.nd0)];

[model.nx model.nu] = size(model.B);
[model.nx model.nd] = size(model.Bd);
model.nlifted = 2*model.nu0; % number of lifted states
model.N = 15;
model.eps = 1e-6;
model.nominal = [10;10;10;10];

constraint.uub = [20;20;200;20;20;200;20;20;200;20;200;20;200;20;200;20;200];
constraint.ulb = zeros(model.nu,1);

model.IC = [40;0;37;0;38;0;28;0;39;0;29;0;36;0];

model.x_s = [35;0;45;0;45;0;30;0;35;0;25;0;30;0];
model.u_s = model.nominal(1)*ones(model.nu,1);
model.x_s = [model.x_s;model.u_s;model.u_s]; %This is the "set-point"
				%from which we penalize in the stage-cost.
model.IC =[model.IC;model.u_s;model.u_s];
model.IC = model.IC-model.x_s;
constraint.uub = [20;20;200;20;20;200;20;20;200;20;200;20;200;20;200;20;200]-model.u_s;
constraint.ulb = zeros(model.nu,1)-model.u_s;

penalty.cx = ones(model.nx,1);
penalty.cu = ones(model.nu,1);
penalty.cxt = ones(model.nx,1);
penalty.Q = diag(repmat([1;10],[SS,1]));
penalty.Q = blkdiag(penalty.Q,zeros(2*model.nu));
penalty.R = eye(model.nu);
penalty.scale_eco = 1;
penalty.scale_risk = 1;
[K P E] = dlqr(model.A,[model.B],penalty.Q,penalty.R);
penalty.P = (5000/50)*P;% ones(model.nx);
model.K = -K;


terminal.T = [];
terminal.t = [];

[mpc] = centralized(model,penalty,constraint,terminal);
[cmpc] = cooperative(mpc,subsystem);
 
retailer = parallel_retailer;
distributor = parallel_distributor;
manufacturer = 1;

parameter.omega = 0; % pure tracking
or = 1-parameter.omega;
oe = parameter.omega;


function V_cent = evalfun(model,penalty,mpc,parameter,z)
or = 1-parameter.omega;
oe = parameter.omega;
V_cent = (1/2*((model.IC)'*penalty.Q*(model.IC))+...
         1/2*(mpc.phi*model.IC+mpc.gam*z)'*mpc.QQ*(mpc.phi*model.IC+mpc.gam*z)+...
         1/2*(z)'*mpc.RR*(z));
end
%centralized
parameter.x = model.IC;
parameter.d = repmat(model.nominal,[model.N 1]);
[z obj info] = optimize(mpc,parameter);
V_cent = evalfun(model,penalty,mpc,parameter,z);
u_cent = z;
%cooperative
%GS-GJ parallel
pmax = 100;
u = zeros(model.N*model.nu,1);
u1 = u;
U_PS(:,1) = u;
V_PS(1) = evalfun(model,penalty,mpc,parameter,u);

for p = 1:pmax
 w = 1/length(retailer);
 for ss = 1:length(retailer)
  send_mpc = cmpc{retailer(ss)};
  parameter.u = u(cmpc{retailer(ss)}.ot);
  [z1 obj info] = optimize(send_mpc,parameter); 
  z1 = w*z1+(1-w)*u(cmpc{retailer(ss)}.uloc);
  u1(cmpc{retailer(ss)}.uloc) = z1;
 end
 u = u1;
 w = 1/length(distributor);
 for ss = 1:length(distributor)
  send_mpc = cmpc{distributor(ss)};
  parameter.u = u(cmpc{distributor(ss)}.ot);
  [z1 obj info] = optimize(send_mpc,parameter);
  z1 = w*z1+(1-w)*u(cmpc{distributor(ss)}.uloc);
  u1(cmpc{distributor(ss)}.uloc) = z1;
 end
 u = u1;
 w = 1/length(manufacturer);
  for ss = 1:length(manufacturer)
  send_mpc = cmpc{manufacturer(ss)};
  parameter.u = u(cmpc{manufacturer(ss)}.ot);
  [z1 obj info] = optimize(send_mpc,parameter);
  z1 = w*z1+(1-w)*u(cmpc{manufacturer(ss)}.uloc);
  u1(cmpc{manufacturer(ss)}.uloc) = z1;
 end
 u = u1;
 %calculate cost
 z = u;
 V_PS(p+1) = evalfun(model,penalty,mpc,parameter,z);
 U_PS(:,p+1) = u;
end 

%GJ only

u = zeros(model.N*model.nu,1);
u1 = u;
V_PP(1) = evalfun(model,penalty,mpc,parameter,u);
U_PP(:,1) = u;
for p = 1:pmax
 w = 1/(length(retailer)+length(manufacturer)+length(distributor));
 for ss = 1:SS
  send_mpc = cmpc{ss};
  parameter.u = u(cmpc{ss}.ot);
  [z1 obj info] = optimize(send_mpc,parameter);
  z1 = w*z1+(1-w)*u(cmpc{ss}.uloc);
  u1(cmpc{ss}.uloc) = z1;
 end
 u = u1;
 %calculate cost
 z = u;
 V_PP(p+1) = evalfun(model,penalty,mpc,parameter,z);
 U_PP(:,p+1) = u;
end 

% GS only

u = zeros(model.N*model.nu,1);
u1 = u;
U_GS(:,1) = u;
V_GS(1) =  evalfun(model,penalty,mpc,parameter,u)
for p = 1:pmax
 w = 1/(length(retailer)+length(manufacturer)+length(distributor));
 for ss = 1:SS
  send_mpc = cmpc{ss};
  parameter.u = u(cmpc{ss}.ot);
  [z1 obj info] = optimize(send_mpc,parameter);
  z1 = 1*z1+(1-1)*u(cmpc{ss}.uloc);
  u1(cmpc{ss}.uloc) = z1;
  u = u1;
 end

 %calculate cost
 z = u;
 V_GS(p+1) =  evalfun(model,penalty,mpc,parameter,z);
 U_GS(:,p+1) = u;
end 




l = length(V_PP);
V_C = repmat(V_cent,[l 1]);

plot(1:l,V_PS,'r',1:l,V_PP,'b',1:l,V_GS,'g',1:l,V_C,'k')
legend('GS-GJ','GJ','GS','cent')

l = 1:l;
%save data
data0 = [l(:) V_PS(:) V_PP(:) V_GS(:) V_C(:)];
#save -ascii iterate.dat data


#### Closed loop simulation for this problem

#First is centralized
sim_time = 10;
model.IC0 = model.IC;
cent.X = model.IC + model.x_s;
cent.U = [];

for k = 1:sim_time
  parameter.x = cent.X(:,k) - model.x_s;
  parameter.d = repmat(model.nominal,[model.N 1]);
  [z obj info] = optimize(mpc,parameter);
  u = z(1:model.nu);
  cent.X(:,k+1) = model.A*parameter.x+ model.B*u + model.x_s;
  cent.U(:,k) = u+model.u_s;
  model.IC = parameter.x;
  cent.V(k) = evalfun(model,penalty,mpc,parameter,z);
  cent.l(k) = (parameter.x'*penalty.Q*parameter.x) +( u'*penalty.R*u);
endfor

#GS-Jacobi
pmax = 1;
u = zeros(model.N*model.nu,1);
u1 = u;
coop.X = model.IC0+ model.x_s;
coop.U = [];
for k = 1:sim_time
    if k == 1
      pmax = 200; #to find a feasible point at k=1
      u = zeros(model.N*model.nu,1);
      model.IC = coop.X(:,k) - model.x_s;
      parameter.x =  coop.X(:,k) - model.x_s;
      u1 = u;
      firsttime = 0;
     else
      #find warmstart
      xN = mpc.phi*parameter.x + mpc.gam*z;
      uN = model.K*xN(end-model.nx+1:end);
      u = [z(model.nu+1:end);uN];
      u1 = u;
      #just check if we are okay
      parameter.x =  coop.X(:,k) - model.x_s;
      model.IC = parameter.x;
      V_PS = evalfun(model,penalty,mpc,parameter,u);
      #V_PS
      #pause
      pmax =1;
    end
    #Find input   
    p = 0;
    while (p <=pmax)
        w = 1/length(retailer);
	for ss = 1:length(retailer)
	  send_mpc = cmpc{retailer(ss)};
	  parameter.u = u(cmpc{retailer(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter); 
	  z1 = w*z1+(1-w)*u(cmpc{retailer(ss)}.uloc);
	  u1(cmpc{retailer(ss)}.uloc) = z1;
	end
	u = u1;
	w = 1/length(distributor);
	for ss = 1:length(distributor)
	  send_mpc = cmpc{distributor(ss)};
	  parameter.u = u(cmpc{distributor(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter);
	  z1 = w*z1+(1-w)*u(cmpc{distributor(ss)}.uloc);
	  u1(cmpc{distributor(ss)}.uloc) = z1;
	end
	u = u1;
	w = 1/length(manufacturer);
	for ss = 1:length(manufacturer)
	  send_mpc = cmpc{manufacturer(ss)};
	  parameter.u = u(cmpc{manufacturer(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter);
	  z1 = w*z1+(1-w)*u(cmpc{manufacturer(ss)}.uloc);
	  u1(cmpc{manufacturer(ss)}.uloc) = z1;
	end
	u = u1;
	%lets quit if we have a feasible solution
	z = u;
	V_PS = evalfun(model,penalty,mpc,parameter,z);
	#if V_PS <=5000 && k==1 && firsttime == 0
	#  %z is a feasible point
	#  p = 199; #do one iteration
	#  firsttime = 1;
	#  #keyboard
	#endif
	p+=1;
    endwhile
    u = z(1:model.nu);
    coop.X(:,k+1) = model.A*parameter.x+ model.B*u + model.x_s;
    coop.U(:,k) = u+model.u_s;
    coop.V(k) = evalfun(model,penalty,mpc,parameter,z);
    coop.l(k) = (parameter.x'*penalty.Q*parameter.x) +( u'*penalty.R*u);
    #find warm start
end 

##Jacobi 
pmax = 1;
u = zeros(model.N*model.nu,1);
u1 = u;
coopJ.X = model.IC0+ model.x_s;
coopJ.U = [];
for k = 1:sim_time
    if k == 1
      pmax = 1; #to find a feasible point at k=1
      model.IC = coopJ.X(:,k) - model.x_s;
      parameter.x =  coopJ.X(:,k) - model.x_s;
      [z obj info] = optimize(mpc,parameter);
      u = z;
      u1 = u;
      firsttime = 0;
     else
      #find warmstart
      xN = mpc.phi*parameter.x + mpc.gam*z;
      uN = model.K*xN(end-model.nx+1:end);
      u = [z(model.nu+1:end);uN];
      u1 = u;
      #just check if we are okay
      parameter.x =  coopJ.X(:,k) - model.x_s;
      model.IC = parameter.x;
      V_PS = evalfun(model,penalty,mpc,parameter,u);
      #V_PS
      #pause
      pmax =1;
    end
    #Find input   
    p = 0;
    while (p <=pmax)
        w = 1/SS;
	for ss = 1:length(retailer)
	  send_mpc = cmpc{retailer(ss)};
	  parameter.u = u(cmpc{retailer(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter); 
	  z1 = w*z1+(1-w)*u(cmpc{retailer(ss)}.uloc);
	  u1(cmpc{retailer(ss)}.uloc) = z1;
	end
	for ss = 1:length(distributor)
	  send_mpc = cmpc{distributor(ss)};
	  parameter.u = u(cmpc{distributor(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter);
	  z1 = w*z1+(1-w)*u(cmpc{distributor(ss)}.uloc);
	  u1(cmpc{distributor(ss)}.uloc) = z1;
	end
	for ss = 1:length(manufacturer)
	  send_mpc = cmpc{manufacturer(ss)};
	  parameter.u = u(cmpc{manufacturer(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter);
	  z1 = w*z1+(1-w)*u(cmpc{manufacturer(ss)}.uloc);
	  u1(cmpc{manufacturer(ss)}.uloc) = z1;
	end
	u = u1;
	%lets quit if we have a feasible solution
	z = u;
	V_PS = evalfun(model,penalty,mpc,parameter,z);
	#if V_PS <=5000 && k==1 && firsttime == 0
	#  %z is a feasible point
	#  p = 199; #do one iteration
	#  firsttime = 1;
	#  #keyboard
	#endif
	p+=1;
    endwhile
    u = z(1:model.nu);
    coopJ.X(:,k+1) = model.A*parameter.x+ model.B*u + model.x_s;
    coopJ.U(:,k) = u+model.u_s;
    coopJ.V(k) = evalfun(model,penalty,mpc,parameter,z);
    coopJ.l(k) = (parameter.x'*penalty.Q*parameter.x) +( u'*penalty.R*u);
    #find warm start
end 

#from the first time feasibility is attained

pmax = 1;
u = zeros(model.N*model.nu,1);
u1 = u;
coop1.X = model.IC0+ model.x_s;
coop1.U = [];
for k = 1:sim_time
    if k == 1
      pmax = 200; #to find a feasible point at k=1
      u = zeros(model.N*model.nu,1);
      model.IC = coop1.X(:,k) - model.x_s;
      parameter.x =  coop1.X(:,k) - model.x_s;
      u1 = u;
      firsttime = 0;
     else
      #find warmstart
      xN = mpc.phi*parameter.x + mpc.gam*z;
      uN = model.K*xN(end-model.nx+1:end);
      u = [z(model.nu+1:end);uN];
      u1 = u;
      #just check if we are okay
      parameter.x =  coop1.X(:,k) - model.x_s;
      model.IC = parameter.x;
      V_PS = evalfun(model,penalty,mpc,parameter,u);
      #V_PS
      #pause
      pmax =1;
    end
    #Find input   
    p = 0;
    while (p <=pmax)
        w = 1/length(retailer);
	for ss = 1:length(retailer)
	  send_mpc = cmpc{retailer(ss)};
	  parameter.u = u(cmpc{retailer(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter); 
	  z1 = w*z1+(1-w)*u(cmpc{retailer(ss)}.uloc);
	  u1(cmpc{retailer(ss)}.uloc) = z1;
	end
	u = u1;
	w = 1/length(distributor);
	for ss = 1:length(distributor)
	  send_mpc = cmpc{distributor(ss)};
	  parameter.u = u(cmpc{distributor(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter);
	  z1 = w*z1+(1-w)*u(cmpc{distributor(ss)}.uloc);
	  u1(cmpc{distributor(ss)}.uloc) = z1;
	end
	u = u1;
	w = 1/length(manufacturer);
	for ss = 1:length(manufacturer)
	  send_mpc = cmpc{manufacturer(ss)};
	  parameter.u = u(cmpc{manufacturer(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter);
	  z1 = w*z1+(1-w)*u(cmpc{manufacturer(ss)}.uloc);
	  u1(cmpc{manufacturer(ss)}.uloc) = z1;
	end
	u = u1;
	%lets quit if we have a feasible solution
	z = u;
	V_PS = evalfun(model,penalty,mpc,parameter,z);
	if V_PS <=5000 && k==1 && firsttime == 0
	  %z is a feasible point
	  p = 199; #do one iteration
	  firsttime = 1;
	  #keyboard
	endif
	p+=1;
    endwhile
    if k==1
      zstartGSJ = z;
    end
    u = z(1:model.nu);
    coop1.X(:,k+1) = model.A*parameter.x+ model.B*u + model.x_s;
    coop1.U(:,k) = u+model.u_s;
    coop1.V(k) = evalfun(model,penalty,mpc,parameter,z);
    coop1.l(k) = (parameter.x'*penalty.Q*parameter.x) +( u'*penalty.R*u);
end 

##Jacobi-Suboptimal
pmax = 1;
u = zeros(model.N*model.nu,1);
u1 = u;
coopJ1.X = model.IC0+ model.x_s;
coopJ1.U = [];
for k = 1:sim_time
    if k == 1
      pmax = 1; #to find a feasible point at k=1
      model.IC = coopJ1.X(:,k) - model.x_s;
      parameter.x =  coopJ1.X(:,k) - model.x_s;
      u = zstartGSJ;
      u1 = u;
      firsttime = 0;
     else
      #find warmstart
      xN = mpc.phi*parameter.x + mpc.gam*z;
      uN = model.K*xN(end-model.nx+1:end);
      u = [z(model.nu+1:end);uN];
      u1 = u;
      #just check if we are okay
      parameter.x =  coopJ1.X(:,k) - model.x_s;
      model.IC = parameter.x;
      V_PS = evalfun(model,penalty,mpc,parameter,u);
      #V_PS
      #pause
      pmax =1;
    end
    #Find input   
    p = 0;
    while (p <=pmax)
        w = 1/SS;
	for ss = 1:length(retailer)
	  send_mpc = cmpc{retailer(ss)};
	  parameter.u = u(cmpc{retailer(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter); 
	  z1 = w*z1+(1-w)*u(cmpc{retailer(ss)}.uloc);
	  u1(cmpc{retailer(ss)}.uloc) = z1;
	end
	for ss = 1:length(distributor)
	  send_mpc = cmpc{distributor(ss)};
	  parameter.u = u(cmpc{distributor(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter);
	  z1 = w*z1+(1-w)*u(cmpc{distributor(ss)}.uloc);
	  u1(cmpc{distributor(ss)}.uloc) = z1;
	end
	for ss = 1:length(manufacturer)
	  send_mpc = cmpc{manufacturer(ss)};
	  parameter.u = u(cmpc{manufacturer(ss)}.ot);
	  [z1 obj info] = optimize(send_mpc,parameter);
	  z1 = w*z1+(1-w)*u(cmpc{manufacturer(ss)}.uloc);
	  u1(cmpc{manufacturer(ss)}.uloc) = z1;
	end
	u = u1;
	%lets quit if we have a feasible solution
	z = u;
	V_PS = evalfun(model,penalty,mpc,parameter,z);
	#if V_PS <=5000 && k==1 && firsttime == 0
	#  %z is a feasible point
	#  p = 199; #do one iteration
	#  firsttime = 1;
	#  #keyboard
	#endif
	p+=1;
    endwhile
    u = z(1:model.nu);
    coopJ1.X(:,k+1) = model.A*parameter.x+ model.B*u + model.x_s;
    coopJ1.U(:,k) = u+model.u_s;
    coopJ1.V(k) = evalfun(model,penalty,mpc,parameter,z);
    coopJ1.l(k) = (parameter.x'*penalty.Q*parameter.x) +( u'*penalty.R*u);
    #find warm start
end 

t = 0:length(cent.V)-1;
data = [t(:) cent.V(:) coop.V(:) coopJ1.V(:) coop1.V(:)];
data1 = [t(:) cent.l(:) coop.l(:) coopJ.l(:) coop1.l(:)];
t = 0:sim_time;
data2 = [t(:) cent.X(1,:)' coop.X(1,:)' coopJ.X(1,:)' coop1.X(1,:)'];
data3 = [t(:) cent.X(3,:)' coop.X(3,:)' coopJ.X(3,:)' coop1.X(3,:)'];
data4 = [t(:) cent.X(5,:)' coop.X(5,:)' coopJ.X(5,:)' coop1.X(5,:)'];
data5 = [t(:) cent.X(7,:)' coop.X(7,:)' coopJ.X(7,:)' coop1.X(7,:)' coopJ1.X(7,:)'];
data6 = [t(:) cent.X(9,:)' coop.X(9,:)' coopJ.X(9,:)' coop1.X(9,:)' coopJ1.X(9,:)'];
data7 = [t(:) cent.X(11,:)' coop.X(11,:)' coopJ.X(11,:)' coop1.X(11,:)'];
data8 = [t(:) cent.X(13,:)' coop.X(13,:)' coopJ.X(13,:)' coop1.X(13,:)'];

save  Sequential.dat data0 data data1 data2 data3 data4 data5 data6 \
    data7 data8;
