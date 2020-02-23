warning off
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
penalty.cu = 1e0*[10; .1; 10; 100];
penalty.Q =  1e0*blkdiag(diag([10,10,10,1e1]),model.eps*eye(2*model.nu));
penalty.R =  1e-5*diag([1,1e-5,1,1]);

%% Terminal cost
% Standard gain (when x_lb<0)
[K,S,E] = dlqr(model.A,model.B,penalty.Q,penalty.R);
model.K = -K;
% Rao and Rawlings gain when x_lb = 0 (or very close!) 
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
constraint.xub = [[1000;1000;1000;1000];constraint.uub;constraint.uub];
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
% model.x_s(u_s) is the set point from which we penalize in the stage cost

% For each model.omega, we find an unique steady state
% model.x_ss,model.u_ss = model.u_s from which we penalize the terminal
% state.

%% Steady state as function of omega
omega = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];
XSS = [];
constraint.TEold = constraint.TE;
for i = 1:length(omega)
    model.omega = omega(i); model.x_s = XS;
    constraint.TE = 1;
    [model terminal] = SteadyStateAndScaling(model,penalty,constraint);
    XSS = [XSS model.x_ss];
end
constraint.TE = constraint.TEold;
close all;
%figure(1)
%plot(omega,XSS(1,:),omega,XSS(2,:))

% save data
data = [omega' XSS(1,:)' XSS(3,:)'];
save -ascii SS_omega.dat data;

%% Case-1: omega = 0.4

model.omega = 0.4; model.x_s = XS;
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
[mpc] = centralized(model,penalty,constraint,terminal);
[CL{1}] = centMPC(mpc,model);
CL{1}.xss = model.x_ss;
CL{1}.model = model;
CL{1}.penalty = penalty;
CL{1}.terminal = terminal;

% Compare with pure tracking to same steady state
comp = 1;
model.omega = 0.0;
model.x_s = CL{comp}.model.x_ss; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLT{1}] = centMPC(mpc,model);
CLT{1}.xss = model.x_ss;
CLT{1}.model = model;
CLT{1}.penalty = penalty;
CLT{1}.terminal = terminal;


 
%% Case-2: omega = 0.2
model.omega = 0.2; model.x_s = XS;
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
[mpc] = centralized(model,penalty,constraint,terminal);
[CL{2}] = centMPC(mpc,model);
CL{2}.xss = model.x_ss;
CL{2}.model = model;
CL{2}.penalty = penalty;
CL{2}.terminal = terminal;

% Compare with pure tracking to same steady state
comp = 2;
model.omega = 0.0;
model.x_s = CL{comp}.model.x_ss; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLT{2}] = centMPC(mpc,model);
CLT{2}.xss = model.x_ss;
CLT{2}.model = model;
CLT{2}.penalty = penalty;
CLT{2}.terminal = terminal;


%% Case-3: omega = 0.8
% we need to do TE for this case as all the steady-states are at the origin
constraint.TE = 1;
model.omega = 0.8;  model.x_s = XS;
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
[mpc] = centralized(model,penalty,constraint,terminal);
[CL{3}] = centMPC(mpc,model);
CL{3}.xss = model.x_ss;
CL{3}.model = model;
CL{3}.penalty = penalty;
CL{3}.terminal = terminal;

% Compare with pure tracking to same steady state
comp = 3;
model.omega = 0.0;
model.x_s = CL{comp}.model.x_ss; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLT{3}] = centMPC(mpc,model);
CLT{3}.xss = model.x_ss;
CLT{3}.model = model;
CLT{3}.penalty = penalty;
CLT{3}.terminal = terminal;

%% Figures

% figure(2)
% t = 0:model.simtime;
% subplot(221)
% plot(t,CL{1}.X(1,:),'r',t,CL{2}.X(1,:),'g',t,CL{3}.X(1,:),'b',t,CL{4}.X(1,:),'k')
% ylabel('Inventory-Retailer')
% xlabel('Time')
% subplot(222)
% plot(t,CL{1}.X(2,:),'r',t,CL{2}.X(2,:),'g',t,CL{3}.X(2,:),'b',t,CL{4}.X(2,:),'k')
% ylabel('BackOrder-Retailer')
% xlabel('Time')
% subplot(223)
% plot(t,CL{1}.X(3,:),'r',t,CL{2}.X(3,:),'g',t,CL{3}.X(3,:),'b',t,CL{4}.X(3,:),'k')
% ylabel('Inventory-Manufacturer')
% xlabel('Time')
% subplot(224)
% plot(t,CL{1}.X(4,:),'r',t,CL{2}.X(4,:),'g',t,CL{3}.X(4,:),'b',t,CL{4}.X(4,:),'k')
% ylabel('BackOrder-Manufacturer')
% xlabel('Time')
% legend('Economic','Mixed-0.5','Tracking-Eco SS','Mixed-0.25')

