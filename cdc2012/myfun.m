
function f = myfun(x)
global mpc model;
         f = 0.5*(x'*mpc{1}.H*x+ 2*x'*mpc{1}.c*model.x);     
end