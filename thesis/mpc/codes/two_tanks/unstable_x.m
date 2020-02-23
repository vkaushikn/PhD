% Sept-12,2012
% Try to make unstable. Probably cannot be made unstable.
% with regular recycle
% Try to make non-cooperative cyclic. 1 dumps to 2 and 2 dumps to 1.

%----------------------------------------%
%initialize the model and the parameters
%----------------------------------------%
r =1.1;
max_delay = 2;
original.A = eye(2);
betaa = 100; %terminal penalty maginifcation factor
original.B{1} = [-1 -1 1 0 0; 0 r -1 -1 1];
%original.B{2} = [0 0 0; 0 0 0];
%original.B{3} = [0 0 0; 0 0 0];
original.B{2} = [0 0 0 0 0;0 0 0 0 0];
original.B{3} = [0 0 0 0 0;0 0 0 0 0];

original.nu = 5;
original.nx = 2;

nu1 = 2;
nu2 = 3;
u1loc = [1 2];
u2loc = [3 4 5];
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
penalty.Q1 = 1;
penalty.Q2 = 1;
penalty.R = eye(original.nu);
penalty.R(1,1) = 100;
penalty.R(4,4) = 100;
penalty.Q = blkdiag(blkdiag(penalty.Q1,penalty.Q2),1e-8*eye(max_delay*original.nu)); 
constraint.ulb = -1*[2e-3;2e-3;2e-3;2e-3;2e-3]; constraint.uub = 1*[70;70;70;70;70];
%[K PPP E] = dlqr(model.A,model.B,penalty.Q,penalty.R);
%PPP = PPP(1:original.nx,1:original.nx);
PPP = eye(original.nx);
K = zeros(original.nu,original.nx);
[nx nu] = size(model.B);
K = zeros(nu,nx);
%no state constraint
N =2; %small horizon to have lesser constraints in the projection
       %algorithm.
ncoopx = [7;7;zeros(max_delay*original.nu,1)]; %for distributed
centx = ncoopx; %for centralized
coopx = ncoopx; % for cooperative
decx = ncoopx; % for decentralized
target = [3;3];

centu = [];
ncoopu = [];
coopu = [];
decu = [];


dnu = 1;
pmax = 1; %maximum number of iterations
sim_time = 30;
count1=0;count2=0; %#of times hot start failed.

%----------------------------------------------------------------------------------------------------------%

infeas = 0;

model.targetx = zeros(nx,1);
model.targetu = zeros(nu,1);

function [mpcmatrices] = mpcmake1(model,penalty,N)
[nx nu] = size(model.B);
%making the penalty matrix and linear penalty vector
temp = blkdiag(penalty.R,penalty.Q);
H = kron(full(eye(N)),temp);
H = blkdiag(H(1:N*nu+(N-1)*nx,1:N*nu+(N-1)*nx),penalty.P);
%H = 2*H;

%making the linear constraint matrix
D1 = kron(full(eye(N)),-model.B);
D2 = kron(full(diag(ones(N-1,1),-1)),-model.A);
D3 = kron(full(eye(N)),eye(size(model.A)));
D = [];
%to be made from the previous D matrix by inserting columns of D1
%between D2+D3
D4 = D2+D3;
for i = 1:N
    D = [D D1(:,(i-1)*nu+1:i*nu) D4(:,(i-1)*nx+1:i*nx)];
endfor
%adding the extra constraint to zero out the unstable mode(s)
%(special for this problem: All states are unstable)
%TerminalConstraint = [zeros(nx,N*(nu)+(N-1)*(nx)) eye(nx) ];
%D = [D;TerminalConstraint];
mpcmatrices.H = H;
%Check: Modify D in the main code for distributed codes.
mpcmatrices.D = D;
endfunction

function [xk uk obj info] = mpcregulation1(MPCMatrices,model,N)
[nx nu] = size(model.B);
H = MPCMatrices.H;
D = MPCMatrices.D;
%Check: lhs and rhs are the input constraint sets obtained from
%projection for distributed and constraint.uub(lb) for centralized.
%Should happen in main
lhs = MPCMatrices.lhs;
rhs = MPCMatrices.rhs;

%if targets are present
if ~isempty(model.targetx)
 tvec = repmat([model.targetu;model.targetx],[N 1]);
else
 tvec = zeros(N*(nx+nu),1);
end

q = -H*tvec;
d = MPCMatrices.d_eq; 
[z,obj,  info] = qp([],H,q,D,d,[],[],[],lhs,rhs);
xk = [];
uk = [];
count = 1;
for i = 1:N
  uk(:,i) = z(count:count+nu-1);
  count= count+nu;
  xk(:,i) = z(count:count+nx-1);
  count= count + nx;
