
function f = myfun1(x)
global mpc model;
         f = 0.5*(x'*mpc{2}.H*x+ 2*x'*mpc{2}.c*model.x);     
end