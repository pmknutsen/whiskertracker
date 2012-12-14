function vWhiskAngRel = wt_get_angle(vCoords, vRefLine, mObj)
% WT_GET_REACTION_ANGLE
% Calculate the whisker-object reaction angle, relative to reference line.
% Function is 'stand-alone' and can be called without WT being currently
% invoked.
%
% Syntax: wt_get_reaction_angle(V, RL, OBJ), where
%           V is a vector that contains minimum 2 points that define the
%           spline shape of the whisker, in the format [X Y]
%           RL are two points that define the trajectory of the reference
%           line, in the format [X1 Y1;X2 Y2]
%           OBJ is a matrix containing coordinates of touch locations in
%           the format [X Y FRAME]
%
%
% Whisker Tracker (WT)
%
% Authors: Per Magne Knutsen, Dori Derdikman
%
% (c) Copyright 2004 Yeda Research and Development Company Ltd.,
%     Rehovot, Israel
%
% This software is protected by copyright and patent law. Any unauthorized
% use, reproduction or distribution of this software or any part thereof
% is strictly forbidden. 
%
% Citation:
% Knutsen, Derdikman, Ahissar (2004), Tracking whisker and head movements
% of unrestrained, behaving rodents, J. Neurophys, 2004
%

% Get angle of the reference line
nRefAngle = rad2deg( atan2( diff([vRefLine(1,2) vRefLine(2,2)]), diff([vRefLine(1,1) vRefLine(2,1)])));
if nRefAngle<0, nRefAngle = 90+(90-abs(nRefAngle)); end

nFrames = size(vCoords, 3);

% For now, assume there is only one touch location
vObj = mObj(1,1:2); % [X Y]

for f = 1:nFrames
    % Get relevant spline-points
    mSpl = vCoords(:, :, f, 1);
    mSpl = unique(mSpl, 'rows');
    vIndxNoneZero = find(~all(mSpl == 0, 2));
    vX = mSpl(vIndxNoneZero,1);
    vY = mSpl(vIndxNoneZero,2);
    
    if isempty(vX)
        vWhiskAngRel(f) = NaN;
        continue;
    end
    
    % If the object is more radial than the whisker tip, then fill in the
    % reaction angle in this frame with a NaN
    if vObj(1) > max(vX)
        vWhiskAngRel(f) = NaN;
    else        
        % Compute the spline only for the pixel where the object is, and the
        % pixel inwards towards the whisker pad
        vXX = vX(1):vX(end);
        vXX = [ceil(vObj(1))-1 ceil(vObj(1))];
        vYY = spline(vX, vY, vXX); % note, we don't do extrapolation anymore
        % Compute angle between these two pixels
        nAng = rad2deg(atan2(diff(vYY), diff(vXX)));
        vWhiskAngRel(f) = nRefAngle + nAng;
    end
end

return
