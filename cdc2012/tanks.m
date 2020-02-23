%Compare different MPC's

%----------------------------------------%
%initialize the model and the parameters
%----------------------------------------%
global nu1 nu2 u1loc u2loc nx nu max_delay model penalty constraint N ;
global phi gam1 gam2 QQ;
%------------------ The system models----------------------------------
% DO NOT CHANGE THESE PARAMETERS. THE OTHER DATA in Paper is for these parameters.
r =1.1;
max_delay = 0;
original.A = eye(2);
betaa = 200; %terminal penalty maginifcation factor
original.B{1} = [-1 -1 1 0 ; 0 r -1 -1 ];
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
penalty.Q = blkdiag(blkdiag(penalty.Q1,penalty.Q2),1e-8*eye(max_delay*original.nu)); 
						   constraint.ulb = -1*[2;2;2;2]; constraint.uub = 1*[2;2;2;2];



target = [0;0];
model.targetx = zeros(nx,1);
model.targetu = zeros(nu,1);



%reshaping model.B = [model.B1 model.B2]
model.B1 = model.B(:,u1loc);
model.B2 = model.B(:,u2loc);
model.B = [];
model.B = [model.B1 model.B2];
penalty.R1 = [10 0;0 1];
penalty.R2 = [1 0 ; 0 10 ];
penalty.R = blkdiag(penalty.R1,penalty.R2);



penalty.K = [-0.40220 -0.22578;-0.15384 0.19181; 0.17642 -0.15384; -0.22578 -0.37962];
PPP = [1.40220 0.22578;0.22578 1.37962];
penalty.P = PPP;

%N,pmax,initial state,sim_time
infeas = 0;
pmax = 1;
N = 5;
initial_state= [7.5;7.5;zeros(max_delay*original.nu,1)]; %dont change this
				%initial state.(11,11) gives bad
				%performance for Terminal constraint
sim_time = 30;
K = penalty.K;
%-------------------Make the problem matrices for different problems-------------------
function [cmpc mpc] = MPCmake1(betaa)
 global model penalty constraint N nx nu nu1 nu2 u1loc u2loc;
 global phi gam1 gam2 QQ;
 phi =  [];
 gam1 = [];
 gam2 = [];
 gam =  [];
 for i = 1:N
   phi = [phi;model.A^i];
 endfor

 for i = 1:N
    temp = [zeros((i-1)*nx,nx);phi(1:(N+1-i)*nx,:)];
    gam1 = [gam1 temp*model.B1];
    gam2 = [gam2 temp*model.B2];
 endfor

 gam = [gam1 gam2];

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

 %Terminal constraint MPC
 mpc.A = [gam1(end-nx+1:end,:) gam2(end-nx+1:end,:)];
 mpc.beq = model.A^N;

 %Terminal region
 K = penalty.K;
 F = model.A-model.B*K;
 H = [K];
 E = [eye(nu);-eye(nu)];
 e1 = [constraint.uub;-constraint.ulb];
 [tstar Ain Bin] = Oinf(F,H,E,e1);
 %remocw redundant constraints
 A = [];
 b = [];
 for i = 1:length(Bin)
   if Ain(i,1)~=0 || Bin(i,2)~=0
     A = [A;Ain(i,:)];
     b = [b;Bin(i)];
   endif
 endfor
 c = [0;0];
 bk = b; % preserve
 b = b - A*c; % polytope A*x <= b now includes the origin
 % obtain dual polytope vertices
 D = A ./ repmat(b,[1 size(A,2)]);
 k = convhulln(D);
 % record which constraints generate points on the convex hull
 nr = unique(k(:));
 An=A(nr,:);
 bn=bk(nr);
 mpc.Ain = An*mpc.A;
 mpc.bineq{1} = bn;
 mpc.bineq{2} = An*mpc.beq;

 %the same matrices for cooperative MPC
 cmpc{1}.Ain = mpc.Ain(:,1:N*nu1);
 cmpc{1}.bineq{1} = bn;
 cmpc{1}.bineq{2} = An*mpc.beq;
 cmpc{1}.bineq{3} = mpc.Ain(:,N*nu1+1:end);

 cmpc{2}.Ain = mpc.Ain(:,N*nu1+1:end);
 cmpc{2}.bineq{1} = bn;
 cmpc{2}.bineq{2} = An*mpc.beq;
 cmpc{2}.bineq{3} = mpc.Ain(:,1:N*nu1);

endfunction

%--------------------------------------------------------------------------------

%---------- MPC (with terminal region)-------------------------------------------
%-------------------------------------------------------------------------------
%make the matrices
[cmpc mpc] = MPCmake1(1); %betaa factor is 1.

