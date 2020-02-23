function [ Xf,tstar,fd, isemptypoly] = findXf( model,penalty,constraint,mode )
% finds the terminal region for the supply chain system
%if nargin == 3
%    mode = 1;
%end;
b = penalty.Q*(model.x_ss-model.x_s);
c = model.x_ss'*penalty.Q*(model.x_ss-model.x_s);
%c = model.x_ss'*penalty.Q*model.x_ss-model.x_s'*penalty.Q*model.x_s;
U = [eye(model.nu);-eye(model.nu)]*model.K;
u = [constraint.uub;-constraint.ulb]-[model.u_ss;-model.u_ss];
X = [eye(model.nx);-eye(model.nx)];
%constraint.xlb(4) = -100;
x = [constraint.xub;-constraint.xlb]-[model.x_ss;-model.x_ss];
c = c-b'*model.x_ss;
if mode == 1
 constraint.X = [U;X;b'];
 constraint.x = [u;x;c];
 %constraint.X = [U;b'];
 %constraint.x = [u;c];
else
 constraint.X = [U;X];
 constraint.x = [u;x];
end
constraint.PX = polytope(constraint.X,constraint.x);
% xD^+=A_KxD regulates xD to  origin (dD = 0)
%PX is a polytope that satisfies u  = uD+uS = KxD+us in in the input
%constraint set
%[Xf,tstar,fd,isemptypoly] = mpt_infset(model.A_K,constraint.PX,1000);
id = find(constraint.x<0);
for i =1:length(id)
    if abs(constraint.x(id)) < sqrt(1e-16)
        constraint.x(id) = 1e-15;
    end
end
makachoot = 1;
isemptypoly = 0;
if constraint.TE ~= 1
%[tstar A B ] = Oinf(model.A_K,[eye(model.nx)],constraint.X,constraint.x);
[Xf,tstar,fd,isemptypoly] = mpt_infset(model.A_K,constraint.PX,1000);
if isemptypoly == 0
 [A B] = double(Xf);
 makachoot = 0;
else
  display('Equality constraint')
  maakachoot = 1;
end
end
fd = 0;  tstar = 1;

%Equality constraint
if constraint.TE == 1
    A = [eye(model.nx);-eye(model.nx)];
    B = 1e-5*ones(2*model.nx,1);
end



if makachoot == 1
   A = [eye(model.nx);-eye(model.nx)];
   B = 1e-5*ones(2*model.nx,1); 
end
Xf = polytope(A,B);    
