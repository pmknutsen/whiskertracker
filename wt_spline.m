function [vXX, vYY] = wt_spline(vX, vY, vXX)
% WT_SPLINE
% Create spline from splinepoints. This function encapsulated the Matlab
% spline(...) function and performs some additional error-checking on the
% input.
%
% Syntax: YY = wt_spline(X, Y, XX), where:
%           X are the x coordinates of known coordinates
%           Y are the y coordinates of known coordinates
%           XX are the x coordinates to be inter/extra-polatd
%           YY are the resultant y coordinates at XX
%
% This function can be run as a stand-alone, i.e. it does not depend on the
% WT GUI or its global variables.

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

% Error checking
%  - remove rows that contain only zeros
mSpl = [vX(:) vY(:)];
mSpl = unique(mSpl, 'rows');
vIndxNoneZero = find(~all(mSpl == 0, 2));
vX = mSpl(vIndxNoneZero,1);
vY = mSpl(vIndxNoneZero,2);

% Compute spline
vYY = spline(vX, vY, vXX);

return