%finding the initial input for cooperative MPC
%find initial input.
%Finding an input that takes me to zero. 
if 1
model.x = initial_state-[target;zeros(max_delay*nu,1)];
mpc.q = mpc.c*model.x;
mpc.b = -mpc.beq*model.x;
[uk obj info] = qp([],mpc.H,mpc.q,mpc.A,mpc.b,mpc.LB,mpc.UB);
info
vecu1_s =  [2;0;2;0;2;0;0;0;1.5;0];
vecu2_s =  [0;2;0;2;0;2;0;0;0;1.5];

%Use terminal constraint MPC as the initial guess
model.x = initial_state;
mpc.q = mpc.c*model.x;
mpc.b = -mpc.beq*model.x;
[uk obj info] = qp([],mpc.H,mpc.q,mpc.A,mpc.b,mpc.LB,mpc.UB);
info
keyboard
vecu1_s = uk(1:N*nu1);
vecu2_s = uk(N*nu1+1:end);

coopx = initial_state;
coopu = [];
val = [];
uall = [];
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
  endif
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  iter = 1;
  while iter<=pmax
    cmpc{1}.q = cmpc{1}.cx*model.x+cmpc{1}.cu*vecu2_0;
    cmpc{1}.bin = cmpc{1}.bineq{1}-cmpc{1}.bineq{2}*model.x-cmpc{1}.bineq{3}*vecu2_0;
   [vecu1_o obj1 info] = qp(vecu1_0,cmpc{1}.H,cmpc{1}.q,[],[],cmpc{1}.LB,cmpc{1}.UB,[],cmpc{1}.Ain,cmpc{1}.bin);
   if info.info ~=0
     info.info
     infeas = 1;
   end
   cmpc{2}.q = cmpc{2}.cx*model.x+cmpc{2}.cu*vecu1_0;
   cmpc{2}.bin = cmpc{2}.bineq{1}-cmpc{2}.bineq{2}*model.x-cmpc{2}.bineq{3}*vecu1_0;
   [vecu2_o obj2 info] = qp(vecu2_0,cmpc{2}.H,cmpc{2}.q,[],[],cmpc{2}.LB,cmpc{2}.UB,[],cmpc{2}.Ain,cmpc{2}.bin);
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
   iter+=1;
  endwhile

  %identify final input at time k
  %u = 0 is the target, so no need to add targets here.
  coopu(:,k) = [vecu1_0(1:nu1);vecu2_0(1:nu2)];
  uall(:,k) = [vecu1_0;vecu2_0];
  %update model
  coopx(:,k+1) = model.A*coopx(:,k)+model.B*coopu(:,k);
  temp = phi*model.x+ gam1*vecu1_0 + gam2*vecu2_0;
  coopx1(:,k+1) = temp(end-nx+1:end);
  val(k) = 1/2*([vecu1_0;vecu2_0]'*mpc.H*[vecu1_0;vecu2_0]+ 2*[vecu1_0;vecu2_0]'*mpc.c*model.x+model.x'*phi'*QQ*phi*model.x);
end

% SIT = 1 : Coop MPC, Terminal constraint, 1 iteration
SIT=1;
DATA{SIT}.U = coopu;
DATA{SIT}.X = coopx;
DATA{SIT}.Val = val;
DATA{SIT}.uall = uall;
end
%-------------------Cooperative MPC, Terminal Constraint-----------------------------------
%---------------------(Iterate to convergence)---------------------------------------------
if 1
coopx = initial_state;
coopu = [];
val = [];
uall = [];
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
  endif
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  iter = 1;
  exitflag = 1;
  while exitflag 
    cmpc{1}.q = cmpc{1}.cx*model.x+cmpc{1}.cu*vecu2_0;
    cmpc{1}.bin = cmpc{1}.bineq{1}-cmpc{1}.bineq{2}*model.x-cmpc{1}.bineq{3}*vecu2_0;
   [vecu1_o obj1 info] = qp(vecu1_0,cmpc{1}.H,cmpc{1}.q,[],[],cmpc{1}.LB,cmpc{1}.UB,[],cmpc{1}.Ain,cmpc{1}.bin);
   if info.info ~=0
     info.info
     infeas = 1;
   end
   cmpc{2}.q = cmpc{2}.cx*model.x+cmpc{2}.cu*vecu1_0;
   cmpc{2}.bin = cmpc{2}.bineq{1}-cmpc{2}.bineq{2}*model.x-cmpc{2}.bineq{3}*vecu1_0;
   [vecu2_o obj2 info] = qp(vecu2_0,cmpc{2}.H,cmpc{2}.q,[],[],cmpc{2}.LB,cmpc{2}.UB,[],cmpc{2}.Ain,cmpc{2}.bin);
   if info.info ~=0
     info.info
     infeas = 1;
   end
   %update inputs and share
   vecu1_old = vecu1_0;
   vecu2_old = vecu2_0;
   vecu1_0 = 0.5*vecu1_0+0.5*vecu1_o;
   vecu2_0 = 0.5*vecu2_0+0.5*vecu2_o;
   if infeas == 1 
      printf('WAIT WAIT something is wrong');
      keyboard
   end
   infeas = 0;
   norm([vecu1_old;vecu2_old]-[vecu1_0;vecu1_0],2)
   exitflag = ~(norm([vecu1_old;vecu2_old]-[vecu1_0;vecu2_0],2)<1e-2);
  endwhile

  %identify final input at time k
  %u = 0 is the target, so no need to add targets here.
  coopu(:,k) = [vecu1_0(1:nu1);vecu2_0(1:nu2)];
  uall(:,k) = [vecu1_0;vecu2_0];
  %update model
  coopx(:,k+1) = model.A*coopx(:,k)+model.B*coopu(:,k);
  temp = phi*model.x+ gam1*vecu1_0 + gam2*vecu2_0;
  coopx1(:,k+1) = temp(end-nx+1:end);
  val(k) = 1/2*([vecu1_0;vecu2_0]'*mpc.H*[vecu1_0;vecu2_0]+ 2*[vecu1_0;vecu2_0]'*mpc.c*model.x+model.x'*phi'*QQ*phi*model.x);
