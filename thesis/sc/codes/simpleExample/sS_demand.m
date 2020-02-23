%%%Sept-12th 2011

%%% Remove the C & D matrix
%%% Impose constraint on the Orders placed

%%% Step change in demand at time k = 30
%----------------------------------------%
%Initializeo the model and the parameters
%----------------------------------------%
PI_K = 1;
original.A = eye(4);
original.B{1} = [-1 0 0 0; -1 0 0 0;0 0 -1 0;0 1 -1 0];
original.B{2} = [0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0];
original.B{3} = [0 0 1 0; 0 0 0 0; 0 0 0 1;0 0 0 0];
model.Bd = [0;1;0;0];

max_delay = 2;
original.nu = 4;
original.nx = 4;

model.A = [original.A];

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

model.Bd = [model.Bd;zeros(max_delay*original.nu,1)];

penalty.R = eye(original.nu);
penalty.Q1 = blkdiag(1,10);
penalty.Q2 = blkdiag(1,10);

constraint.ulb = 1e-4*[-2;-2;-2;-2]; constraint.uub = [40;4000;40;4000];
%the orders are unbounded above!
%no state constraint
N = 5; 
betaa = 1000;
dx = [48;0;32;0;8;8;8;8;8;8;8;8]; %for distributed
decx = dx;
ncoopx = dx;
centx = dx; %for centralized
coopx = dx;

centu = [];
coopu = [];
ncoopu = [];
decu = [];


[nx nu] = size(model.B);
nu1 = 2;
nu2 = 2;
K = zeros(nu,nx);
pmax = 1; %maximum number of iterations
count1=0;count2=0; %#of times hot start failed.
sim_time = 50;
%------------------------------------------------------------%
%Main
%------------------------------------------------------------%
infeas = 0;
dem = 8;
Dem = ones(sim_time,1)*dem;
%Dem(31:end) = 10;
model.targetu = 1*[dem;dem;dem;dem];
model.targetx =[45;0;30;0;model.targetu;model.targetu];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     FUNCTIONS                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% There is a reason why utarget = 0 for decen/ncooop. It is a part
%%%%% of the problem formulation to get Orders to be equal to orderupto policy


%make the matrices
Q = blkdiag(blkdiag(1*penalty.Q1,1*penalty.Q2),zeros(max_delay*nu));
R = penalty.R;
[ K P E] = \
    dlqr(model.A,model.B,Q,R);
model.K = -K;
penalty.P = P;
penalty.P1 = penalty.P(1:2,1:2);
penalty.P2 = penalty.P(3:4,3:4);
%noncooperative distributed MPC
%Non cooperative MPC
%for subsystem-1
penalty.Q = blkdiag(blkdiag(penalty.Q1,0*penalty.Q2),zeros(max_delay*nu));
penalty.P =betaa*blkdiag(blkdiag(penalty.Q1,0*penalty.Q2),zeros(max_delay*nu));
%penalty.P = betaa*blkdiag(blkdiag(penalty.P1,0*penalty.P2),zeros(max_delay*nu));
mpcmatrices =[];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[eye(nu1) zeros(nu1,nu2) zeros(nu1,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub(1:nu1),[N 1]);...
		   repmat(-constraint.ulb(1:nu1),[N 1])];

%enforce that other subsystem 'u' is fixed in distributed MPC
Dmod1 = kron(full(eye(N)),[zeros(nu2,nu1) eye(nu2) zeros(nu2,nx)]);
mpcmatrices.D = [mpcmatrices.D;Dmod1];


