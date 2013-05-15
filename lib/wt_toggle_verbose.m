function wt_toggle_verbose
% WT_TOGGLE_VERBOSE
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

% Toggle verbose status
g_tWT.VerboseMode = ~g_tWT.VerboseMode;

% Update user-menu
switch g_tWT.VerboseMode
    case 0
        sStatus = 'off';        
    case 1
        sStatus = 'on';        
    otherwise
        wt_error('Verbose mode status is undefined. Click continue to set verbose to OFF.')
        g_tWT.VerboseMode = 0;
        sStatus = 'off';
end
set(findobj('Label', 'Show debug window'), 'checked', sStatus);

return
