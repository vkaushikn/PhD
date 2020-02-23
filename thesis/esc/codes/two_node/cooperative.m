function [ cmpc ] = cooperative( mpc, subsystem)
%cooperative: Makes the matrices for the cooperative MPC problem
eps1 = mpc.eps;
H = mpc.H; qR_c = mpc.qR_c; qR_x = mpc.qR_x; qR_d = mpc.qR_d;
qE = mpc.qE;
LB = mpc.LB; UB = mpc.UB;
Ain = mpc.Ain;
bin_c = mpc.bin_c; bin_x = mpc.bin_x; bin_d = mpc.bin_d;
M = length(subsystem);
nx = mpc.nx; nd = mpc.nd; nu = mpc.nu; N = mpc.N;
for ss = 1:M  
    uloc = subsystem{ss}.uloc; nu1 = length(subsystem{ss}.uloc);
    locvec = repmat([nu.*[0:N-1]]',[1 nu1])+repmat(uloc,[N 1]);
    locvec = locvec'; locvec = locvec(:);

    cmpc{ss}.LB = LB(locvec);
    cmpc{ss}.UB = UB(locvec);
    cmpc{ss}.Ain = Ain(:,locvec);
    cmpc{ss}.bin_x = bin_x;
    cmpc{ss}.bin_d = bin_d;
    cmpc{ss}.bin_c = bin_c;
    cmpc{ss}.nu = nu1;
    cmpc{ss}.uloc = locvec;
    %make the H matrix
    all = 1:N*nu;    all(locvec) = 0;  ot = find(all);
    cmpc{ss}.ot = ot;
    cmpc{ss}.bin_u = Ain(:,ot);
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
    %make the q vectors
    cmpc{ss}.qR_x = qR_x(locvec,:);
    cmpc{ss}.qR_d = qR_d(locvec,:);
    cmpc{ss}.qE = qE(locvec,:);
    cmpc{ss}.qR_c = qR_c(locvec,:);
end %for ss = 1:M
end