%add the constraint on orders
lhs1 = kron(full(eye(N)),[0 -1 0 0 -PI_K 0 zeros(1,nx-2)]);
%lhs1 = kron(full(eye(N)),[
mpcmatrices.lhs =[mpcmatrices.lhs;lhs1];
mpcmatrices.rhs =[mpcmatrices.rhs;repmat(-PI_K*model.targetx(1),[N 1])];


dmpcmatrices{1} = mpcmatrices;
%for subsystem-2, give no penalty to subsystem-1 states
penalty.Q = blkdiag(blkdiag(0*penalty.Q1,penalty.Q2),zeros(max_delay*nu));
penalty.P = betaa*blkdiag(blkdiag(0*penalty.Q1,penalty.Q2),zeros(max_delay*nu));
%penalty.P = betaa*blkdiag(blkdiag(0*penalty.P1,1*penalty.P2),zeros(max_delay*nu));
mpcmatrices = [];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[zeros(nu2,nu1) eye(nu2) zeros(nu2,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub(nu1+1:end),[N 1]);...
		   repmat(-constraint.ulb(nu1+1:end),[N 1])];
%enforce the other subsystem 'u' to be fixed in distributed MPC
Dmod2 = kron(full(eye(N)),[eye(nu1) zeros(nu1,nu2) zeros(nu1,nx)]);
mpcmatrices.D = [mpcmatrices.D;Dmod2];
lhs1 = kron(full(eye(N)),[0 0 0 -1 0 0 -PI_K 0 zeros(1,nx-4)]);
%mpcmatrices.lhs =[mpcmatrices.lhs;lhs1];
%mpcmatrices.rhs =[mpcmatrices.rhs;repmat(-PI_K*model.targetx(3),[N 1])];

dmpcmatrices{2} = mpcmatrices;



%Cooperative MPC
%for subsystem-1
penalty.Q = blkdiag(blkdiag(penalty.Q1,penalty.Q2),zeros(max_delay*nu));
penalty.P = betaa*blkdiag(blkdiag(penalty.Q1,penalty.Q2),zeros(max_delay*nu));
%penalty.P = betaa*penalty.P;
mpcmatrices =[];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[eye(nu1) zeros(nu1,nu2) zeros(nu1,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub(1:nu1),[N 1]);...
		   repmat(-constraint.ulb(1:nu1),[N 1])];

%enforce that other subsystem 'u' is fixed in distributed MPC
Dmod1 = kron(full(eye(N)),[zeros(nu2,nu1) eye(nu2) zeros(nu2,nx)]);
mpcmatrices.D = [mpcmatrices.D;Dmod1];
cmpcmatrices{1} = mpcmatrices;

%for subsystem-2, give no penalty to subsystem-1 states
penalty.Q = blkdiag(blkdiag(penalty.Q1,penalty.Q2),zeros(max_delay*nu));
%penalty.P = betaa*blkdiag(blkdiag(penalty.Q1,penalty.Q2),zeros(max_delay*nu));
penalty.P = betaa*penalty.P;
mpcmatrices = [];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[zeros(nu2,nu1) eye(nu2) zeros(nu2,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub(nu1+1:end),[N 1]);...
		   repmat(-constraint.ulb(nu1+1:end),[N 1])];
%enforce the other subsystem 'u' to be fixed in distributed MPC
Dmod2 = kron(full(eye(N)),[eye(nu1) zeros(nu1,nu2) zeros(nu1,nx)]);
mpcmatrices.D = [mpcmatrices.D;Dmod2];
cmpcmatrices{2} = mpcmatrices;

%Centralized MPC
penalty.Q = blkdiag(blkdiag(penalty.Q1,penalty.Q2),zeros(max_delay*nu));
penalty.P =betaa*blkdiag(blkdiag(penalty.Q1,penalty.Q2),zeros(max_delay*nu));
%penalty.P = betaa*penalty.P;
mpcmatrices = [];
mpcmatrices = mpcmake1(model,penalty,N);
mpcmatrices.lhs = kron(full(eye(N)),[eye(nu) zeros(nu,nx)]);
mpcmatrices.lhs = [mpcmatrices.lhs;-mpcmatrices.lhs];
mpcmatrices.rhs = [repmat(constraint.uub,[N 1]);...
		   repmat(-constraint.ulb,[N 1])];




model.targetu = 0*[dem;dem;dem;dem];
model.targetx =[45;0;30;0;model.targetu;model.targetu];
  %%%%%%%%%%%%%%%%%%Non cooperative  MPC  %%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:sim_time
  dem = Dem(k);
  %set the targets
  if k<=30
    model.x = ncoopx(:,k);%-[target;dem*ones(max_delay*nu,1)];
    model.targetx = [45;0;30;0;8;8;8;8;8;8;8;8];
  else
    model.x = ncoopx(:,k);%-[target;dem*ones(max_delay*nu,1)];
    model.targetx = [45;0;30;0;8;8;8;8;8;8;8;8];
  endif 
  %hot starts (sharing of iterate zero of inputs)
  if k == 1
     %some feasible starting point.   
     vecu1_0 = dem*ones(N*nu1,1);
     vecu2_0 = dem*ones(N*nu2,1);
   else
    vecu1_0 = [vecu1_0(3:end);dem*ones(nu1,1)]; %-0*K(1:2,:)*(ncoopx1(:,k)-[target;0*ncoopx1(5:end,k)])]; %it is K_f*x(N)
    vecu2_0 = [vecu2_0(3:end);dem*ones(nu2,1)]; %-0*K(3:4,:)*(ncoopx1(:,k)-[target;0*ncoopx1(5:end,k)])]; 
    %steady state input is zeros.
  endif
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  for iter = 1:pmax
  %subsystem-1
  d = [];
  d = model.A*model.x+model.Bd*dem;
  d = [d;repmat(model.Bd*dem,[N-1 1])];%satisfy model
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
  temp = uk(1:2,:);%optimal 
  vecu1_o = [];
  for tempiter = 1:N
      vecu1_o = [vecu1_o;temp(:,tempiter)];
  end

  %subsystem-2
  d = [];
  d = model.A*model.x+model.Bd*dem; % (no disturbance)+model.d(1:nx);
  d = [d;repmat(model.Bd*dem,[N-1 1])];%satisfy model
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
   temp = uk(3:4,:);%optimal 
   vecu2_o = [];
     for tempiter = 1:N
      vecu2_o = [vecu2_o;temp(:,tempiter)];
   end
 

  %update inputs and share
  vecu1_0 = 1*0.5*vecu1_0+1*0.5*vecu1_o;
  vecu2_0 = 1*0.5*vecu2_0+1*0.5*vecu2_o;

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
  ncoopx(:,k+1) = model.A*ncoopx(:,k)+model.B*ncoopu(:,k)+model.Bd*dem;
  ncoopx1(:,k+1) = ncoopx(:,k+1);
  for i = 2:N
    ncoopx1(:,k+1) = model.A*ncoopx1(:,k+1)+model.B*[vecu1_0((i-1)*nu1+1:i*nu1);vecu2_0((i-1)*nu1+1:i*nu1)]+model.Bd*dem;;
  end
