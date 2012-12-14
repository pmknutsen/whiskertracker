function mB = wt_zeropad(mA, nI, nJ)
% WT_ZEROPAD(A, I, J) Zeropad matrix A with I rows and J columns
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

% Columns
mB = [zeros(size(mA,1),nJ) mA zeros(size(mA,1),nJ)];

% Rows
mB = [zeros(nI,size(mB,2)) ; mB ; zeros(nI,size(mB,2))];

return;