end

%SIT = 2 : Coop MPC, Terminal condition, Iterated to convergence
SIT=2;
DATA{SIT}.U = coopu;
DATA{SIT}.X = coopx;
DATA{SIT}.Val = val;
DATA{SIT}.uall = uall;
end

%-------------------Centralized MPC-----------------------------------------
%                  (Terminal region)

centx = initial_state;
centu = [];
uall = [];
for k = 1:sim_time
  model.x = centx(:,k)-[target;zeros(max_delay*nu,1)];
  mpc.q = mpc.c*model.x;
  mpc.bin = mpc.bineq{1}-mpc.bineq{2}*model.x;
  [uk obj info] = qp([],mpc.H,mpc.q,[],[],mpc.LB,mpc.UB,[],mpc.Ain,mpc.bin);
  info
  %active constraint
%  [mpc.Ain*uk  mpc.bin]
%  pause
  centu(:,k) = [uk(1:nu1);uk(N*nu1+1:N*nu1+nu2)];
  centx(:,k+1) = model.A*centx(:,k)+model.B*centu(:,k);
  val(k) = 1/2*([uk]'*mpc.H*[uk]+ \
		2*[uk]'*mpc.c*model.x+model.x'*phi'*QQ*phi*model.x);
  uall(:,k) = uk;
end

%SIT = 3 : Centralized MPC, Terminal condition
SIT=3;
DATA{SIT}.U = centu;
DATA{SIT}.X = centx;
DATA{SIT}.Val = val;
DATA{SIT}.uall = uall;
%-------------------Centralized MPC----------------------------------------
%                  (Terminal constraint)
termx = initial_state;
termu = [];
for k = 1:sim_time
  model.x = termx(:,k)-[target;zeros(max_delay*nu,1)];
  mpc.q = mpc.c*model.x;
  mpc.b = -mpc.beq*model.x;
  [uk obj info] = qp([],mpc.H,mpc.q,mpc.A,mpc.b,mpc.LB,mpc.UB);
  info
  termu(:,k) = [uk(1:nu1);uk(N*nu1+1:N*nu1+nu2)];
  termx(:,k+1) = model.A*termx(:,k)+model.B*termu(:,k);
  val(k) = 1/2*([uk]'*mpc.H*[uk]+ 2*[uk]'*mpc.c*model.x+model.x'*phi'*QQ*phi*model.x);
end 

%SIT = 4: Centralized MPC, Terminal constraint
SIT = 4;
DATA{SIT}.U = termu;
DATA{SIT}.X = termx;
DATA{SIT}.Val = val;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%     RELAXAED OPTIMIZATION PROBLEM%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

betaa = 500; %includes initial_state in ths Region of attraction.
%---------- MPC (with honking beta)-------------------------------------------
%-------------------------------------------------------------------------------
%make the matrices
QQ1 = QQ;
cmp1 = cmpc;
mpc1 = mpc; % to calculate the cost with the original problem
[cmpc mpc] = MPCmake1(betaa); %betaa factor is 1.