endfor
endfunction


function [fixed] = qp_fix(mpcmatrices) 
%this function fixes the problem with depenedent rows in the equality
%matrix. The code is copied from the implementation in MATLAB
tolDep = 1e-4; %some tolerance. Can be manipulated.
D = mpcmatrices.D;
d = mpcmatrices.d_eq; %will see that D*z=d is consistent when rows of 
%D are dependent.
if (rank(D) < size(D)(1))
%now the consistency needs to be checked
  [Qa,Ra,Ea]=qr(D);
   depInd = find( abs(diag(Ra)) < tolDep );
   %if there is a zero element on the diagonal of Ra then it represnets
   %a dependent row
   if ~isempty(depInd)    % equality constraints are dependent
       disp('The equality constraints are dependent. Checking consistency');
        bdepInd =  abs(Qa(:,depInd)'*d) >= tolDep ;
        
        if any( bdepInd ) % Not consistent
          disp('\nThe system of equality constraints is not consistent. The QP will fail');
	else % the equality constraints are consistent
        % Delete the redundant constraints
        % By QR factoring the transpose, we see which columns of D'
        %   (rows of A) move to the end
          [Qat,Rat,Eat]=qr(D');        
          [i,j] = find(Eat); % Eat permutes the columns of D' (rows of D)
          remove = i(depInd);
          disp('The system of equality constraints is consistent. Removing');
          disp('the following dependent constraints before continuing:');
          disp(remove)
	  D((remove),:)=[];
          d((remove),:)=[];
        endif
        
   endif
endif
mpcmatrices.D = D;
mpcmatrices.d_eq = d;
fixed = mpcmatrices;
endfunction




%---------------------The QP problem constraints-----------------------------------------------------%

%Non cooperative MPC
%for subsystem-1
penalty.Q = blkdiag(blkdiag(1*penalty.Q1,0*penalty.Q2),zeros(max_delay*nu));
penalty.P = betaa*blkdiag(1*blkdiag(PPP(1),0*PPP(2)),zeros(max_delay*nu));
mpcmatrices =[];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[eye(nu1) zeros(nu1,nu2) zeros(nu1,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub(u1loc),[N 1]);...
		   repmat(-constraint.ulb(u1loc),[N 1])];

%enforce that other subsystem 'u' is fixed in distributed MPC
Dmod1 = kron(full(eye(N)),[zeros(nu2,nu1) eye(nu2) zeros(nu2,nx)]);
mpcmatrices.D = [mpcmatrices.D;Dmod1];
dmpcmatrices{1} = mpcmatrices;

%for subsystem-2, give no penalty to subsystem-1 states
penalty.Q = blkdiag(blkdiag(0*penalty.Q1,1*penalty.Q2),zeros(max_delay*nu));
penalty.P = betaa*blkdiag(blkdiag(0*PPP(1),PPP(2)),zeros(max_delay*nu));
mpcmatrices = [];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[zeros(nu2,nu1) eye(nu2) zeros(nu2,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub(u2loc),[N 1]);...
		   repmat(-constraint.ulb(u2loc),[N 1])];
%enforce the other subsystem 'u' to be fixed in distributed MPC
Dmod2 = kron(full(eye(N)),[eye(nu1) zeros(nu1,nu2) zeros(nu1,nx)]);
mpcmatrices.D = [mpcmatrices.D;Dmod2];
dmpcmatrices{2} = mpcmatrices;



%Cooperative MPC
%for subsystem-1
penalty.Q = blkdiag(blkdiag(1*penalty.Q1,1*penalty.Q2),zeros(max_delay*nu));
penalty.P = betaa*blkdiag(PPP,zeros(max_delay*nu));
mpcmatrices =[];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[eye(nu1) zeros(nu1,nu2) zeros(nu1,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub(u1loc),[N 1]);...
		   repmat(-constraint.ulb(u1loc),[N 1])];

%enforce that other subsystem 'u' is fixed in distributed MPC
Dmod1 = kron(full(eye(N)),[zeros(nu2,nu1) eye(nu2) zeros(nu2,nx)]);
mpcmatrices.D = [mpcmatrices.D;Dmod1];
cmpcmatrices{1} = mpcmatrices;

%for subsystem-2, give no penalty to subsystem-1 states
penalty.Q = blkdiag(blkdiag(1*penalty.Q1,1*penalty.Q2),zeros(max_delay*nu));
penalty.P = betaa*blkdiag(PPP,zeros(max_delay*nu));
mpcmatrices = [];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[zeros(nu2,nu1) eye(nu2) zeros(nu2,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub(u2loc),[N 1]);...
		   repmat(-constraint.ulb(u2loc),[N 1])];
%enforce the other subsystem 'u' to be fixed in distributed MPC
Dmod2 = kron(full(eye(N)),[eye(nu1) zeros(nu1,nu2) zeros(nu1,nx)]);
mpcmatrices.D = [mpcmatrices.D;Dmod2];
cmpcmatrices{2} = mpcmatrices;


%Centralized MPC
penalty.Q = blkdiag(blkdiag(1*penalty.Q1,1*penalty.Q2),zeros(max_delay*nu));
penalty.P =betaa*blkdiag(PPP,zeros(max_delay*nu));
mpcmatrices = [];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[eye(nu) zeros(nu,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub,[N 1]);...
		   repmat(-constraint.ulb,[N 1])];
%add constraint that terminal state be zero

%TerminalConstraint = [zeros(2,N*(nu)+(N-1)*(nx)) eye(2) zeros(2,nx-2) ];
%mpcmatrices.D = [mpcmatrices.D;TerminalConstraint];


%---------------------------------------------------------------------------------------------------------------------------%


%%%%%%----------------------IMPLEMENT MPC-----------------------------------------------------------------------------------%


                        %%%%%%%%%%%%%%%%%% NON COOPERATIVE MPC%%%%%%%%%%%%%%%%%%
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:sim_time
  %set the targets
  if k<=5
    model.x = ncoopx(:,k)-[target;zeros(max_delay*nu,1)];
  else
    model.x = ncoopx(:,k)-[target;zeros(max_delay*nu,1)];
  endif 
  %hot starts (sharing of iterate zero of inputs)
  if k == 1
     %some feasible starting point.   
     vecu1_0 = zeros(N*nu1,1);
     vecu2_0 = zeros(N*nu2,1);
   else
    vecu1_0 = [vecu1_0(nu1+1:end);-0*K(u1loc,:)*(ncoopx1(:,k)-[target;0*ncoopx1(original.nx+1:end,k)])]; %it is K_f*x(N)
    vecu2_0 = [vecu2_0(nu2+1:end);-0*K(u2loc,:)*(ncoopx1(:,k)-[target;0*ncoopx1(original.nx+1:end,k)])]; 
    %steady state input is zeros.
  endif
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  for iter = 1:pmax
  %subsystem-1
  d = [];
  d = model.A*model.x; % (no disturbance)+model.d(1:nx);
  d = [d;zeros((N-1)*nx,1)];%satisfy model
  d = [d;vecu2_0]; %add constraint that u2 be held constant at the
		   %shared value
  dmpcmatrices{1}.d_eq = d;
  dfixedmpcmatrices{1} = qp_fix(dmpcmatrices{1});
  [xk uk obj info] = mpcregulation1(dfixedmpcmatrices{1},model,N);
  info;
  if info.info ~=0
  info.info;
  infeas = 1;
  end
  temp = uk(u1loc,:);%optimal 
  vecu1_o = [];
  for tempiter = 1:N
      vecu1_o = [vecu1_o;temp(:,tempiter)];
  end

  %subsystem-2
  d = [];
  d = model.A*model.x; % (no disturbance)+model.d(1:nx);
  d = [d;zeros((N-1)*nx,1)];%satisfy model
  d = [d;vecu1_0]; %add constraint that u1 be held constant at the
		   %shared value
   dmpcmatrices{2}.d_eq = d;
  dfixedmpcmatrices{2} = qp_fix(dmpcmatrices{2});
  [xk uk obj info] = mpcregulation1(dfixedmpcmatrices{2},model,N);
  info;
  if info.info ~=0
  info.info;
  infeas = 1;
  end
  temp = uk(u2loc,:);
  vecu2_o = [];
  for tempiter = 1:N
      vecu2_o = [vecu2_o;temp(:,tempiter)];
  end
  

  %update inputs and share
  vecu1_0 = 0.5*vecu1_0+0.5*vecu1_o;
  vecu2_0 = 0.5*vecu2_0+0.5*vecu2_o;

  if infeas == 1 
     printf('WAIT WAIT something is wrong');
     pause
  end
  infeas = 0;
  endfor

  %identify final input at time k
  %u = 0 is the target, so no need to add targets here.
  ncoopu(:,k) = [vecu1_0(1:nu1);vecu2_0(1:nu2)];
  %update model
  ncoopx(:,k+1) = model.A*ncoopx(:,k)+model.B*ncoopu(:,k);
  ncoopx1(:,k+1) = ncoopx(:,k+1);
  for i = 2:N
    ncoopx1(:,k+1) = model.A*ncoopx1(:,k+1)+model.B*[vecu1_0((i-1)*nu1+1:i*nu1);vecu2_0((i-1)*nu2+1:i*nu2)];
  end
end

                         %%%%%%%%%%%%%%%%%% Decentralized MPC  %%%%%%%%%%%%%%%%%
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:sim_time
  %set the targets
  if k<=5
    model.x = decx(:,k)-[target;zeros(max_delay*nu,1)];
  else
    model.x = decx(:,k)-[target;zeros(max_delay*nu,1)];
  endif 
  %hot starts (sharing of iterate zero of inputs)
  if k == 1
     %some feasible starting point.   
     vecu1_0 = zeros(N*nu1,1);
     vecu2_0 = zeros(N*nu2,1);
   else
    vecu1_0 = 0*[vecu1_0(nu1+1:end);-K(u1loc,:)*(decx1(:,k)-[target;0*decx1(original.nx+1:end,k)])]; %it is K_f*x(N)
    vecu2_0 = 0*[vecu2_0(nu2+1:end);-K(u2loc,:)*(decx1(:,k)-[target;0*decx1(original.nx+1:end,k)])]; 
    %steady state input is zeros.
    %Do not share any inputsin decentralized MPC
  endif
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  for iter = 1:1 %only one iteration in decentralized
  %subsystem-1
  d = [];
  d = model.A*model.x; % (no disturbance)+model.d(1:nx);
  d = [d;zeros((N-1)*nx,1)];%satisfy model
  d = [d;vecu2_0]; %add constraint that u2 be held constant at the
		   %shared value
  dmpcmatrices{1}.d_eq = d;
  dfixedmpcmatrices{1} = qp_fix(dmpcmatrices{1});
  [xk uk obj info] = mpcregulation1(dfixedmpcmatrices{1},model,N);
  info;
  if info.info ~=0
  info.info;
  infeas = 1;
  end
  temp = uk(u1loc,:);%optimal 
  vecu1_o = [];
  for tempiter = 1:N
      vecu1_o = [vecu1_o;temp(:,tempiter)];
  end

  %subsystem-2
  d = [];
  d = model.A*model.x; % (no disturbance)+model.d(1:nx);
  d = [d;zeros((N-1)*nx,1)];%satisfy model
  d = [d;vecu1_0]; %add constraint that u1 be held constant at the
		   %shared value
   dmpcmatrices{2}.d_eq = d;
  dfixedmpcmatrices{2} = qp_fix(dmpcmatrices{2});
  [xk uk obj info] = mpcregulation1(dfixedmpcmatrices{2},model,N);
  info;
  if info.info ~=0
  info.info;
  infeas = 1;
  end
  temp = uk(u2loc,:);
  vecu2_o = [];
  for tempiter = 1:N
      vecu2_o = [vecu2_o;temp(:,tempiter)];
  end
  
  %update inputs and share
  vecu1_0 = vecu1_o;
  vecu2_0 = vecu2_o;

  if infeas == 1 
     printf('WAIT WAIT something is wrong');
     pause
  end
  infeas = 0;
  endfor

  %identify final input at time k
  %u = 0 is the target, so no need to add targets here.
  decu(:,k) = [vecu1_0(1:nu1);vecu2_0(1:nu2)];
  %update model
  decx(:,k+1) = model.A*decx(:,k)+model.B*decu(:,k);
  decx1(:,k+1) = decx(:,k+1);
  for i = 2:N
    decx1(:,k+1) = model.A*decx1(:,k+1)+model.B*[vecu1_0((i-1)*nu1+1:i*nu1);vecu2_0((i-1)*nu2+1:i*nu2)];
  end
end



                        %%%%%%%%%%%%%%%%%% COOPERATIVE MPC %%%%%%%%%%%%%%%%%%%%%
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:sim_time
  %set the targets
  if k<=5
    model.x = coopx(:,k)-[target;zeros(max_delay*nu,1)];
  else
    model.x = coopx(:,k)-[target;zeros(max_delay*nu,1)];
  endif 
  %hot starts (sharing of iterate zero of inputs)
  if k == 1
     %some feasible starting point.   
     vecu1_0 = zeros(N*nu1,1);
     vecu2_0 = zeros(N*nu2,1);
   else
    vecu1_0 = [vecu1_0(nu1+1:end);-0*K(u1loc,:)*(coopx1(:,k)-[target;0*coopx1(original.nx+1:end,k)])]; %it is K_f*x(N)
    vecu2_0 = [vecu2_0(nu2+1:end);-0*K(u2loc,:)*(coopx1(:,k)-[target;0*coopx1(original.nx+1:end,k)])]; 
    %steady state input is zeros.
  endif
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  for iter = 1:pmax
  %subsystem-1
  d = [];
  d = model.A*model.x; % (no disturbance)+model.d(1:nx);
  d = [d;zeros((N-1)*nx,1)];%satisfy model
  d = [d;vecu2_0]; %add constraint that u2 be held constant at the
		   %shared value
  cmpcmatrices{1}.d_eq = d;
  cfixedmpcmatrices{1} = qp_fix(cmpcmatrices{1});
  [xk uk obj info] = mpcregulation1(cfixedmpcmatrices{1},model,N);
  info;
  if info.info ~=0
  info.info;
  infeas = 1;;
  end
  temp = uk(u1loc,:);%optimal 
  vecu1_o = [];
  for tempiter = 1:N
      vecu1_o = [vecu1_o;temp(:,tempiter)];
  end

  %subsystem-2
  d = [];
  d = model.A*model.x; % (no disturbance)+model.d(1:nx);
  d = [d;zeros((N-1)*nx,1)];%satisfy model
  d = [d;vecu1_0]; %add constraint that u1 be held constant at the
		   %shared value
  cmpcmatrices{2}.d_eq = d;
  cfixedmpcmatrices{2} = qp_fix(cmpcmatrices{2});
  [xk uk obj info] = mpcregulation1(cfixedmpcmatrices{2},model,N);
  info;
  if info.info ~=0
  info.info;
  infeas = 1;
  end
  temp = uk(u2loc,:);
  vecu2_o = [];
  for tempiter = 1:N
     vecu2_o = [vecu2_o;temp(:,tempiter)];
  end
  

  %update inputs and share
  vecu1_0 = 0.5*vecu1_0+0.5*vecu1_o;
  vecu2_0 = 0.5*vecu2_0+0.5*vecu2_o;

  if infeas == 1 
     printf('WAIT WAIT something is wrong');
     keyboard
  end
  infeas = 0;
  endfor

  %identify final input at time k
  %u = 0 is the target, so no need to add targets here.
  coopu(:,k) = [vecu1_0(1:nu1);vecu2_0(1:nu2)];
  %update model
  coopx(:,k+1) = model.A*coopx(:,k)+model.B*coopu(:,k);
  coopx1(:,k+1) = coopx(:,k+1);
  for i = 2:N
    coopx1(:,k+1) = model.A*coopx1(:,k+1)+model.B*[vecu1_0((i-1)*nu1+1:i*nu1);vecu2_0((i-1)*nu2+1:i*nu2)];
  end
end

                        %%%%%%%%%%%%%%%%%% CENTRALIZED  MPC %%%%%%%%%%%%%%%%%%%%
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:sim_time
  if k<=5
    model.x = centx(:,k)-[target;zeros(max_delay*nu,1)];
  else
    model.x = centx(:,k)-[target;zeros(max_delay*nu,1)];
  end
  d = model.A*model.x; % (no disturbance)+model.d(1:nx);
  d = [d;zeros((N-1)*nx,1)];%satisfy model
  %d = [d;0;0]; %terminal constraint
  mpcmatrices.d_eq = d;
  fixedmpcmatrices = qp_fix(mpcmatrices);
  [xk uk obj info] = mpcregulation1(fixedmpcmatrices,model,N);
  k;
  info;
  centu(:,k) = uk(:,1);
  centx(:,k+1) = model.A*centx(:,k)+model.B*centu(:,k);
end


time = 0:sim_time;
time = time(:);
sp1 = repmat(target(1), [length(time) 1]);
sp2 = repmat(target(2), [length(time) 1]);
data = [time ncoopx(1,:)' coopx(1,:)' centx(1,:)' ncoopx(2,:)' \
	coopx(2,:)' centx(2,:)' sp1 sp2];

save -ascii unstable_x.dat data

time = 0:sim_time-1;
time = time(:);

data = [time ncoopu(1,:)' coopu(1,:)' centu(1,:)' ncoopu(2,:)' \
	coopu(2,:)' centu(2,:)'];

save -ascii unstable_u2.dat data

time = 0:sim_time-1;
time = time(:);

data = [time ncoopu(3,:)' coopu(3,:)' centu(3,:)' ncoopu(4,:)' \
	coopu(4,:)' centu(4,:)'];

save -ascii unstable_u1.dat data
