warning off
close all
clear all

%Robust cooperative MPC for a system of two tanks
%MATLAB code: Need MPT toolbox

%simulation parameters
sim.time = 50;
sim.N = 5;
sim.eps = 1e-8;
sim.xabs = [25;17]; %initial absolute variables
sim.xSS = [20;20]; %steady-state in absolute variables (can be fixed
		   %because of integrator)
sim.dSS = [0.1;5];
sim.x0 = sim.xabs - sim.xSS;
sim.pmax = 1;
%nominal system
nominal.A = eye(2);
nominal.B = [1 -1 0; 0 1 -1];

%actual system
plant.A = eye(2);
plant.B = [1 -1 0; 0 1 -1];
plant.Bd = eye(2);

%Costs
penalty.cx = sim.eps*ones(2,1);
penalty.cu = sim.eps*ones(3,1);
penalty.cxt = sim.eps*ones(2,1);
penalty.Q = 0.1*eye(2);
penalty.R = eye(3);

%input steady state
sim.uSS = quadprog(penalty.R,-penalty.R*[5;5;5],[],[],nominal.B,-sim.dSS,[0;0;0],[10;10;10]);
[K,S,E] = dlqr(plant.A,plant.B,penalty.Q,penalty.R);
nominal.K = -K; %K used for both terminal region and local error
		%correction
penalty.P = S; %terminal penalty

%Constraints
constraint.uub = [10;10;20]- sim.uSS;
constraint.ulb = [0;0;0]- sim.uSS;
constraint.xub = [100;100];
constraint.xlb = -[100;100];

%\mathbb{W}
constraint.wub = [0.2;10] - sim.dSS;
constraint.wlb = [0;0] - sim.dSS;

%represent as polytopes
constraint.W = ...
    polytope([eye(2);-eye(2)],[constraint.wub;-constraint.wlb]);
constraint.U = ...
    polytope([eye(3);-eye(3)],[constraint.uub;-constraint.ulb])


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
Skinf = constraint.W;
for i = 1:15
  Skinf = Skinf + nominal.AK^i*constraint.W;
end

h_new = h-(1-alpha)^-1*(-Theta_N);
constraint.V = polytope(H,h_new);

%okay, constraint.V is not coupled!
[H,h] = double(constraint.V);
%assign the new constraints to the models
constraint.uub = h(1:3);
constraint.ulb = -h(4:end);

constraint1 = constraint;
constraint = [];
constraint.uub = constraint1.uub;
constraint.ulb = constraint1.ulb;
constraint.beta = constraint1.beta;
constraint.Skinf = extreme(Skinf);


save Model.dat nominal
save Penalty.dat penalty
save Constraint.dat constraint
save sims.dat sim




