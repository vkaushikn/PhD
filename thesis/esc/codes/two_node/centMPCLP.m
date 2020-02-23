function [ res ] = centMPCLP( mpc,model,mode)
%centMPC centralized MPC
if nargin==2
    mode = 'cent';
end
options = optimset('Display','on');
options = optimset(options,'Diagnostics','off');
options = optimset(options,'Algorithm','interior-point-convex');
omega(1) = model.omega;
omega(2) = 1-omega(1);
% 
% mpc.H = gam'*QQ*gam+RR;
% mpc.qR_c = -(gam'*QQ*XS+RR*US);
% mpc.qR_x = gam'*QQ*phi;
% mpc.qR_d = gam'*RR*gamd;
% 
% mpc.LB = repmat(ulb,[N 1]);
% mpc.UB = repmat(uub,[N 1]);
% 
% mpc.Ain = T*gam(end-nx+1:end,:);
% mpc.bin_c = t;
% mpc.bin_x = T*A^N;
% mpc.bin_d = T*gamd;
% 
% mpc.gam = gam;
% mpc.phi = phi;
% 
% mpc.eps = eps1;
% mpc.N = N;
% mpc.nx = nx;
% mpc.nu = nu;
% mpc.nt = nt;
% 
% mpc.QQ = phi'*QQ*phi;
% mpc.qq = phi'*CX;
% 
% mpc.qE = (gam'*CX+CU);
omega(2)  = 0;
omega(1) = 1;
H = omega(2)*mpc.H; qR_c =omega(2)*mpc.qR_c; qR_x = omega(2)*mpc.qR_x; qR_d = omega(2)*mpc.qR_d;
qE = omega(1)*mpc.qE;

LB = mpc.LB; UB = mpc.UB;
Ain = mpc.Ain; bin_c = mpc.bin_c; bin_x = mpc.bin_x; bin_d = mpc.bin_d;


A = model.A; B = model.B; nx = model.nx; nu = model.nu; Bd = model.Bd ;
d0 = model.distEstimate;
actD = model.actD;
N = model.N;
d = repmat(d0,[N 1]);
simtime = model.simtime;

x0 = model.IC;

res.X = [x0];
res.U = [];
res.info = [];
res.Xp = [];
res.V = [];
res.Z = [];
ws = [];
for k = 1:simtime
    bin = bin_c-bin_x*x0-bin_d*d;
    q = qR_c+qR_x*x0++qR_d*d+qE;
    if mode == 'cent'
    [z obj info] =linprog(q,Ain,bin,[],[],LB,UB,[],options);
    end
    if mode == 'coop'
       Aeq = mpc.Aeq;
       beq = mpc.beq;
       
      [z obj info] = quadprog(H,q,Ain,bin,Aeq,beq,LB,UB,[],options);
    end
    if info~=1
  info
    end
    u = z(1:nu);
    u0 = u;
    xp = mpc.phi*x0+mpc.gam*z+mpc.gamd*d;
    x0 = A*x0+B*u+Bd*actD(k);
    
    res.X = [res.X x0];
    res.U = [res.U u0];
    res.info = [res.info info];
    res.V = [res.V obj];
    res.Z = [res.Z z];
    res.Xp = [res.Xp xp];
end

