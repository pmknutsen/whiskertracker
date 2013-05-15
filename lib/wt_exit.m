function wt_exit
% WT_EXIT
% Exit WT and clean up workspace.

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

wt_save_data('check1st')

% Close windows
delete(findobj('Tag', 'plotprefs'));
delete(findobj('Tag', 'WTMainWindow'));
delete(findobj('Tag', 'SignalNoiseFig'));
delete(findobj('Name', 'WT Plots'))

% Pack workspace
%cwd = pwd;
%cd(tempdir);
%pack;
%cd(cwd);

% Remove paths
%sPath = which('wt_init');
%sPath = sPath(1:findstr(sPath, 'wt_init.m')-1);
%rmpath(sPath);
%rmpath(sprintf('%sbin\\', sPath));

clear global g_tWT

return
