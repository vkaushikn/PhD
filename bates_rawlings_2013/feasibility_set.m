npts = 21;
x1 = linspace(0,1,npts)';
x2 = (1/4)*x1.^3;


x2disp = zeros(npts,1);
x2dism = x2disp;
for i = 1:npts
  a = -144;
  b = 160*x1(i)^3;
  c = -16*x1(i)^6;
    x2disp(i) = (-b + sqrt(b^2-4*a*c))/(2*a);
    x2dism(i) = (-b - sqrt(b^2-4*a*c))/(2*a);
endfor

X1set = [x1, x1.^3];
X1set = [flipud(X1set); -X1set];

X2set = [x1, x2; 0, x2(end)];
X2set = [X2set; -flipud(X2set)];

dis = [x1, x2disp, x2dism];
dis = [flipud(dis); -dis];

% double check
% a = 3; b=-3*x1; c=-3*x1.*x1; d=-(x1.^3)+4*x2dism;
% discriminant = 18*a*b.*c.*d - 4*b.^3.*d + b.^2.*c.^2 - 4*a.*c.^3 - 27*a.^2.*d.^2

plot(X2set(:,1), X2set(:,2), '-o', dis(:,1),dis(:,2), '-', \
     X1set(:,1), X1set(:,2))
axis ([-1,1,-0.25,0.25]);

save 'feasibility_set.dat' X2set X1set dis