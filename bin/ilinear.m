function F=ilinear(x,y,u)
%ILINEAR Linear Interpolation of a 1-D function.
%  F=ILINEAR(Y,XI) returns the value of the 1-D function Y at the
%  points XI using linear interpolation. length(F)=length(XI). XI is
%  an index into the vector Y. Y is the value of the function
%  evaluated uniformly on a interval. If Y is a matrix, then
%  the interpolation is performed for each column of Y in which
%  case F is length(XI)-by-size(Y,2).
%
%  If Y is of length N then XI must contain values between 1 and N.
%  The value NaN is returned if this is not the case.
%
%  F = ILINEAR(X,Y,XI) uses the vector X to specify the coordinates
%  of the underlying interval. X must be equally spaced and
%  monotonic. NaN's are returned for values of XI outside the
%  coordinates in X.
%
%  See also ICUBIC, INTERP1.

%  Clay M. Thompson 7-4-91
%  Copyright (c) 1984-1994 by The MathWorks, Inc.
%  $Revision: 1.4 $

if nargin==2,  % No X specified.
  u = y; y = x;
  % Check for vector problem.  If so, make everything a column vector.
  if min(size(y))==1, y = y(:); end
  [nrows,ncols] = size(y);

elseif nargin==3, % X specified.
  % Check for vector problem.  If so, make everything a column vector.
  if min(size(y))==1, y = y(:); end
  if min(size(x))==1, x = x(:); end
  [nrows,ncols] = size(y);
  % Scale and shift u to be indices into Y.
  if (min(size(x))~=1), error('X must be a vector.'); end
  [m,n] = size(x);
  if m ~= nrows,
    error('The length of X must match the number of rows of Y.');
  end
  u = 1 + (u-x(1))*((nrows-1)/(x(m)-x(1)));
 
else
  error('Wrong number of input arguments.');
end

if nrows<2, error('Y must have at least 2 rows.'); end

siz = size(u);
u = u(:); % Make sure u is a vector
u = u(:,ones(1,ncols)); % Expand u
[m,n] = size(u);

% Check for out of range values of u and set to 1
uout = find(u<1 | u>nrows);
if ~isempty(uout), u(uout) = 1; end

% Interpolation parameters
s = (u - floor(u));
u = floor(u);
d = (u==nrows); if any(d(:)), u(d) = u(d)-1; s(d) = s(d)+1; end

% Now interpolate.
s2 = s.*s; s3 = s.*s2; v = (0:n-1)*nrows;
ndx = u+v(ones(m,1),:);
F =  ( y(ndx).*(1-s) + y(ndx+1).*s );

% Now set out of range values to NaN.
if ~isempty(uout), F(uout) = NaN; end

if min(size(F))==1, F = reshape(F,siz); end