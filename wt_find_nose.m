% WT_FIND_NOSE Finds the nose in image, given eye positions.
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
% of unrestrained, behaving rodents, J. Neurophys, 2004, IN PRESS
%

function vNose = wt_find_nose(vRightEye, vLeftEye, nAxLen)

nMidPnt = [mean([vRightEye(:,1) vLeftEye(:,1)],2) mean([vRightEye(:,2) vLeftEye(:,2)],2)]; % eye midpoint
vRrelM = vRightEye - nMidPnt;
vAngRrelX = rad2deg(atan(vRrelM(:,2)./vRrelM(:,1)));
vAngNrelX = deg2rad(90 + vAngRrelX);
vNrelX = [nAxLen*cos(vAngNrelX) nAxLen*sin(vAngNrelX)];
vNose = nMidPnt + vNrelX;

return;
