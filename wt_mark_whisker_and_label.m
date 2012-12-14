function wt_mark_whisker_and_label(nWhisker, sOption, nLabel)
% WT_MARK_WHISKER_AND_LABEL Mark both a new whisker and label. Whisker is
% placed by default in the upper left corner. This function is intended
% more for tracking a stand-along object, rather than a whisker. For
% example, it can be used as a shortcut to track the whisker follicle when
% its not needed to track the whisker shaft.

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
% of unrestrained, behaving rodents, J. Neurophys, 2004, 2005

global g_tWT

%%%%%% CREATE NEW WHISKER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

vX = [-50 -49 -48]; vY = [1 1 1]; % whisker coordinates

nFirstFrame = round(get(g_tWT.Handles.hSlider, 'Value'));

if isempty(g_tWT.MovieInfo.SplinePoints), nIndx = 1;
else, nIndx = size(g_tWT.MovieInfo.SplinePoints, 4) + 1; end

g_tWT.MovieInfo.SplinePoints(1:3, 1:2, nFirstFrame, nIndx) = [vX' vY'];
g_tWT.MovieInfo.Angle(nFirstFrame, nIndx) = 0;
g_tWT.MovieInfo.Intersect(nFirstFrame, 1:2, nIndx) = [0 0];
g_tWT.MovieInfo.MidPointConstr(1:2, nIndx) = [0 0]';
g_tWT.MovieInfo.WhiskerSide(nIndx) = 0;
g_tWT.MovieInfo.LastFrame(nIndx) = g_tWT.MovieInfo.NumFrames;

%%%%%%% CREATE NEW WHISKER LABEL %%%%%%%%%%%%%%%%%%%%%%%%%%

wt_set_status('Mark position of whisker label')
wt_track_whisker_label(nIndx, 'mark');

wt_set_status('Enter whisker identity (e.g. C3)')
wt_set_identity(nIndx); % set whisker identity
wt_set_status('')


return;

