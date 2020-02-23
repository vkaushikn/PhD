 warning off
close all
clear all
% To test robust cooperative MPC
% Tracking MPC
% x^+ = Ax +Bu + Bdd_{\text{nominal}} + w 
% w \in R^n is the disturbance
% w(2) \in (-2,2) (20% disturbance around nominal demand)
% w(i), i \neq 2 \in (-eps,eps)  to satisfy assumptions
% In actual realization w(i), i \neq 2 is always 0.
%% Original supply chain
original.A = eye(4);
original.B{1} = [-1 0 0 0; -1 0 0 0;0 0 -1 0;0 1 -1 0];
original.B{2} = [0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0];
original.B{3} = [0 0 1 0; 0 0 0 0; 0 0 0 1;0 0 0 0];
original.Bd = [0;1;0;0];
[origianal.nx original.nd] = size(original.Bd);
[original.nx original.nu] = size(original.B{1});

%% The model
model.A = [original.A original.B{2} original.B{3}; ...
           zeros(original.nu,original.nx) zeros(original.nu,original.nu) zeros(original.nu,original.nu);...
           zeros(original.nu,original.nx) eye(original.nu,original.nu) zeros(original.nu,original.nu)];
  
model.B = [original.B{1}; eye(original.nu); zeros(original.nu)];
model.Bd = [original.Bd; zeros(original.nu,original.nd); zeros(original.nu,original.nd)];
[model.nx model.nu] = size(model.B);
[model.nx model.nd] = size(model.Bd);
model.x_sD = [35;0;40;0];
model.nominal = 1*10;
model.N = 15;
model.eps = 1e-1;%sqrt(eps);
model.simtime = 20;
model.IC = [15;10;23;0;model.nominal*ones(original.nu,1);model.nominal*ones(original.nu,1)]; 

model.actD = model.nominal*ones(2000,1);
eps1 = model.eps;

%% Stage cost
penalty.cx = [[10;10;10;.1];zeros(2*model.nu,1)];
penalty.cu = 1*[10; .1; 10; 100];
penalty.Q =  1e0*blkdiag(diag([10,10,10,1e1]),model.eps*eye(2*model.nu));
penalty.R =  1e0*diag([1,1e-5,1,1]);

