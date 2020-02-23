
% Rewrote the MPC by eliminating the states and then check for convergen%ce

% Find number of iterations to converge as a function of beta
%----------------------------------------%
%initialize the model and the parameters
%----------------------------------------%
global nu1 nu2 u1loc u2loc nx nu max_delay;
r =1.1;
max_delay = 0;
original.A = eye(2);
betaa = 10; %terminal penalty maginifcation factor
original.B{1} = [-1 -1 1 0 ; 0 r -1 -1 ];
%original.B{2} = [0 0 0; 0 0 0];
%original.B{3} = [0 0 0; 0 0 0];
original.B{2} = [0 0 0 0 0; 0 0 0 0 0];
original.B{3} = [0 0 0 0 0; 0 0 0 0 0];

original.nu = 4;
original.nx = 2;

nu1 = 2;
nu2 = 2;
u1loc = [1 2];
u2loc = [3 4];
model.A = [original.A];
%make the A and B matrices
for delay = 2:max_delay+1
 model.A = [model.A original.B{delay}];
end
model.B = original.B{1};
for delay = 1:max_delay
  if delay == 1
   model.B = [model.B; eye(original.nu)];
   temp = [zeros(original.nu,original.nx)];
   temp = [temp zeros(original.nu, max_delay*original.nu)];
   model.A = [model.A; temp];
  else
   model.B = [model.B;zeros(original.nu)];
   temp = [zeros(original.nu,original.nx)];
   temp1 = [zeros(original.nu,(delay-2)*original.nu) eye(original.nu)...
            zeros(original.nu,(max_delay-delay+1)*original.nu)];
   model.A = [model.A; temp temp1];   
  endif
endfor
[nx nu] = size(model.B)

penalty.Q1 = 1;
penalty.Q2 = 1;
penalty.R = eye(original.nu);

%$$Expensive inputs$$$$
penalty.R(1,1) = 10;%$
penalty.R(4,4) = 10;%$
%$$$$$$$$$$$$$$$$$$$$$$ 

penalty.Q = blkdiag(blkdiag(penalty.Q1,penalty.Q2),1e-8*eye(max_delay*original.nu)); 
						   constraint.ulb = -1*[2;2;2;2]; constraint.uub = 1*[2;2;2;2];
N =5;

initial_state= [3;3;zeros(max_delay*original.nu,1)]; %for distributed
target = [0;0];
model.targetx = zeros(nx,1);
model.targetu = zeros(nu,1);

pmax = 10000; %maximum number of iterations
sim_time = 1;
infeas = 0;

%reshaping model.B = [model.B1 model.B2]
model.B1 = model.B(:,u1loc);
model.B2 = model.B(:,u2loc);
model.B = [];
model.B = [model.B1 model.B2];
penalty.R1 = [10 0;0 1];
penalty.R2 = [1 0 ; 0 10 ];
penalty.R = blkdiag(penalty.R1,penalty.R2);
phi = [];
gam1 = [];
gam2 = [];
gam = [];

%[K PPP E] = dlqr(model.A,model.B,penalty.Q,penalty.R);
%PPP(find(PPP<1e-3)) = 0;
%penalty.P = PPP;
%K = zeros(5,2);
%PPP = eye(2);
K = [-0.40220 -0.22578;-0.15384 0.19181; 0.17642 -0.15384; -0.22578 -0.37962];
PPP = [1.40220 0.22578;0.22578 1.37962];
penalty.P = PPP;
for i = 1:N
  phi = [phi;model.A^i];
endfor

for i = 1:N
   temp = [zeros((i-1)*nx,nx);phi(1:(N+1-i)*nx,:)];
   gam1 = [gam1 temp*model.B1];
   gam2 = [gam2 temp*model.B2];
endfor

gam = [gam1 gam2];

