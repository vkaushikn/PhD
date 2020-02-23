function [ mpc ] = centralized( model, penalty, constraint, terminal )
%Centralized: Makes the matrices for the centralized economic problem
nx = model.nx;nu = model.nu; nd = model.nd;
A = model.A;B = model.B; Bd = model.Bd;
N = model.N;eps1=model.eps;
cx = penalty.cx; cu = penalty.cu; cxt = penalty.cxt;
uub = constraint.uub; ulb = constraint.ulb;

if ~isempty(terminal.T)
T = terminal.T; t = terminal.t;
nt = length(t);
else
nt = 0;
T = zeros(nt,nx);
t = zeros(nt,1);
end

scale(1)= penalty.scale_eco;
scale(2) = penalty.scale_risk;
xs = model.x_s; us = model.u_s;
XS = repmat(xs,[N 1]);
US = repmat(us,[N 1]);


phi = []; gam = []; gamd = [];
phi1 = [];
for i = 1:N
  phi = [phi;A^i];
  phi1 = [phi1;A^(i-1)];
end %for i = 1:N
for i = 1:N
   temp = [zeros((i-1)*nx,nx);phi1(1:(N+1-i)*nx,:)];
   gam = [gam temp*B];
   gamd = [gamd temp*Bd];
end %for i = 1:N

%Economic
CX = [repmat(cx/scale(1),[N-1 1]); cxt/scale(1)]; CU = repmat(cu/scale(1),[N 1]);
mpc.qE = (gam'*CX+CU);

%Risk
QQ = 1/scale(2)*kron(full(eye(N-1)), penalty.Q);
QQ = blkdiag(QQ,1/scale(2)*penalty.P);
RR = 1/scale(2)*kron(full(eye(N)), penalty.R);
mpc.H = gam'*QQ*gam+RR;
mpc.qR_c = 1*-(gam'*QQ*XS+RR*US);
mpc.qR_x = gam'*QQ*phi;
mpc.qR_d = gam'*QQ*gamd;

mpc.LB = repmat(ulb,[N 1]);
mpc.UB = repmat(uub,[N 1]);

mpc.Ain = T*gam(end-nx+1:end,:);
mpc.bin_c = t;
mpc.bin_x = T*A^N;
mpc.bin_d = T*gamd(end-nx+1:end,:);

%state constraints
%mpc.Ain = [mpc.Ain;-gam];
%mpc.bin_c  = [mpc.bin_c;-repmat(constraint.xlb,[N 1])];
%mpc.bin_x = [mpc.bin_x;-phi];
%mpc.bin_d = [mpc.bin_d;-gamd];
mpc.gam = gam;
mpc.phi = phi;

mpc.gamd = gamd;

mpc.eps = eps1;
mpc.N = N;
mpc.nx = nx;
mpc.nu = nu;
mpc.nt = nt;
mpc.nd = nd*N;
mpc.QQ = QQ;
mpc.CX = CX;
mpc.RR = RR;
mpc.XS = XS;
mpc.US = US;
end