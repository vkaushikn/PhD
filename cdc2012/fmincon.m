## Copyright (C) 2007 John W. Eaton
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, write to the Free
## Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
## 02110-1301, USA.

## -*- texinfo -*-
## @deftypefn {Function File} {[@var{x}, @var{obj}, @var{info}]} fmincon (@var{f}, @var{x0}, @var{A}, @var{b}, @var{Aeq}, @var{beq}, @var{lb}, @var{ub} @var{confun}, @var{options})
## Minimize the function @var{f} starting from @var{x0}.
## @end deftypefn

## These are the meanings of info for Matlab's fmincon:
##
##  1: First-order optimality conditions were satisfied to the specified
##     tolerance.
##  2: Change in x was less than the specified tolerance.
##  3: Change in the objective function value was less than the
##     specified tolerance.
##  4: Magnitude of the search direction was less than the specified
##     tolerance and constraint violation was less than options.TolCon. 
##  5: Magnitude of directional derivative was less than the specified
##     tolerance and constraint violation was less than options.TolCon. 
##  0: Number of iterations exceeded options.MaxIter or number of
##     function evaluations exceeded options.FunEvals. 
## -1: Algorithm was terminated by the output function.
## -2: No feasible point was found.
##
## These are the meanings of info for Octave's sqp:
##
##   0: The problem is feasible and convex.  Global solution found.
##   1: The problem is not convex.  Local solution found.
##   2: The problem is not convex and unbounded.
##   3: Maximum number of iterations reached.
##   6: The problem is infeasible.
## 101: norm of last ste less than tol * norm (x)
## 102: BFGS update failed
## 103: iteration limit reached
##
## These are the meanings of info for NPSOL:
##
##  0: optimal solution found
##  1: weak local solution found
##  2: no feasible point for linear constraints and bounds
##  3: no feasible point found for nonlinear constraints
##  4: iteration limit reached
##  6: current point cannot be improved upon
##  7: user-supplied derivatives appear to be incorrect
##  9: internal error: invalid input parameter
##
## The match is not perfect, so we do the best we can.

function [x, obj, info] = fmincon (f, x0, A, b, Aeq, beq, lb, ub, cf, options)

  global __fmincon_A__;
  global __fmincon_b__;
  global __fmincon_Aeq__;
  global __fmincon_beq__;

  if (nargin == 2 || nargin == 4 || nargin == 6 || nargin == 8 || nargin == 9 || nargin == 10)

    nx = numel (x0);

    if (nargin < 4)
      A = zeros (0, nx);
      b = zeros (0, 1);
    endif

    if (nargin < 6)
      Aeq = zeros (0, nx);
      beq = zeros (0, 1);
    endif

    if (nargin < 8)
      lb = [];
      ub = [];
    endif

    ## We don't bother to check options for GradObj.  Just use the
    ## second element of f if it is provided.  Note also that we are not
    ## attempting to handle the case of a single function that returns
    ## both the objective and gradient.

    if (nargin > 8 && ! isempty (cf))
      error ("general nonlinear constraint function not handled yet");
    endif

    args = {x0, f};
    nargs = 2;

    have_linear_constraints = false;
    if (isempty (lb))
      if (isempty (ub))
	## do nothing
      else
	lb = -Inf * ones (nx, 1);
	have_linear_constraints = true;
      endif
    else
      if (isempty (ub))
	ub = Inf * ones (nx, 1);
	have_linear_constraints = true;
      else
	have_linear_constraints = true;
      endif
    endif

    if (isempty (getenv ("OCTAVE_FMINCON_USE_NPSOL")))

      if (isempty (A))
        __fmincon_A__ = [];
        __fmincon_b__ = [];
        h_arg = [];
      else
        __fmincon_A__ = A;
        __fmincon_b__ = b;
        h_arg = @hfun;
      endif

      if (isempty (Aeq))
        __fmincon_Aeq__ = [];
        __fmincon_beq__ = [];
        g_arg = [];
      else
        __fmincon_Aeq__ = Aeq;
        __fmincon_beq__ = beq;
        g_arg = @gfun;
      endif

      args = [args, {g_arg, h_arg}];

      if (have_linear_constraints)
	args = [args, {lb, ub}];
      endif

      [x, obj, sqp_info] = sqp (args{:});

      switch (sqp_info)
	case 0, info = 1;
	case 1, info = 2;
	case 2, -7;
	case 3, -8;
	case 6, -9;
	case 101, info = 2;
	case 102, info = -10;
	case 103, info = 0;
      endswitch
    else
      if (have_linear_constraints)
	args = [args, {lb, ub}];
      endif

      npsol_A = [A; Aeq];
      npsol_Alb = [-Inf*ones(nx,1); beq];
      npsol_Aub = [b; beq];
      if (! isempty (npsol_A))
	args = [args, {npsol_Alb, npsol_A, npsol_Aub}];
      endif

      [x, obj, npsol_info] = npsol (args{:});

      switch (npsol_info)
	case 0, info = 1;
	case 1, info = 2;
	case 2, info = -2;
	case 3, info = -2;
	case 4, info = 0;
	case 6, info = 2;
	case 7, info = -3;
	case 9, info = -4;
      endswitch
    endif
  else
    usage ("[x, obj, info] = retval = fmincon (f, x0, A, b, Aeq, b, lb, ub, confun, options)");
  endif

endfunction

function retval = gfun (x)
  global __fmincon_Aeq__;
  global __fmincon_beq__;
  retval = __fmincon_beq__ - __fmincon_Aeq__*x(:);
endfunction

function retval = hfun (x)
  global __fmincon_A__;
  global __fmincon_b__;
  retval = __fmincon_b__ - __fmincon_A__*x(:);
endfunction

%!function obj = phi (x)
%!  obj = (1-x(1))^2 + 100*(x(2)-x(1)^2)^2;
%!
%!function grd = grad (x)
%!  tmp = 200*(x(2)-x(1)^2);
%!  grd = [2*(x(1)-1)-2*x(1)*tmp; tmp];
%!
%!test
%! options = optimset ("GradObj", "on");
%! [x, fval] = fmincon ({@phi, @grad}, [1; 1], [], [], [], [], [2; 0], [10; 20], [], options);
%! assert (x, [2; 4]);
%! assert (fval, 1);