%% save data
t = 0:model.simtime; t = t(:);
data = [t CL{1}.X(1,:)' CLT{1}.X(1,:)'...
        t CL{1}.X(3,:)' CLT{1}.X(3,:)'...
        t CL{1}.X(2,:)' CLT{1}.X(2,:)'];
    
save -ascii CL4.dat data

t = 0:model.simtime; t = t(:);
data = [t CL{2}.X(1,:)' CLT{2}.X(1,:)'...
        t CL{2}.X(3,:)' CLT{2}.X(3,:)'...
        t CL{2}.X(2,:)' CLT{2}.X(2,:)'];
    
save -ascii CL2.dat data

t = 0:model.simtime; t = t(:);
data = [t CL{3}.X(1,:)' CLT{3}.X(1,:)'...
        t CL{3}.X(3,:)' CLT{3}.X(3,:)'...
        t CL{3}.X(2,:)' CLT{3}.X(2,:)'];
    
save -ascii CL8.dat data

Xf = polytope(CL{1}.terminal.T,CL{1}.terminal.t);
Xf1 = projection(Xf, [ 1 3]);
[P.xCheb,P.RCheb] = chebyball(Xf1)            
tempV.V = extreme(Xf1);
% sort vertices in a cyclic way;
x1=tempV.V(:,1);
x2=tempV.V(:,2);
ang=angle((x1-P.xCheb(1))+(x2-P.xCheb(2))*sqrt(-1));
[val,ind]=sort(ang);
x1=x1(ind);
x2=x2(ind);
V = [x1 x2];
save -ascii Xf4.dat V
%plot(Xf1)
%% Costs
cost(1) = 0;  cost(2) = 0; cost(3) = 0;
Tcost(1) = 0; Tcost(2) = 0; Tcost(3) = 0; 
for i = 1:model.simtime
    for j = 1:3
        cost(j) = cost(j) + penalty.cx'*CL{j}.X(:,i)+penalty.cu'*CL{j}.U(:,i);
        Tcost(j) = Tcost(j)+penalty.cx'*CLT{j}.X(:,i)+penalty.cu'*CLT{j}.U(:,i);
    end 
end

cost-Tcost

% ss =comp;
% x = CL{ss}.Xp(end-11:end,5);
% X = x; U = []; delV = []; delVT =[]; delVE = [];
% for i = 1:20
% x1 = model.A*x+model.B*(model.K*(x-CL{ss}.xss)+CL{ss}.model.u_ss)+model.Bd*10;
% u = model.K*(x-CL{ss}.xss)+CL{ss}.model.u_ss;
% V1T =(x1-CL{ss}.model.x_ss)'*penalty.P*(x1-CL{ss}.model.x_ss);
% V1E =penalty.cxt'*(x1-CL{ss}.model.x_ss);
% V0T = (x-CL{ss}.model.x_ss)'*penalty.P*(x-CL{ss}.model.x_ss);
% V0E = penalty.cxt'*(x-CL{ss}.model.x_ss);
% ellT = (x-CL{ss}.model.x_s)'*penalty.Q*(x-CL{ss}.model.x_s)+...
%        (u-CL{ss}.model.u_s)'*penalty.R*(u-CL{ss}.model.u_s);
% ellE = (penalty.cx'*x+penalty.cu'*u);
% ellTs = (CL{ss}.model.x_ss-CL{ss}.model.x_s)'*penalty.Q*(CL{ss}.model.x_ss-CL{ss}.model.x_s)+...
%         (CL{ss}.model.u_ss-CL{ss}.model.u_s)'*penalty.R*(CL{ss}.model.u_ss-CL{ss}.model.u_s);
% ellEs = (penalty.cx'*CL{ss}.model.x_ss+penalty.cu'*CL{ss}.model.u_ss);
% delVT(i) = V1T-V0T+ellT-ellTs;
% delVE(i) = V1E-V0E+ellE-ellEs;
% delV(i) = CL{ss}.model.omega(2)*delVT(i)+CL{ss}.model.omega(1)*delVE(i);
% x = x1;
% X  = [X x]; U = [U u];
% b = penalty.Q*(CL{ss}.model.x_ss-CL{ss}.model.x_s);
% c = CL{ss}.model.x_ss'*penalty.Q*(CL{ss}.model.x_ss-CL{ss}.model.x_s);
% fc(i) = x'*b-c;
% end
[CL{1}.xss CL{2}.xss CL{3}.xss ]
[CL{1}.X(:,end) CL{2}.X(:,end) CL{3}.X(:,end) ]

