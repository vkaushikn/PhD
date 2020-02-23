% Algorithm 3.2 in Gilbert and Tan
% Kaushik and Pratik, 4/23/2009


function [tstar A B ] = Oinf(F,H,E,e1)
%Will find maximum admissable output set for x^+=Fx, y = Hx, Ey<e1
%Requires F to be Lyapunov Stable
%Requires E(0)-e1<0 All elements of e1 must be greater than or equal to 0


[p n] = size(H); 
[s p] = size(E);

%check that F is lyapunov stable
%%%WRITE ME

%check that all elements of e1 are positive
%%%%WRITE ME

A = [];
B = [];
t = 0;
LB = ones(n,1)*-inf;
UB = ones(n,1)*inf;
VARTYPE = [];
for i = 1:n
  VARTYPE = [VARTYPE 'C'];
endfor
SENSE = -1;
%PARAM.presol
FLAG = 0;
while(FLAG==0)
  A = [A;E*H*F^t];
  B = [B;e1];
  CTYPE = [];
  Jstar = 0;
  no_of_active_constraint = 0;
  for l = 1:length(B)
    CTYPE =[CTYPE 'U'];
  endfor 
  for i = 1:s
    C = [E(i,:)*H*F^(t+1)]';
    [XOPT, FMIN, STATUS, EXTRA] = glpk (C, A, B, LB, UB,CTYPE,VARTYPE, SENSE);
    STATUS;
    Jstar(i) = FMIN-e1(i);
    if Jstar(i)<=0 & STATUS == 180 %Problem has feasible solution
    %only if status is 180, otherwise, the solution is unbounded (beacuse of the
    %maximization) and we need more constraints to find the feasible solution
       no_of_active_constraint+=1; 
    endif
  endfor
  format long
  %Jstar
  if no_of_active_constraint == s
     FLAG = 1;
     tstar = t;
  else
     FLAG = 0;
     t+=1;
  endif
  if t>2000
    FLAG = 1;
    tstar = inf;
  endif
endwhile




  