end

                         %%%%%%%%%%%%%%%%%% Decentralized MPC  %%%%%%%%%%%%%%%%%
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:sim_time
  dem = Dem(k);
  if k<=30
    model.x = decx(:,k);%-[target;dem*ones(max_delay*nu,1)];
    model.targetx =  [45;0;30;0;8;8;8;8;8;8;8;8];
  else
    model.x = decx(:,k);%-[target;dem*ones(max_delay*nu,1)];
    model.targetx =  [45;0;30;0;8;8;8;8;8;8;8;8];
  endif 
  
 
  %hot starts (sharing of iterate zero of inputs)
  vecu1_0 = dem*ones(N*2,1);
  vecu2_0 = dem*ones(N*2,1);
 
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  for iter = 1:1 %only one iteration in decentralized
  %subsystem-1
  d = [];
  d = model.A*model.x+model.Bd*dem;
  d = [d;repmat(model.Bd*dem,[N-1 1])];%satisfy model
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
  temp = uk(1:2,:);%optimal 
  vecu1_o = [];
  for tempiter = 1:N
      vecu1_o = [vecu1_o;temp(:,tempiter)];
  end

  %subsystem-2
  d = [];
  d = model.A*model.x+model.Bd*dem;
  d = [d;repmat(model.Bd*dem,[N-1 1])];%satisfy model
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
   temp = uk(3:4,:);%optimal 
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
  decx(:,k+1) = model.A*decx(:,k)+model.B*decu(:,k)+model.Bd*dem;
  decx1(:,k+1) = decx(:,k+1);
  for i = 2:N
    decx1(:,k+1) = model.A*decx1(:,k+1)+model.B*[vecu1_0((i-1)*nu1+1:i*nu1);vecu2_0((i-1)*nu2+1:i*nu2)]+model.Bd*dem;
   
  end
