function [model terminal] = SteadyStateAndScaling(model,penalty,constraint)
% Function does the following tasks:
% (i) Finds the scaling for the steady state problem
% (ii)Obtains the steady state
% (iii) Runs MPC with N=1 to obtain scaling for the dynamic regulation
% problem
% (iv) Modifies model.omega with the corresponding scaling

%% (i) Scaling for the steady state problem
Aeq = [eye(model.nx)-model.A -model.B];
beq = [model.Bd*model.nominal];
LB = [constraint.xlb;constraint.ulb];
UB = [constraint.xub;constraint.uub];
% Find the "economic steady state"
qEco  = [penalty.cx;penalty.cu];
[zEco objEco info] = linprog(qEco,[],[],Aeq,beq,LB,UB);
% Find the "tracking steady state"
HTrack = blkdiag(penalty.Q,penalty.R);
qTrack = -1*[penalty.Q*model.x_s;penalty.R*model.u_s];
[zTrack objTrack info] = quadprog(HTrack,qTrack,[],[],Aeq,beq,LB,UB);
zs = [model.x_s;model.u_s];
objTrack = 1/2*(zTrack-zs)'*HTrack*(zTrack-zs);
% Nadir point;
objEco_Nadir = qEco'*zTrack;
objTrack_Nadir  = 1/2*(zEco-zs)'*HTrack*(zEco-zs);
% Scaling
if model.omega > 0 & model.omega<1
    eco = abs((model.omega(1))/(objEco_Nadir-objEco));
    track = abs((1-model.omega(1))/(objTrack_Nadir-objTrack));
    mode = 1;
else
   if model.omega == 0
        eco = 0; track = 1; mode = 0;
        %eco = abs((model.omega(1))/(objEco_Nadir-objEco));
        % track = abs((1-model.omega(1))/(objTrack_Nadir-objTrack));
         mode = 1;
   else
        eco = 0.99; track = 0.01; mode = 1;
   end
end
%eco
%track
%pause
%track = 1-model.omega(1); eco = model.omega(1);
%% Steady state and Terminal constraint calculation
H = track*HTrack; q = track*qTrack + eco*qEco; 
[z obj info output lambda] = quadprog(H,q,[],[],Aeq,beq,LB,UB);
model.x_ss = z(1:model.nx);
model.u_ss = z(model.nx+1:end);
[ Xf,tstar,fd, isemptypoly] = findXf( model,penalty,constraint,1);
[terminal.T terminal.t] = double(Xf);
terminal.t = terminal.t+terminal.T*model.x_ss;

%% Scaling for the dynamic regulation problem
simold = model.simtime; model.simtime = 1;
distold = model.distEstimate;
omega = model.omega; 
x = model.IC;
model.distEstimate = model.nominal;
VEco_Nadir = objEco_Nadir; VEco = objEco;
VTrack_Nadir = objTrack_Nadir; VTrack = objTrack;
model.omega(1) = eco; %omega/(VEco_Nadir-VEco);
model.omega(2) =track;%(1-omega)/(VTrack_Nadir-VTrack);
model.simtime = simold; model.distEstimate = distold;
%% 
end