%finding the initial input for cooperative MPC
%find initial input.
% we want x(N,i) < 1. 
%here we use the fact that we can use the expensive inputs!
%somehow got to find a "good" input. That keeps the value function below
%100
%vecu1_s = 0.5*[2;0;2;0;2;0;2;0;0;0];
%vecu2_s = 0.5*[0;2;0;2;0;2;0;2;0;0];
model.x = termx(:,1)-[target;zeros(max_delay*nu,1)];
mpc.q = mpc.c*model.x;
mpc.b = -mpc.beq*model.x;
[uk obj info] = qp([],mpc1.H,mpc1.q,mpc1.A,mpc1.b,mpc1.LB,mpc1.UB);
%vecu1_s = DATA{3}.uall(1:N*nu1,1);
%vecu2_s = DATA{3}.uall(N*nu1+1:end,1);
us = [vecu1_s;vecu2_s];
xs = initial_state;
chk = 1/2*(us'*mpc.H*us+2*us'*mpc.c*xs+xs'*phi'*QQ*phi*xs)
pause
coopx = initial_state;
coopu = [];
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
  endif
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  iter = 1;
  while iter<=pmax
     mpc.bin = mpc.bineq{1}-mpc.bineq{2}*model.x;
    cmpc{1}.q = cmpc{1}.cx*model.x+cmpc{1}.cu*vecu2_0;
    [vecu1_o obj1 info] = qp(vecu1_0,cmpc{1}.H,cmpc{1}.q,[],[],cmpc{1}.LB,cmpc{1}.UB);
   if info.info ~=0
     info.info
     infeas = 1;
   end
   cmpc{2}.q = cmpc{2}.cx*model.x+cmpc{2}.cu*vecu1_0;
   [vecu2_o obj2 info] = qp(vecu2_0,cmpc{2}.H,cmpc{2}.q,[],[],cmpc{2}.LB,cmpc{2}.UB);
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
  endwhile

  %identify final input at time k
  %u = 0 is the target, so no need to add targets here.
  coopu(:,k) = [vecu1_0(1:nu1);vecu2_0(1:nu2)];
  %update model
  coopx(:,k+1) = model.A*coopx(:,k)+model.B*coopu(:,k);
  temp = phi*model.x+ gam1*vecu1_0 + gam2*vecu2_0;
  coopx1(:,k+1) = temp(end-nx+1:end);
  val(k) = 1/2*([vecu1_0;vecu2_0]'*mpc1.H*[vecu1_0;vecu2_0]+ \
		2*[vecu1_0;vecu2_0]'*mpc1.c*model.x+model.x'*phi'*QQ1*phi*model.x);
  uk = [vecu1_0;vecu2_0];
  [mpc.Ain*uk mpc.bin]
  1/2*(uk'*mpc.H*uk+2*uk'*mpc.c*model.x+model.x'*phi'*QQ*phi*model.x)
  xn = [phi*model.x+[gam1 gam2]*uk](end-nx+1:end);
  xn'*penalty.P*xn
  length( find(mpc.Ain*uk <=mpc.bin))
  pause
end

% SIT = 5 : Coop MPC, Honking beta, 1 iteration
SIT=5;
DATA{SIT}.U = coopu;
DATA{SIT}.X = coopx;
DATA{SIT}.Val = val;

%-------------------Centralized MPC-----------------------------------------
%                    (Honking beta)

centx = initial_state;
centu = [];
for k = 1:sim_time
  model.x = centx(:,k)-[target;zeros(max_delay*nu,1)];
  mpc.q = mpc.c*model.x;
  mpc.bin = mpc.bineq{1}-mpc.bineq{2}*model.x;
  [uk obj info] = qp([],mpc.H,mpc.q,[],[],mpc.LB,mpc.UB);
  info
  centu(:,k) = [uk(1:nu1);uk(N*nu1+1:N*nu1+nu2)];
  centx(:,k+1) = model.A*centx(:,k)+model.B*centu(:,k);
  val(k) = 1/2*([uk]'*mpc1.H*[uk]+ 2*[uk]'*mpc1.c*model.x+model.x'*phi'*QQ1*phi*model.x);
end

%SIT = 6 : Centralized MPC, Honking beta
SIT=6;
DATA{SIT}.U = centu;
DATA{SIT}.X = centx;
DATA{SIT}.Val = val;

%-------------------Centralized MPC------------------------------------
%                        (QCQP)





%Costs for the first iterate?




%Find the costs

t1x = zeros(6,1);
t1u = zeros(6,1);
for i = 1:sim_time
 for sit = 1:6
   t1x(sit)+=(DATA{sit}.X(:,i+1))'*penalty.Q*(DATA{sit}.X(:,i+1));
   t1u(sit)+=(DATA{sit}.U(:,i))'*penalty.R*(DATA{sit}.U(:,i));
 end
end


LAM = t1x+t1u;
LAM(1) = (LAM(1)-LAM(3))/LAM(3);
LAM(2) = (LAM(2)-LAM(3))/LAM(3);
LAM(4) = (LAM(4)-LAM(3))/LAM(3);
LAM(5) = (LAM(5)-LAM(3))/LAM(3);
LAM(6) = (LAM(6)-LAM(3))/LAM(3);
LAM(3) = 0;
