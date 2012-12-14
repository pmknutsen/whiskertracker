function [vWhiskAngRel, vInters] = wt_get_angle(vCoords, vRefLine, nDelta)
% WT_GET_ANGLE
% Calculate whisker angle, relative to reference line, at N'th pixel along
% whisker length. Function is 'stand-alone' and can be called without WT
% being currently invoked (it does not access any globals variables used by
% WT).
%
% Syntax: wt_get_angle(V, RL, N), where
%           V is a vector that contains minimum 2 points that define the
%           spline shape of the whisker, in the format [X Y]
%           RL are two points that define the trajectory of the reference
%           line, in the format [X1 Y1;X2 Y2]
%           N is the Nth point along the whisker length where whisker angle
%           is calculated.
%
% Notes:
%   1 - If N=0 angle is solved analytically from the spline shape.

if isempty(vCoords)
    vWhiskAngRel = [];
    vInters = [];
    return
end

% Get angle of the reference line
nX = diff(vRefLine(:,1));
nY = diff(vRefLine(:,2));
if nX < 0 && nY > 0
    nRefAngle = abs(rad2deg( atan2( nY, nX))-180);
else
    nRefAngle = 90 + rad2deg( atan2( nX, nY));
end

%%% CALCULATE ANGLE
nFrames = size(vCoords, 3);
for f = 1:nFrames
    mSpl = vCoords(:, :, f, 1);
    if isempty(mSpl), continue, end
    
    mSpl = unique(mSpl, 'rows');
    
    vIndxNoneZero = find(~all(mSpl == 0, 2));
    vX = mSpl(vIndxNoneZero,1);
    vY = mSpl(vIndxNoneZero,2);
    
    if length(vX) < 2
        vWhiskAngRel(f) = NaN;
        continue
    end

    if nDelta == 0 % solve angle analytically
        tmp = spline(vX,vY);
        vWhiskAngRel(f) = nRefAngle + rad2deg(atan(tmp.coefs(1,end-1)));
    else
        vXX = vX(1):vX(3); % interpolate only the section we need below
        if nDelta > length(vXX), nD = length(vXX); else, nD = nDelta; end
        [vXX, vYY] = wt_spline(vX, vY, vXX);
        nRx = nD;
        nRy = vYY(nD)-vYY(1);
        nAng = rad2deg(atan(nRy/nRx));
        vWhiskAngRel(f) = nRefAngle + nAng;
    end
end

%%% CALCULATE INTERSECT
vInters = [ ...
    reshape(vCoords(1,1,:), size(vCoords,3), 1) ...
    reshape(vCoords(1,2,:), size(vCoords,3), 1) ];

return



