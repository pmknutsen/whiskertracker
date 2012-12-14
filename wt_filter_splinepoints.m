function vOut = wt_filter_splinepoints(vIn, nFs, nLoPass)
% WT_FILTER_SPLINEPOINTS
% Filter each splinepoint individually.
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

vOut = zeros(size(vIn));

[a,b] = butter(3, nLoPass / (nFs/2), 'low');
for s = 1:size(vIn, 1) % iterate over splinepoints
    for d = 1:2 % iterate over dimensions
        
        vData = vIn(s, d, :);
        vData = reshape(vData, size(vData, 3), 1);
        if length(find(diff(vData))) ~= 0
            vData(find(vData==0)) = NaN;
            vData = filtfilt(a, b, vData);
        end
        vOut(s, d, :) = vData;

    end
end

return;