%% Terminal cost
% Standard gain (when x_lb<0)
[K,S,E] = dlqr(model.A,model.B,penalty.Q,penalty.R);
model.K = -K;
% % Rao and Rawlings gain when x_lb = 0 (or very close!) 
Cbar = [0 1 0 0 zeros(1,2*original.nu);0 0 0 1 zeros(1,2*original.nu)];
%Cbar = [0 0 0 1 zeros(1,2*original.nu)];
NCbar = null(Cbar);
NCbarB = null(Cbar*model.B);
K = -pinv(Cbar*model.B)*Cbar*model.A;
AK = model.A+model.B*K; BK = model.B*NCbarB;
QK = penalty.Q + K'*penalty.R*K; RK = NCbarB'*penalty.R*NCbarB;
[K1 S E] = dlqr(AK,BK,QK,RK);
model.K = K-NCbarB*K1;
penalty.P = S;
model.A_K = model.A+model.B*model.K;
penalty.q_K = [penalty.cx+model.K'*penalty.cu];
penalty.cxt = [(model.A_K-eye(model.nx))']^-1*(-penalty.q_K); %works for any steady state
penalty.scale_eco = 1e0; penalty.scale_risk = 1e0;


%% The Constraints;
constraint.uub = [20; 20; 20; 20];
constraint.ulb = 1*[0; 0; 0; 0];
constraint.xlb =[1e-9*[-5;-5;-5;-5];constraint.ulb;constraint.ulb];
constraint.xub = [[100;100;100;100];constraint.uub;constraint.uub];
constraint.TE =0;

%% Economic steady state
H = eye(model.nx+model.nu)*model.eps;
q = [penalty.cx;penalty.cu];
Aeq = [eye(model.nx)-model.A -model.B];
beq = model.Bd*model.nominal;
Aeq = [Aeq;eye(original.nx) zeros(original.nx,3*original.nu)];
beq = [beq;model.x_sD];
LB = [constraint.xlb;constraint.ulb];
UB = [constraint.xub;constraint.uub];
[z obj info] = linprog(q,[],[],Aeq,beq,LB,UB);
model.x_s = z(1:model.nx); model.u_s = z(model.nx+1:end);
XS = model.x_s;
model.distEstimate = 1*model.nominal;

%% $S_K(\infty)$
constraint.W1 = [eye(model.nx);-eye(model.nx)]; 
constraint.w1 = model.eps*ones(2*model.nx,1);
% 20% around nominal [-8,10]
constraint.w1(2) = 2; constraint.w1(model.nx+2) = 2;


constraint.U = polytope([eye(model.nu);-eye(model.nu)],[constraint.uub;-constraint.ulb]);
constraint.X = polytope([eye(model.nx);-eye(model.nx)],[constraint.xub;-constraint.xlb]);
constraint.W = polytope(constraint.W1,constraint.w1);

% S_K(infty)
constraint.S_K = (eye(model.nx)-model.A_K)^-1*constraint.W;
% what we want is { u : u+w \in U \forall w \in S_K}
% This can be approximated by algorithm given in Chapter-3
SKV = extreme(constraint.S_K); [nc nd] = size(SKV);
VcoupLHS = []; VcoupRHS = [];
[constULHS constUrhs] = double(constraint.U);
for i = 1:nc
 VcoupLHS = [VcoupLHS;constULHS];
 VcoupRHS = [VcoupRHS;constUrhs-constULHS*model.K*SKV(i,:)'];
end
%VcoupLHS = [VcoupLHS;constULHS]; VcoupRHS = [VcoupRHS;constUrhs];
%
constraint.V = polytope(VcoupLHS,VcoupRHS);
constraint.Z = constraint.X-constraint.S_K;
[ZH ZK] = double(constraint.Z);


%%  "Nominal system"
nominal.model = model;
nominal.penalty = penalty;
% hard code, can later make it okay
nominal.constraint.uub = [18;17.6;17.7;17.4];
nominal.constraint.ulb = [2;2.4;2.3;2.6];
nominal.constraint.xub = ZK(1:nominal.model.nx);
nominal.constraint.xlb = -1*ZK(nominal.model.nx+1:end);
nominal.constraint.TE = 0;
nominal.model.omega = 0.4; nominal.model.x_s = XS;
[nominal.model nominal.terminal] = SteadyStateAndScaling(nominal.model,nominal.penalty,nominal.constraint);
nominal.model.simtime = 1; % control disturbance here! w gets added here
nominal.model.nominal = [10]; % nominal demand
nominal.model.actD = [10]; % only nominal model is used.
nominal.model.distEstimate = [10];

%% "Actual system"
% We need to make all the actual matrices also because inherent robustness
% and the modified algorithm works on the actual system
model.omega = 0.4; model.x_s = XS;
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
model.simtime = 1;
model.nominal = 10;
model.actD = 10;
model.distEstimate = 10;

%% Simulation parameters
sim.time = 20;
sim.realization = 1;
sim.Pmax = [1 10 ]; %10 20];
% make the disturbance
for realization = 1:sim.realization
    sim.dist{realization} = zeros(nominal.model.nx,sim.time);
        for i = 1:sim.time
            sim.dist{realization}(2,i) = -2+rand*4;
        end
end
nominal.model.IC0 = [45;10;20;0;10*ones(2*model.nu,1)]+0*randn(12,1); %(fixed)*random starting point    
model.IC0 = nominal.model.IC0;
[nominal.mpc] = centralized(nominal.model,nominal.penalty,nominal.constraint,nominal.terminal);
%[mpc] = centralized(model,penalty,constraint,terminal);
mpc = nominal.mpc;    
%% Simulations with tubes
clc
str = sprintf('\nTube based MPC');
disp(str)
sim.time = 20;
sim.realization = 1;
sim.Pmax = 0; %10 20];
pmax = 0;
model.nominaldemand = 10;
model.actD = 10; % for the currrent time, the actual disturbance
nominal.model.nominaldemand = 10;
nominal.model.actD = 10;
for realization = 1:sim.realization
    str = sprintf('\nRealization Number: %d',realization);
    disp(str);
    dist = sim.dist{realization};
    % (Restart from the x(k))Centralized 
    str = sprintf('\nCentralized MPC-Tube');
    disp(str);
    X = []; Z = []; U = []; V = []; bU = []; costDrop = [];
    nominal.model.IC = nominal.model.IC0;
    X(:,1) = nominal.model.IC0;
    Z(:,1) = nominal.model.IC0;
    nominal.model.IC = nominal.model.IC0;
    %Xa(:,1) = X(:,1)+[15;15];
    for k = 1:sim.time
	%Added-8/14-Calculate cost from the original x also
	model.IC  = X(:,k)
	%Know the actual current demand!
	model.actD = model.nominaldemand + dist(2,k);
	nominal.model.actD = nominal.model.nominaldemand + dist(2,k);	  
	[res_rob] = centMPC(mpc,nominal.model);% but we predict ahead
				% using the nominal model only
        [res] = centMPC(nominal.mpc,nominal.model);
	if res_rob.obj <= res.obj
		  V(:,k) = res.U(:,1);
		  u = res.U(:,1);
		  costDrop(k) = 1;
	else % need to use the nominal because of cost drop issue
        % Find the input
		  V(:,k) = res.U(:,1);
		  u = res.U(:,1)+ model.K*(X(:,k)-Z(:,k));
		  costDrop(k) = -1;
	end	  
	U(:,k) = u;
        % Move the nominal state
        nominal.model.IC = res.X(:,2);
        Z(:,k+1) = res.X(:,2);
        % Move the actual state
        X(:,k+1) = model.A*X(:,k)+model.B*u+model.Bd*nominal.model.nominal + dist(:,k);
        bU(:,k) = res.Z(:,1);
    end %k
    %sim.res{realization,pmax+1}.Xa = Xa;
    sim.res{1,realization,1}.X = X;
    sim.res{1,realization,1}.Z = Z;
    sim.res{1,realization,1}.U = U;
    sim.res{1,realization,1}.V = V;
    sim.res{1,realization,1}.bU = bU;
    
%%    % Inherent robustness
%%    str = sprintf('\nCentralized MPC-Inherent ');
%%    disp(str);
%%    X = []; Z = []; U = []; V = []; bU = [];
%%    nominal.model.IC = nominal.model.IC0;
%%    X(:,1) = nominal.model.IC0;
%%    Z(:,1) = nominal.model.IC0;
%%    nominal.model.IC = nominal.model.IC0;
%%    %Xa(:,1) = X(:,1)+[15;15];
%%    for k = 1:sim.time
%%        [res] = centMPC(nominal.mpc,nominal.model);
%%        % Find the input
%%        V(:,k) = res.U(:,1);
%%        u = res.U(:,1);
%%        U(:,k) = u;  
%%        % Move the actual state
%%        X(:,k+1) = model.A*X(:,k)+model.B*u+model.Bd*nominal.model.nominal + dist(:,k);
%%       bU(:,k) = res.Z(:,1);
%%      % Resolve the problem from the "actual" state
%%        nominal.model.IC = X(:,k+1);
%%        Z(:,k+1) = X(:,k+1);
%%   end %k
%%    %sim.res{realization,pmax+1}.Xa = Xa;
%%    sim.res{1,realization,2}.X = X;
%%    sim.res{1,realization,2}.Z = Z;
%%    sim.res{1,realization,2}.U = U;
%%    sim.res{1,realization,2}.V = V;
%%    sim.res{1,realization,2}.bU = bU;
end


