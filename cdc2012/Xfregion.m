global nu1 nu2 model mpc penalty ;
r =1.1;
max_delay = 0;
original.A = eye(2);
betaa = 10; %terminal penalty maginifcation factor
original.B{1} = [-1 -1 1 0; 0 r -1 -1];
%original.B{2} = [0 0 0; 0 0 0];
%original.B{3} = [0 0 0; 0 0 0];
original.B{2} = [0 0 0 0; 0 0 0 0];
original.B{3} = [0 0 0 0; 0 0 0 0];

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
  end
end
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

initial_state= [7;7;zeros(max_delay*original.nu,1)]; %for distributed
target = [0;0];
model.targetx = zeros(nx,1);
model.targetu = zeros(nu,1);

pmax = 100; %maximum number of iterations
sim_time = 1;
infeas = 0;

%reshaping model.B = [model.B1 model.B2]
model.B1 = model.B(:,u1loc);
model.B2 = model.B(:,u2loc);
model.B = [];
model.B = [model.B1 model.B2];
penalty.R1 = [10 0;0 1];
penalty.R2 = [1 0; 0 10];
penalty.R = blkdiag(penalty.R1,penalty.R2);
phi = [];
gam1 = [];
gam2 = [];
gam = [];

%[K PPP E] = dlqr(model.A,model.B,penalty.Q,penalty.R);
%PPP(find(PPP<1e-3)) = 0;
%penalty.P = PPP;
K = [-0.40220 -0.22578;-0.15384 0.19181; 0.17642 -0.15384; -0.22578 -0.37962];
PPP = [1.40220 0.22578;0.22578 1.37962];
penalty.P = PPP;
for i = 1:N
  phi = [phi;model.A^i];
end
for i = 1:N
   temp = [zeros((i-1)*nx,nx);phi(1:(N+1-i)*nx,:)];
   gam1 = [gam1 temp*model.B1];
   gam2 = [gam2 temp*model.B2];
end

gam = [gam1 gam2];

Xgrid =[linspace(-20,20,20);linspace(-20,20,20)];

a = 1;
QQ = blkdiag(kron(eye(N-1),penalty.Q),penalty.P);
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

mpc{1}.H = [cmpc{1}.H cmpc{1}.cu; cmpc{2}.cu cmpc{2}.H];
mpc{1}.c = [cmpc{1}.cx;cmpc{2}.cx];
mpc{1}.LB = [cmpc{1}.LB;cmpc{2}.LB];
mpc{1}.UB = [cmpc{2}.UB;cmpc{2}.UB];
mpc{1}.A = model.A^N;
mpc{1}.B = gam(end-nx+1:end,:);
mpc{1}.a = a;
CFeas = [];
%Feasible region for this problem
for i1 = 1:length(Xgrid(1,:))
   for i2 = 1:length(Xgrid(2,:))
       i1
       i2
       model.x = [Xgrid(1,i1);Xgrid(2,i2)];
       %options = optimset('Algorithm','interior-point'); % run interior-point algorithm
        % options = optimset(options,'Display','off');
       [X,FVAL,EXITFLAG] = fmincon(@(x) myfun(x), ones(N*nu,1),[],[],[],[],mpc{1}.LB,mpc{1}.UB,@(x) mycon(x));%,options);
       EXITFLAG
       if mycon(X)<=0
           CFeas = [CFeas model.x];
       end
   end
end

VbarFeas{1} = []
VbarFeas{2} = []
VbarFeas{3} = []
for ff  = 1:3
    Vbar = 10^ff;
    if ff==3
      Vbar = 500;
    end
    betaa = Vbar/a;
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

    mpc{2}.H = [cmpc{1}.H cmpc{1}.cu; cmpc{2}.cu cmpc{2}.H];
    mpc{2}.c = [cmpc{1}.cx;cmpc{2}.cx];
    mpc{2}.LB = [cmpc{1}.LB;cmpc{2}.LB];
    mpc{2}.UB = [cmpc{2}.UB;cmpc{2}.UB];
    for i1 = 1:length(Xgrid(1,:))
        for i2 = 1:length(Xgrid(2,:))
            model.x= [Xgrid(1,i1);Xgrid(2,i2)];
            [X,FVAL,EXITFLAG] = fmincon(@(x) myfun1(x), ones(N*nu,1),[],[],[],[],mpc{2}.LB,mpc{2}.UB);%,[],options);
            EXITFLAG
            FVAL = FVAL + 0.5*model.x'*phi'*QQ*phi*model.x;
            feas = length(find(X>=mpc{2}.UB))+length(find(X<=mpc{2}.LB));
            if FVAL <= Vbar & feas == 0
                VbarFeas{ff} = [VbarFeas{ff} model.x];
            end
        end
    end
end
VbarFeas{4}  = [];
for ff  = 4
    Vbar = 200;
    betaa = Vbar/a;
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

    mpc{2}.H = [cmpc{1}.H cmpc{1}.cu; cmpc{2}.cu cmpc{2}.H];
    mpc{2}.c = [cmpc{1}.cx;cmpc{2}.cx];
    mpc{2}.LB = [cmpc{1}.LB;cmpc{2}.LB];
    mpc{2}.UB = [cmpc{2}.UB;cmpc{2}.UB];
    for i1 = 1:length(Xgrid(1,:))
        for i2 = 1:length(Xgrid(2,:))
            model.x= [Xgrid(1,i1);Xgrid(2,i2)];
[X,FVAL,EXITFLAG] = fmincon(@(x) myfun1(x), ones(N*nu,1),[],[],[],[],mpc{2}.LB,mpc{2}.UB);%,[],options);
            EXITFLAG
            FVAL = FVAL + 0.5*model.x'*phi'*QQ*phi*model.x;
            feas = length(find(X>=mpc{2}.UB))+length(find(X<=mpc{2}.LB));
            if FVAL <= Vbar & feas == 0
                VbarFeas{ff} = [VbarFeas{ff} model.x];
            end
        end
    end
end
figure(1)
plot(CFeas(1,:),CFeas(2,:),'*')
hold on
plot(VbarFeas{1}(1,:),VbarFeas{1}(2,:),'rd')
figure(2)
plot(CFeas(1,:),CFeas(2,:),'*')
hold on
plot(VbarFeas{2}(1,:),VbarFeas{2}(2,:),'rd')
figure(3)
plot(CFeas(1,:),CFeas(2,:),'*')
hold on
plot(VbarFeas{3}(1,:),VbarFeas{3}(2,:),'rd')
plot(VbarFeas{4}(1,:),VbarFeas{4}(2,:),'go')


idx = convhulln(CFeas');
CFeas1 = CFeas'(idx);

for i = 1:4
  idx = convhulln(VFeas{i}');
  VFeas1{i} = VFeas{i}'(idx);
end

save -ascii CFeas.dat CFeas1
save -ascii VFeas10.dat VFeas1{1}
save -ascii VFeas100.dat VFeas1{2}
save -ascii VFeas500.dat VFeas1{3}
save -ascii VFeas200.dat VFeas1{4}