Betavec = [1 2 4 10 20];
for i = 1:length(Betavec)
 betaa = Betavec(i);
 QQ = blkdiag(kron(eye(N-1),penalty.Q),betaa*penalty.P);
 RR1 = kron(eye(N),penalty.R1);
 RR2 = kron(eye(N),penalty.R2);
 cmpc{1}.H = gam1'*QQ*gam1+RR1;
 cmpc{1}.cx = gam1'*QQ*phi;
 cmpc{1}.cu = gam1'*QQ*gam2;
 cmpc{1}.LB = repmat(constraint.ulb(u1loc),[N 1]);
 cmpc{1}.UB = repmat(constraint.uub(u1loc),[N 1]);
 cmpc{2}.H = gam2'*QQ*gam2+RR2;
 cmpc{2}.cx = gam2'*QQ*phi;
 cmpc{2}.cu = gam2'*QQ*gam1;
 cmpc{2}.LB = repmat(constraint.ulb(u2loc),[N 1]);
 cmpc{2}.UB = repmat(constraint.uub(u2loc),[N 1]);
 mpc.H = [cmpc{1}.H cmpc{1}.cu; cmpc{2}.cu cmpc{2}.H];
 mpc.c = [cmpc{1}.cx;cmpc{2}.cx];
 mpc.LB = [cmpc{1}.LB;cmpc{2}.LB];
 mpc.UB = [cmpc{1}.UB;cmpc{2}.UB];

 
 centx = initial_state;
 centu = [];
 for k = 1:sim_time
   model.x = centx(:,k)-[target;zeros(max_delay*nu,1)];
   mpc.q = mpc.c*model.x;
   [uk obj info] = qp([],mpc.H,mpc.q,[],[],mpc.LB,mpc.UB);
   info
   centu(:,k) = [uk(1:nu1);uk(N*nu1+1:N*nu1+nu2)];
   centx(:,k+1) = model.A*centx(:,k)+model.B*centu(:,k);
 end

%uk contains the centralized solution

%---------------------Cooperative MPC-------------------------------------------

%find initial input.
% we want x(N,i) < 1. 
%here we use the fact that we can use the expensive inputs!
 vecu1_s = [1;0;1;0;0.5;0;0.5;0;0;0];
 vecu2_s = [0;1;0;1;0;0.5;0;0.5;0;0];
 
 %is the point feasible
 u_s = [vecu1_s;vecu2_s];
 val1 =1/2*( u_s'*mpc.H*u_s+2*u_s'*mpc.c*initial_state+initial_state'*phi'*QQ*phi*initial_state)
 val2 =  1/2*(uk'*mpc.H*u_s+2*uk'*mpc.c*initial_state+initial_state'*phi'*QQ*phi*initial_state)
 betaa

 coopx = initial_state;
 coopu = [];
 tauk = 0.1; 
 mu = betaa;
 for k = 1:sim_time
   %set the targets
    model.x = coopx(:,k)-[target;zeros(max_delay*nu,1)];
   %hot starts (sharing of iterate zero of inputs)
   if k == 1
      %some feasible starting point.Already found
      vecu1_0 = vecu1_s;
      vecu2_0 = vecu2_s;
     % continue;
    else
     vecu1_0 = [vecu1_0(nu1+1:end);-K(u1loc,:)*(coopx1(:,k))];
     vecu2_0 = [vecu2_0(nu2+1:end);-K(u2loc,:)*(coopx1(:,k))];
    %steady state input is zeros.
  endif
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  iter = 1;
  exitflag = 1;
  iter = 1;
  while exitflag % & iter<=pmax
    cmpc{1}.q = cmpc{1}.cx*model.x+cmpc{1}.cu*vecu2_0;
   [vecu1_o obj1 info] = qp([],cmpc{1}.H,cmpc{1}.q,[],[],cmpc{1}.LB,cmpc{1}.UB);
   if info.info ~=0
     info.info
     infeas = 1;
   end
   cmpc{2}.q = cmpc{2}.cx*model.x+cmpc{2}.cu*vecu1_0;
   [vecu2_o obj2 info] = qp([],cmpc{2}.H,cmpc{2}.q,[],[],cmpc{2}.LB,cmpc{2}.UB);
   if info.info ~=0
     info.info
     infeas = 1;
   end
   %update inputs and share
   vecu1_0 = 0.5*vecu1_0+0.5*vecu1_o;
   vecu2_0 = 0.5*vecu2_0+0.5*vecu2_o;

   if infeas == 1 
      printf('WAIT WAIT something is wrong');
      keyboard
   end
   infeas = 0;
   iter+=1
   uc = [vecu1_0;vecu2_0];
   norm(uc-uk,2)
   
   exitflag = ~(norm(uc-uk,2)<1e-4)
   
  endwhile
  pgapu(i) = norm(u_s-uk);
  pconv(i) = iter;
  pgap(i) = val1-val2;
  tough(i) = cond(mpc.H);
  %identify final input at time k
  %u = 0 is the target, so no need to add targets here.
  coopu(:,k) = [vecu1_0(1:nu1);vecu2_0(1:nu2)];
  %update model
  coopx(:,k+1) = model.A*coopx(:,k)+model.B*coopu(:,k);
  temp = phi*model.x+ gam1*vecu1_0 + gam2*vecu2_0;
  coopx1(:,k+1) = temp(end-nx+1:end);
end
end


















