
function [c,ceq] = mycon(x)
global mpc model penalty;
         c = 1/2*(x'*mpc{1}.B'*penalty.P*mpc{1}.B*x +2*x'*mpc{1}.B'*penalty.P*mpc{1}.A*model.x + model.x'*mpc{1}.A'*penalty.P*mpc{1}.A*model.x) - (mpc{1}.a);
         ceq = [];
end