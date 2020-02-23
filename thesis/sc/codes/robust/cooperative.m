function [ cmpc ] = cooperative( mpc, subsystem)
%cooperative: Makes the matrices for the cooperative MPC problem
eps1 = mpc.eps;
H = mpc.H; q = mpc.q;
LB = mpc.LB; UB = mpc.UB;
M = length(subsystem);
nx = mpc.nx; nu = mpc.nu; N = mpc.N;
for ss = 1:M  
    uloc = subsystem{ss}.uloc; nu1 = length(subsystem{ss}.uloc);
    locvec = repmat([nu.*[0:N-1]]',[1 nu1])+repmat(uloc,[N 1]);
    locvec = locvec'; locvec = locvec(:);
    cmpc{ss}.LB = LB(locvec);
    cmpc{ss}.UB = UB(locvec);
    cmpc{ss}.nu = nu1;
    cmpc{ss}.uloc = locvec;
    %make the H matrix
    all = 1:N*nu;    all(locvec) = 0;  ot = find(all);
    cmpc{ss}.ot = ot;
    H1  = zeros(nu1);
    for i = 1:length(locvec)
      for j = 1:length(locvec)
	H1(i,j) = H(locvec(i),locvec(j));
      end
    end
    H2 = zeros(nu1,nu-nu1);
    for i = 1:length(locvec)
      for j = 1:length(ot)
	H2(i,j) = H(locvec(i),ot(j));
      end
    end
    cmpc{ss}.H = H1;
    cmpc{ss}.qR_u = H2;
    cmpc{ss}.q = q; %multiplies x
end 
end