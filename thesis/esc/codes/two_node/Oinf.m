function [tstar A B ] = Oinf(F,H,E,e1)
%Will find maximum admissable output set for x^+=Fx, y = Hx, Ey<e1
%Requires F to be Lyapunov Stable
%Requires E(0)-e1<0 All elements of e1 must be greater than or equal to 0
[p n] = size(H); 
[s p] = size(E);

%check that F is lyapunov stable
if (max(abs(eig(F))>1))
    error('F is not Lyapunov stable')
end %if max...

%check that all elements of e1 are positive
if (min(e1)<0)
    error('e1 should have all entries positive')
end %if min e1...

A = [];
B = [];
t = 0;
SENSE = -1;
%PARAM.presol
FLAG = 0;
while(FLAG==0)
  A = [A;E*H*F^t];
  B = [B;e1];
  CTYPE = [];
  Jstar = 0;
  no_of_active_constraint = 0;
  for i = 1:s
    C = [E(i,:)*H*F^(t+1)]';
    %keyboard
    [XOPT, FMIN, STATUS] = linprog(-C, A, B);
    Jstar(i) = FMIN-e1(i);
    if Jstar(i)<=1e-5 & STATUS == 1 %Problem has feasible solution
    %only if status is 180, otherwise, the solution is unbounded (beacuse of the
    %maximization) and we need more constraints to find the feasible solution
       no_of_active_constraint= no_of_active_constraint+1; 
    else
       i;
       e1(i);
       FMIN;
    end
  end%for
  format long
  %Jstar
  %[no_of_active_constraint s]
  if no_of_active_constraint == s
     FLAG = 1;
     tstar = t;
  else
     FLAG = 0;
     t=t+1;
  end%if
  if t>200
    FLAG = 1;
    tstar = inf;
  end%if
end%while