end



 
model.targetu = 1*[dem;dem;dem;dem];
model.targetx =[45;0;30;0;model.targetu;model.targetu];
                        %%%%%%%%%%%%%%%%%% COOPERATIVE MPC %%%%%%%%%%%%%%%%%%%%%
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:sim_time
  dem = Dem(k);
    if k<=30
    model.x = coopx(:,k);%-[target;dem*ones(max_delay*nu,1)];
    model.targetx =  [45;0;30;0;8;8;8;8;8;8;8;8];
  else
    model.x = coopx(:,k);%-[target;dem*ones(max_delay*nu,1)];
    model.targetx =  [45;0;30;0;8;8;8;8;8;8;8;8];
  endif 
 
  %hot starts (sharing of iterate zero of inputs)
  if k == 1
     %some feasible starting point.   
     vecu1_0 = dem*ones(N*2,1);
     vecu2_0 = dem*ones(N*2,1);
   else
    vecu1_0 = [vecu1_0(3:end);dem*ones(nu1,1)];%-0*K(1:2,:)*(coopx1(:,k)-[target;0*coopx1(5:end,k)])]; %it is K_f*x(N)
    vecu2_0 = [vecu2_0(3:end);dem*ones(nu2,1)];%-0*K(3:4,:)*(coopx1(:,k)-[target;0*coopx1(5:end,k)])]; 
    %steady state input is zeros.
  endif
  %dynamic MPC
  vecu1_p = vecu1_0;
  vecu2_p = vecu2_0;
  for iter = 1:pmax
  %subsystem-1
  d = [];
  d = model.A*model.x+model.Bd*dem;
  d = [d;repmat(model.Bd*dem,[N-1 1])];%satisfy model
  d = [d;vecu2_0]; %add constraint that u2 be held constant at the
		   %shared value
  cmpcmatrices{1}.d_eq = d;
  cfixedmpcmatrices{1} = qp_fix(cmpcmatrices{1});
  [xk uk obj info] = mpcregulation1(cfixedmpcmatrices{1},model,N);
  info;
  if info.info ~=0
  info.info;
  infeas = 1;
  end
  temp = uk(1:2,:);%optimal 
  vecu1_o = [];
  for tempiter = 1:N
      vecu1_o = [vecu1_o;temp(:,tempiter)];
  end

  %subsystem-2
  d = [];
  d = model.A*model.x + model.Bd*dem; 
  d = [d;repmat(model.Bd*dem,[N-1 1])];%satisfy model
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
  temp = uk(3:4,:);%optimal 
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
  coopx(:,k+1) = model.A*coopx(:,k)+model.B*coopu(:,k)+model.Bd*dem;
  coopx1(:,k+1) = coopx(:,k+1);
  for i = 2:N
    coopx1(:,k+1) = model.A*coopx1(:,k+1)+model.B*[vecu1_0((i-1)*nu1+1:i*nu1);vecu2_0((i-1)*nu2+1:i*nu2)]+model.Bd*dem;
  end
end

                        %%%%%%%%%%%%%%%%%% CENTRALIZED  MPC %%%%%%%%%%%%%%%%%%%%
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:sim_time
  dem = Dem(k);
   %set the targets
    if k<=30
     model.x = centx(:,k);%-[target;dem*ones(max_delay*nu,1)];
     model.targetx =  [45;0;30;0;8;8;8;8;8;8;8;8];
    else
     model.x = centx(:,k);%-[target;dem*ones(max_delay*nu,1)];
     model.targetx =  [45;0;30;0;8;8;8;8;8;8;8;8];
    endif 

  
  d = model.A*model.x+model.Bd*dem; 
  d = [d; repmat(model.Bd*dem,[N-1 1])];%satisfy model
  %d = [d;0;0]; %terminal constraint
  mpcmatrices.d_eq = d;
  fixedmpcmatrices = qp_fix(mpcmatrices);
  [xk uk obj info] = mpcregulation1(fixedmpcmatrices,model,N);
  k;
  info;
  centu(:,k) = uk(:,1);
  centx(:,k+1) = model.A*centx(:,k)+model.B*centu(:,k)+model.Bd*dem;
end


time = 0:sim_time;
target =[[45*ones(30,1);45*ones(sim_time+1-30,1)] [30*ones(30,1);30*ones(sim_time+1-30,1)]];
data = [time' decx([1,3],:)' ncoopx([1,3],:)' coopx([1,3],:)' centx([1,3],:)' target];

%plot bullwhip effect
time = 0:sim_time-1;
data1 = [time' decu([2,4],:)', ncoopu([2,4],:)' coopu([2,4],:)' \
	centu([2,4],:)'];

save -ascii sS_demand.dat data
save -ascii sS_demand_input.dat data1







   




