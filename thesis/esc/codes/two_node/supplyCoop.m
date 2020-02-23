warning off

% Problem with Terminal Region calculation when xlb > -5. 
% Implement cooperative supply chain
original.A = eye(4);
original.B{1} = [-1 0 0 0; -1 0 0 0;0 0 -1 0;0 1 -1 0];
original.B{2} = [0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0];
original.B{3} = [0 0 1 0; 0 0 0 0; 0 0 0 1;0 0 0 0];
original.Bd = [0;1;0;0];
[origianal.nx original.nd] = size(original.Bd);
[original.nx original.nu] = size(original.B{1});

% The model
model.A = [original.A original.B{2} original.B{3}; ...
           zeros(original.nu,original.nx) zeros(original.nu,original.nu) zeros(original.nu,original.nu);...
           zeros(original.nu,original.nx) eye(original.nu,original.nu) zeros(original.nu,original.nu)];
  
model.B = [original.B{1}; eye(original.nu); zeros(original.nu)];
model.Bd = [original.Bd; zeros(original.nu,original.nd); zeros(original.nu,original.nd)];
[model.nx model.nu] = size(model.B);
[model.nx model.nd] = size(model.Bd);

model.N = 15;
model.eps = 1e-1;%sqrt(eps);
model.simtime = 20;
model.IC = [15;5;23;10;zeros(original.nu,1);zeros(original.nu,1)]; 
model.nominal = 1*10;
eps1 = model.eps;

% The costs
penalty.cx = [[1;1;1;1];zeros(2*model.nu,1)];
penalty.cu = [10; 1; 10; 1];
penalty.Q =  1*blkdiag(diag([1,10,1,10]),model.eps*eye(2*model.nu));
penalty.R =  .1*eye(model.nu);
[K,S,E] = dlqr(model.A,model.B,penalty.Q,penalty.R);
penalty.P = S;
model.K = -K;
model.A_K = model.A+model.B*model.K;
penalty.q_K = [penalty.cx+model.K'*penalty.cu];
penalty.cxt = [model.A_K-eye(model.nx)]^-1*(-penalty.q_K); %works for any steady state
penalty.scale_eco = 1e0; penalty.scale_risk = 1e0;

% The Constraints
constraint.uub = [20; 20; 20; 20];
constraint.ulb = 1*[0; 0; 0; 0];
constraint.xlb = [-5*ones(original.nx,1);constraint.ulb;constraint.ulb];
constraint.xub = [100*ones(original.nx,1);constraint.uub;constraint.uub];


% Define the subsystems
subsystem{1}.uloc = [1 2];
subsystem{2}.uloc = [3 4];
%Economic steady state
x_sD = [35;0;40;0];
H = eye(model.nx+model.nu)*model.eps;
q = [penalty.cx;penalty.cu];
Aeq = [eye(model.nx)-model.A -model.B];
beq = model.Bd*model.nominal;
Aeq = [Aeq;eye(original.nx) zeros(original.nx,3*original.nu)];
beq = [beq;x_sD];
LB = [constraint.xlb;constraint.ulb];
UB = [constraint.xub;constraint.uub];
[z obj info] = linprog(q,[],[],Aeq,beq,LB,UB);
model.x_s = z(1:model.nx); model.u_s = z(model.nx+1:end); 
model.simtime = 15;
model.distEstimate = 1*model.nominal;
model.actD = model.nominal*ones(200,1)+0.15*randn(200,1);
% model.x_s(u_s) is the Set point from which we penalize in the stage cost
% For each model.omega, we find an unique steady state
% model.x_ss,model.u_ss = model.u_s from which we penalize the terminal
% state.


model.omega = 0.95; %pure economic 
%Steady state for this particular problem
H = blkdiag(penalty.Q,penalty.R);
H = (1-model.omega)*H;
q = 1*-1*(1-model.omega)*[penalty.Q*model.x_s;penalty.R*model.u_s]+model.omega*[penalty.cx;penalty.cu];
LB = [constraint.xlb;constraint.ulb];
UB = [constraint.xub;constraint.uub];
Aeq = [eye(model.nx)-model.A -model.B];
beq = [model.Bd*model.nominal];
[z obj] = quadprog(H,q,[],[],Aeq,beq,LB,UB);
model.x_ss = z(1:model.nx); model.u_ss = z(model.nx+1:end);
[ Xf,tstar,fd, isemptypoly] = findXf( model,penalty,constraint);
[terminal.T terminal.t] = double(Xf);
% Equalityu
%[terminal.T] = [eye(model.nx);-eye(model.nx)];
%terminal.t = model.eps*ones(2*model.nx,1);
%No terminal
%[terminal.T] = [eye(model.nx);-eye(model.nx)];
%terminal.t = [100*constraint.xub;100*constraint.xub];
terminal.t = terminal.t+terminal.T*model.x_ss;

% Run centralized MPC once to obtain warm-start and IC
model.simtime = 150;
[mpc] = centralized(model,penalty,constraint,terminal);
[res] = centMPC(mpc,model);
model.IC0 = model.IC; %saving the origininal initial condition for further simulations

model.simtime = 149;
model.IC = res.X(:,2);
u0 = res.Z(:,1); xp = res.Xp(:,1);
model.ws = [u0(model.nu+1:end);model.K*(xp(end-model.nx+1:end)-model.x_ss)+model.u_ss];
model.pmax = 5;
%clear res
[cmpc] = cooperative(mpc,subsystem);
[CL{1}] = coopMPC(cmpc,model,mpc);
CL{1}.X = [res.X(:,1) CL{1}.X];
CL{1}.U = [res.U(:,1) CL{1}.U];

