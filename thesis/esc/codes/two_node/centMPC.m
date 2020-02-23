function [ res ] = centMPC( mpc,model,mode)
%centMPC centralized MPC
if nargin==2
    mode = 'cent';
end

if isfield(model,'distmat')
    robust = 1;
    distmat = model.distmat;
    model.actD = distmat(1,:);
else
    robust = 0;
end

options = optimset('Display','off');
options = optimset(options,'Diagnostics','off');
options = optimset(options,'Algorithm','interior-point-convex');
options = optimset(options,'MaxIter',1000);
omega(1) = model.omega(1);
omega(2) = model.omega(2);

H = omega(2)*mpc.H; qR_c =omega(2)*mpc.qR_c; qR_x = omega(2)*mpc.qR_x; qR_d = omega(2)*mpc.qR_d;
qE = 1*omega(1)*mpc.qE;

LB = mpc.LB; UB = mpc.UB;
Ain = mpc.Ain; bin_c = mpc.bin_c; bin_x = mpc.bin_x; bin_d = mpc.bin_d;


A = model.A; B = model.B; nx = model.nx; nu = model.nu; Bd = model.Bd ;
d0 = model.nominaldemand;
actD = model.actD;
N = model.N;
d = [actD;repmat(d0,[N-1 1])];
simtime = model.simtime;

x0 = model.IC;

res.X = [x0];
res.U = [];
res.info = [];
res.Xp = [];
res.obj = [];
res.Z = [];
ws = [];
for k = 1:simtime
    if robust ==1
        d = distmat(:,k);
    end
    %keyboard
    bin = bin_c-bin_x*x0-bin_d*d;
    q = qR_c+qR_x*x0++qR_d*d+qE;
    if mode == 'cent'
        [z obj info outpt] = quadprog(H,q,Ain,bin,[],[],LB,UB,[],options);
    end
    if mode == 'coop'
       Aeq = mpc.Aeq;
       beq = mpc.beq;
       
      [z obj info] = quadprog(H,q,Ain,bin,Aeq,beq,LB,UB,[],options);
    end
    if info~=1
        info
        keyboard
    end
    u = z(1:nu);
    u0 = u;
    xp = mpc.phi*x0+mpc.gam*z+mpc.gamd*d;
    obj = obj+omega(2)*1/2*(x0-model.x_s)'*mpc.Q*(x0-model.x_s)+omega(1)*mpc.cx'*x0;
    x0 = A*x0+B*u+Bd*actD(k);
    
    res.X = [res.X x0];
    res.U = [res.U u0];
    res.info = [res.info info];
    res.obj = [res.obj obj];
    res.Z = [res.Z z];
    res.Xp = [res.Xp xp];
end

