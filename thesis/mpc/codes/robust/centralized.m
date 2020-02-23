function [ mpc ] = centralized( model, penalty, constraint )
%Centralized: Makes the matrices for the centralized economic problem
% Stage cost: (x-x_s)'Q(x-x_s)+(u-u_s)'R(u-u_s)+ cx'x+cu'u
% Terminal cost: (x-x_ss)'P(x-x_ss)+cxt'(x-x_ss)
% Eliminate all state equality constraints
% Regulate to origin
nx = model.nx;nu = model.nu; 
A = model.A;B = model.B; 
N = model.N;eps1=model.eps;
uub = constraint.uub; ulb = constraint.ulb;
phi = []; gam = []; gamd = [];
phi1 = [];
for i = 1:N
  phi = [phi;A^i]; %z = (u0,x1,u1,x2,...un-1,xn)
  phi1 = [phi1;A^(i-1)];
end
for i = 1:N
   temp = [zeros((i-1)*nx,nx);phi1(1:(N+1-i)*nx,:)];
   gam = [gam temp*B];
end

beta = constraint.beta;
QQ = kron(eye(N-1), penalty.Q);
QQ = blkdiag(QQ,penalty.P*beta);
RR = kron(eye(N), penalty.R);

mpc.H = gam'*QQ*gam+RR;
mpc.q = gam'*QQ*phi;

mpc.LB = repmat(ulb,[N 1]);
mpc.UB = repmat(uub,[N 1]);

mpc.gam = gam;
mpc.phi = phi;


mpc.eps = eps1;
mpc.N = N;
mpc.nx = nx;
mpc.nu = nu;


mpc.QQ = phi'*QQ*phi;

mpc.Q = penalty.Q;


end
