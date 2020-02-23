npts = 21;
x1vec = linspace(-1,1,npts)';
x2 = -0.1

roots = zeros(npts, 3);
w1 = 1;
w2 = (-1 + i*sqrt(3))/2;
w3 = (-1 - i*sqrt(3))/2;

for j = 1:npts
x1 = x1vec(j);
a = 3; b=-3*x1; c=-3*x1.*x1; d=-(x1.^3)+4*x2;


Delta0 = b^2-3*a*c;
Delta1 = 2*b^3 - 9*a*b*c + 27*a^2*d;
C = ((Delta1 + sqrt(Delta1^2 - 4*Delta0^3))/2)^(1/3);

u1 = - ( b + w1*C + Delta0/(w1*C) )/(3*a);
u2 = - ( b + w2*C + Delta0/(w2*C) )/(3*a);
u3 = - ( b + w3*C + Delta0/(w3*C) )/(3*a);
roots(j,:) = [u1, u2, u3];


endfor


% double check
% a = 3; b=-3*x1; c=-3*x1.*x1; d=-(x1.^3)+4*x2dism;
% discriminant = 18*a*b.*c.*d - 4*b.^3.*d + b.^2.*c.^2 - 4*a.*c.^3 - 27*a.^2.*d.^2

