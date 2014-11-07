%%%% WT_SET_LAST_FRAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function wt_set_last_frame
% Set Last Frame for all Whiskers defined so far 
% Must check for Cancel or eXit
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

global g_tWT

% default is current frame
L = inputdlg('Set last frame to track', 'Set last frame', 1, {num2str(get(g_tWT.Handles.hSlider, 'value'))} );

% Change last frame value unless user hit Cancel or eXit
if ~isempty(L)
    for nW = 1:size(g_tWT.MovieInfo.SplinePoints, 4)
        g_tWT.MovieInfo.LastFrame(nW) = str2num(char(L));
    end
end
