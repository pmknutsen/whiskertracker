function vCurv = wt_get_curv_at_base(mSplinePoints)
% WT_GET_CURV_AT_BASE
% Calculate whisker curvature. Function is 'stand-alone' and can be called
% without WT being currently invoked (it does not access any globals
% variables used by WT).
%
% Syntax: wt_get_curvature(M), where
%           M is a 3D matrix that contains rows of [X Y] splinepoints
%           arranged in frames along the 3rd dimension.
%

if isempty(mSplinePoints)
    vCurv = [];
end

% Compute curvature analytically
for f = 1:size(mSplinePoints, 3)
    mSpl = mSplinePoints(:,:,f,1);
    if isempty(mSpl), continue, end
    if any(isnan(mSpl(:))), continue, end
    
    mSpl = unique(mSpl, 'rows');
    vIndxNoneZero = find(~all(mSpl == 0, 2));
    vX = mSpl(vIndxNoneZero,1);
    vY = mSpl(vIndxNoneZero,2);
    
    if length(vX) < 2
        vCurv(f) = NaN;
        continue
    elseif length(vX) == 2
        % if whisker is a line, curvature is always zero
        vCurv(f) = 0;
        continue
    end
    
    %if all(mSpl(end,:) == 0) % 4 splinepoints
    %    vX = mSpl(1:3,1);
    %    vY = mSpl(1:3,2);
    %else
    %    vX = mSpl(:,1);
    %    vY = mSpl(:,2);
    %end
    
    % downsample whisker to 3-point spline
    if size(mSpl, 2) > 3
        vXX = [min(vX) min(vX)+(max(vX)-min(vX))/2 max(vX)];
        vYY = spline(vX, vY, vXX);
        mSpl = [vXX', vYY'];
    end
    
    tmp = spline(vX,vY);
    B = tmp.coefs(1,end-2);
    C = tmp.coefs(1,end-1);
    vCurv(f) = (2*B) / ((1 + C^2)^1.5);
end
vCurv = vCurv * -1;

return