%% Obtain other costs
model.omega = 0.0; model.x_s = XS;
constraint.TE = 0;
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
[mpc] = centralized(model,penalty,constraint,terminal);
[CL{1}] = centMPC(mpc,model);
CL{1}.xss = model.x_ss;
CL{1}.model = model;
CL{1}.penalty = penalty;
CL{1}.terminal = terminal;

% Compare with pure tracking to same steady state
comp = 1;
model.omega = 0.0;
model.x_s = CL{comp}.model.x_ss; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLT{1}] = centMPC(mpc,model);
CLT{1}.xss = model.x_ss;
CLT{1}.model = model;
CLT{1}.penalty = penalty;
CLT{1}.terminal = terminal;

model.omega = 0.6; model.x_s = XS;
constraint.TE = 1;
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
[mpc] = centralized(model,penalty,constraint,terminal);
[CL{2}] = centMPC(mpc,model);
CL{2}.xss = model.x_ss;
CL{2}.model = model;
CL{2}.penalty = penalty;
CL{2}.terminal = terminal;

% Compare with pure tracking to same steady state
comp = 2;
model.omega = 0.0;
model.x_s = CL{comp}.model.x_ss; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLT{2}] = centMPC(mpc,model);
CLT{2}.xss = model.x_ss;
CLT{2}.model = model;
CLT{2}.penalty = penalty;
CLT{2}.terminal = terminal;

comp = 2;
model.omega = 1.0;
model.x_s = XS; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLE{2}] = centMPC(mpc,model);
CLE{2}.xss = model.x_ss;
CLE{2}.model = model;
CLE{2}.penalty = penalty;
CLE{2}.terminal = terminal;


model.omega = 0.8; model.x_s = XS;
constraint.TE = 1;
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
[mpc] = centralized(model,penalty,constraint,terminal);
[CL{3}] = centMPC(mpc,model);
CL{3}.xss = model.x_ss;
CL{3}.model = model;
CL{3}.penalty = penalty;
CL{3}.terminal = terminal;

% Compare with pure tracking to same steady state
comp = 3;
model.omega = 0.0;
model.x_s = CL{comp}.model.x_ss; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLT{3}] = centMPC(mpc,model);
CLT{3}.xss = model.x_ss;
CLT{3}.model = model;
CLT{3}.penalty = penalty;
CLT{3}.terminal = terminal;

comp = 3;
model.omega = 1.0;
model.x_s = XS; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLE{3}] = centMPC(mpc,model);
CLE{3}.xss = model.x_ss;
CLE{3}.model = model;
CLE{3}.penalty = penalty;
CLE{3}.terminal = terminal;


model.omega = 1; model.x_s = XS;
constraint.TE = 1;
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
[mpc] = centralized(model,penalty,constraint,terminal);
[CL{4}] = centMPC(mpc,model);
CL{4}.xss = model.x_ss;
CL{4}.model = model;
CL{4}.penalty = penalty;
CL{4}.terminal = terminal;

% Compare with pure tracking to same steady state
comp = 4;
model.omega = 0.0;
model.x_s = CL{comp}.model.x_ss; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLT{4}] = centMPC(mpc,model);
CLT{4}.xss = model.x_ss;
CLT{4}.model = model;
CLT{4}.penalty = penalty;
CLT{4}.terminal = terminal;

comp = 4;
model.omega = 1.0;
model.x_s = XS; % track to Steady state of case-1
[model terminal] = SteadyStateAndScaling(model,penalty,constraint);
%model.x_s = CL{comp}.model.x_ss; model.u_s = CL{comp}.model.u_ss;
%model.x_ss = CL{comp}.model.x_ss; model.u_ss = CL{comp}.model.u_ss;
%terminal = CL{comp}.terminal;
%model.omega(1) = 0; model.omega(2) = 1;
[mpc] = centralized(model,penalty,constraint,terminal);
[CLE{4}] = centMPC(mpc,model);
CLE{4}.xss = model.x_ss;
CLE{4}.model = model;
CLE{4}.penalty = penalty;
CLE{4}.terminal = terminal;


cost(1) = 0;  cost(2) = 0; cost(3) = 0; cost(4) = 0;
Tcost(1) = 0; Tcost(2) = 0; Tcost(3) = 0; Tcost(4) = 0;
Ecost(1) = 0; Ecost(2) = 0; Ecost(3) = 0; Ecost(4) = 0;
for i = 1:model.simtime
    for j = 1:4
        cost(j) = cost(j) + penalty.cx'*CL{j}.X(:,i)+penalty.cu'*CL{j}.U(:,i);
        Tcost(j) = Tcost(j)+penalty.cx'*CLT{j}.X(:,i)+penalty.cu'*CLT{j}.U(:,i);
        if j>1
              Ecost(j) = Ecost(j)+penalty.cx'*CLT{j}.X(:,i)+penalty.cu'*CLT{j}.U(:,i);  
    end 
end
end

