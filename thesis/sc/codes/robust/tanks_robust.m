warning off
close all
clear all

%Robust cooperative MPC for a system of two tanks
%MATLAB code: Need MPT toolbox
original.A = eye(4);
original.B{1} = [-1 0 0 0;
		 -1 0 0 0;
		 0 0 -1 0;
		 0 1 -1 0];
original.B{2} = [0 0 1 0;
		 0 0 0 0;
		 0 0 0 0;
		 0 0 0 0];
original.B{3} = [0 0 0 0;
		 0 0 0 0; 
		 0 0 0 1;
		 0 0 0 0];
original.Bd = eye(4); %just to be consistent with the code. The only
		      %significant disturbance is the demands
[origianal.nx original.nd] = size(original.Bd);
[original.nx original.nu] = size(original.B{1});


%nominal system
nominal.A = [original.A original.B{2} original.B{3}; ...
           zeros(original.nu,original.nx) zeros(original.nu,original.nu) zeros(original.nu,original.nu);...
           zeros(original.nu,original.nx) eye(original.nu,original.nu) zeros(original.nu,original.nu)];
nominal.B = [original.B{1}; eye(original.nu); zeros(original.nu)];

%actual system
plant.A = nominal.A;
plant.B = nominal.B;
plant.Bd = [original.Bd; zeros(original.nu,original.nd); zeros(original.nu,original.nd)];
[plant.nx plant.nu] = size(plant.B);
[plant.nx plant.nd] = size(plant.Bd);
%simulation parameters
sim.time = 50;
sim.N = 5;
sim.eps = 1e-8;
sim.xabs = [15;10;23;0]; %initial absolute variables
sim.xSS = [35;0;40;0]; %steady-state in absolute variables (can be fixed
		   %because of integrator)
sim.dSS = [0.0001;10;0.0001;0.0001]; %nominal demand.
sim.uSS = [10;10;10;10]; %know that SC steady state is equal to demand
sim.x0 = sim.xabs - sim.xSS;
sim.x0  = [sim.x0;0*sim.uSS;0*sim.uSS]; %start of with flows at steady state
sim.pmax = 1;


%Costs

penalty.cx = 0*[[10;10;10;.1];zeros(2*plant.nu,1)];
penalty.cu = 0*1e0*[10; .1; 10; 100];
penalty.Q =  1e0*blkdiag(diag([10,10,10,1e1]),sim.eps*eye(2*plant.nu));
penalty.R =  1e0*diag([1,1e-5,1,1]);



%[K,S,E] = dlqr(plant.A,plant.B,penalty.Q,penalty.R);
%nominal.K = -K; %K used for both terminal region and local error
		%correction

Cbar = [0 1 0 0 zeros(1,2*original.nu);0 0 0 1 zeros(1,2*original.nu)];
% %Cbar = [0 0 0 1 zeros(1,2*original.nu)];
NCbar = null(Cbar);
NCbarB = null(Cbar*nominal.B);
K = -pinv(Cbar*nominal.B)*Cbar*nominal.A;
AK = nominal.A+nominal.B*K; BK = nominal.B*NCbarB;
QK = penalty.Q + K'*penalty.R*K; RK = NCbarB'*penalty.R*NCbarB;
[K1 S E] = dlqr(AK,BK,QK,RK);
nominal.K = K-NCbarB*K1
penalty.P = S; %terminal penalty

%Constraints
constraint.uub = [20;100;20;100]- sim.uSS;
constraint.ulb = [0;0;0;0]- sim.uSS;
constraint.xub = [100;100;100;100;constraint.uub;constraint.uub];
constraint.xlb = [-100;-100;-100;-100;constraint.ulb;constraint.ulb];

%\mathbb{W}
constraint.wub = [0.0002;15;0.0002;0.0002] - sim.dSS;
constraint.wlb = [0;5;0;0] - sim.dSS;

%represent as polytopes
%correct for the inputs that are stacked as well
constraint.W = ...
    polytope([eye(12);-eye(12)],[constraint.wub;0.001*ones(8,1);-constraint.wlb;0.001*ones(8,1)]);
constraint.U = ...
    polytope([eye(4);-eye(4)],[constraint.uub;-constraint.ulb])


%Invariant sets and ellipsoids (fixed by trial and error)
nominal.AK = nominal.A + nominal.B*nominal.K; %closed loop dynamics in
				%terminal region
%construct the set for terminal region 
%in the terminal region {x | Kx \in constraint.U}
[H h] = double(constraint.U);
X = polytope(H*K,h);
[constraint.Xf,tstar] = mpt_infset(nominal.AK,X,1000);

%a = 1 is small enough. Comment that we could have chosen larger a also
constraint.a = 1;
constraint.Vbar = 100;
constraint.beta = constraint.Vbar/constraint.a;


%\mathbb{V} (page 233)
N = 200;
alpha = 1e-9;
[H h] = double(constraint.W);
%the constraint of the LP problem is obtained by kron
A = kron(eye(N),H);
b = repmat(h,[N,1]);
[H h] = double(constraint.U);
Theta_N = zeros(length(h),1);
for j = 1:length(h)
  temp = [];
  for jj = 0:N-1
    temp = [temp nominal.AK^(jj)];
  end
  f = H(j,:)*nominal.K*temp;
  [x Theta_N(j) info] = linprog(-f,A,b);
  info
end
%Skinf = constraint.W;
%for i = 1:15
%  Skinf = Skinf + nominal.AK^i*constraint.W;
%end

h_new = h-(1-alpha)^-1*(-Theta_N);
constraint.V = polytope(H,h_new);

%okay, constraint.V is not coupled!
[H,h] = double(constraint.V);
%assign the new constraints to the plants
constraint.uub = h(1:4);
constraint.ulb = -h(5:end);

constraint1 = constraint;
constraint = [];
constraint.uub = constraint1.uub;
constraint.ulb = constraint1.ulb;
constraint.beta = constraint1.beta;
%constraint.Skinf = extreme(Skinf);


save Model.dat nominal
save Penalty.dat penalty
save Constraint.dat constraint
save sims.dat sim




