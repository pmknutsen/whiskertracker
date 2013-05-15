function vVertAngle = wt_get_vertical_angle(mXY, nD, nC)
% WT_GET_VERTICAL_ANGLE Calculate vertical whisker angle.
% The vertical whisker angle is computed from the known distance between
% two labels attached to the whisker shaft.
%
% To use this function the whisker must have a minimum of two labels
% attached to it. The Eucledian distance between the two points must be
% known a priori. This distance can be provided either in units of
% millimeters or pixels. A unit of millimeters will be assumed if the movie
% has already been calibration, whereas a unit of pixels will be assumed if
% the movie has not been calibrated.
%
% Syntax: wt_get_vertical_angle(V, RL, N), where
%          V is a Fx2x2 matrix of [X Y] coordinates of two whisker
%           attached labels
%          D is the known Eucledian distance between labels
%          C is the pixels/mm calibration value (or, NaN)
%
% If C is NaN, the unit of D is assumed to be pixels. Is C is non-NaN, C is
% assumed to be in millimeters

if isempty(mXY)
    vVertAngle = [];
    return
end

% Compute vertical angle
nFrames = size(mXY, 1);
for f = 1:nFrames
    mXY_this = mXY(f, :, :);
    if isempty(mXY_this), continue, end
    
    % Eucledian distance between labels
    nE = sqrt(diff(mXY_this(1,1,:))^2 + diff(mXY_this(1,2,:))^2);
    
    % Convert distance to mm
    if ~isnan(nC)
        nE = nE / nC;
    end
    
    vVertAngle(f) = rad2deg( acos(nE/nD) );    
end

return



