function sWhiskerId = wt_whisker_id(nW)
% Returns whisker Id string given number of whisker
% Whisker Identity is usually string like A2 or E4 or C3
% Whisker side is either 1 ('R') or 2 ('L')
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

% Create the WhiskerIdentity field if it does not already exist
if ~isfield(g_tWT.MovieInfo, 'WhiskerIdentity')
    nW = size(g_tWT.MovieInfo.SplinePoints, 4); % number of tracked whiskers
    g_tWT.MovieInfo.WhiskerIdentity = cell(1,nW);
end

persistent sWhiskerSide;
sWhiskerSide = ['R', 'L'];
try
    sWhiskerId = [char(g_tWT.MovieInfo.WhiskerIdentity{nW}), '(', sWhiskerSide(g_tWT.MovieInfo.WhiskerSide(nW)), ')'];
catch
    wt_error('There is an error in the g_tWT.MovieInfo.WhiskerIdentity vector')
end

return
