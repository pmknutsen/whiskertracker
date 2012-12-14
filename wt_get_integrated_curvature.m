function vA = wt_get_curvature(mSplinePoints)
% WT_GET_INTEGRATED_CURVATURE
% Calculate whisker curvature. Function is 'stand-alone' and can be called
% without WT being currently invoked (it does not access any globals
% variables used by WT).
%
% Description: The integrated curvature measurement is the integrated
% difference between a straight line and the whisker shaft. Thus, if the
% whisker shaft is a perfectly straight line, then the integrated curvature
% equals zero.
%
% Syntax: wt_get_curvature(M), where
%           M is a 3D matrix that contains rows of [X Y] splinepoints
%           arranged in frames along the 3rd dimension.
%

nRMax = [];
for f = 1:size(mSplinePoints, 3)
    mSpl = mSplinePoints(:,:,f,1);
    mSpl = unique(mSpl, 'rows');
    vIndxNoneZero = find(~all(mSpl == 0, 2));
    vX = mSpl(vIndxNoneZero,1);
    vY = mSpl(vIndxNoneZero,2);
    if isempty(vX) | any(isnan(mSpl(:)))
        vA(f) = NaN;
        continue
    end

    vXX = vX(1):max(vX);
    [vXX, vYY] = wt_spline(vX, vY, vXX); % compute whisker spline
    if length(unique(vYY)) == 1 % if all Y values are the same, IC is zero
        vA(f) = 0;
    else
        % Compute the whisker's convex hull
        vK = convhull(vXX,vYY);
        % Compute area of the convex hull
        vA(f) = polyarea(vXX(vK),vYY(vK));
    end

end

return
