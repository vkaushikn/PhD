warning off

% Equality terminal constraint
% Compare results of 
% (i) Stability ensured v/s stability not ensured (Nominal)


% Do not change the costs or model.omega
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
model.eps = 1e-3;%sqrt(eps);
model.simtime = 200;
model.nominal = 1*10;
model.IC = [0;0;0;0;model.nominal*ones(original.nu,1);model.nominal*ones(original.nu,1)]; 
eps1 = model.eps;

% The costs

penalty.cx = [[1;1;1;.01];zeros(2*model.nu,1)];
penalty.cu =1*[10; 0.1;10;1 ];
penalty.Q =  .1*blkdiag(diag([1,1,1,1]),model.eps*eye(2*model.nu));
penalty.R =  .1*eye(model.nu);
[K,S,E] = dlqr(model.A,model.B,penalty.Q,penalty.R);
penalty.P = 0*S;
model.K = -K;
model.A_K = model.A+model.B*model.K;
penalty.q_K = [penalty.cx+model.K'*penalty.cu];
penalty.cxt = 0*[model.A_K-eye(model.nx)]^-1*(-penalty.q_K); %works for any steady state
penalty.scale_eco = 1e0; penalty.scale_risk = 1e0;

% The Constraints
constraint.uub = [20; 20; 20; 20];
constraint.ulb = 1*[0; 0; 0; 0];
constraint.xlb = [0*ones(original.nx,1);constraint.ulb;constraint.ulb];
constraint.xub = [100*ones(original.nx,1);constraint.uub;constraint.uub];

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
model.simtime = 150;
model.distEstimate = 1*model.nominal;
model.omega = 0.98;%pure economic 
model.actD = model.nominal*ones(200,1)+0.0*randn(200,1);

% model.x_s(u_s) is the Set point from which we penalize in the stage cost
% For each model.omega, we find an unique steady state
% model.x_ss,model.u_ss = model.u_s from which we penalize the terminal
% state.

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

% Part (i) a: Equality terminal constraint
model.IC = [15;5;23;10;zeros(2*model.nu,1)];
model.simtime = 200;
terminal.T = [eye(model.nx);-eye(model.nx)];
terminal.t = [model.eps*ones(2*model.nx,1)];
terminal.t = terminal.t+terminal.T*model.x_ss;
[mpc] = centralized(model,penalty,constraint,terminal);
[CL{1}] = centMPCLP(mpc,model);

% Part (i) b: No terminal constraint, show instability starting from x_s
model.IC = [0;0;0;0;model.nominal*ones(original.nu,1);model.nominal*ones(original.nu,1)];
   
terminal.T = [eye(model.nx);-eye(model.nx)];
terminal.t = [100*constraint.xub;100*constraint.xub];
terminal.t = terminal.t+terminal.T*model.x_ss;
[mpc] = centralized(model,penalty,constraint,terminal);
[CL{2}] = centMPCLP(mpc,model);

%save results for plotting and calculate closed-loop cost
t = 0:model.simtime; t = t(:);
temp = repmat(x_sD, [1 model.simtime+1]);
temp1 = repmat(model.x_ss, [1 model.simtime+1]);
data = [t CL{1}.X(1,:)' CL{2}.X(1,:)' temp(1,:)' temp1(1,:)'...
        t CL{1}.X(2,:)' CL{2}.X(2,:)' temp(2,:)' temp1(2,:)'...
        t CL{1}.X(3,:)' CL{2}.X(3,:)' temp(3,:)' temp1(3,:)'... 
        t CL{1}.X(4,:)' CL{2}.X(4,:)' temp(4,:)' temp1(4,:)'];
figure(1)
subplot(221)
plot(data(:,1),data(:,2),data(:,1),data(:,3),data(:,1),data(:,4),data(:,1),data(:,5));
ylabel('Inv-R')
xlabel('time')
legend('Stability','No-stability','Target','SS')
subplot(222)
plot(data(:,6),data(:,7),data(:,6),data(:,8),data(:,6),data(:,9),data(:,6),data(:,10));
ylabel('BO-R')
xlabel('time')
%legend('Stability','No-stability','Target','SS')
subplot(223)
plot(data(:,11),data(:,12),data(:,11),data(:,13),data(:,11),data(:,14),data(:,11),data(:,15));
ylabel('Inv-M')
xlabel('time')
%legend('Stability','No-stability','Target','SS')
subplot(224)
plot(data(:,16),data(:,17),data(:,16),data(:,18),data(:,16),data(:,19),data(:,16),data(:,20));
ylabel('BO-M')
xlabel('time')
%legend('Stability','No-stability','Target','SS') 

CL{1}.cost = 0; CL{2}.cost = 0;
for i= 1:model.simtime
    for sim = 1:2
        x = CL{sim}.X(:,i);
        u = CL{sim}.U(:,i);
        l = (1-model.omega)*((x-model.x_s)'*penalty.Q*(x-model.x_s)+(u-model.u_s)'*penalty.R*(u-model.u_s))+model.omega*(penalty.cx'*x+penalty.cu'*u);
        CL{sim}.cost = CL{sim}.cost+l;
    end
end

[CL{1}.cost CL{2}.cost]./model.simtime

data1 = data(:,[6 8]);
save -ascii unstable_SC.dat data1

data1 = data(:,[1 2 6 7 11 12 16 17]);
save -ascii stable_SC.dat data1





