function wt_toggle_show_label_identity(nStatus)
% WT_TOGGLE_SHOW_IDENTITY
% Toggle status of show whisker identity
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
if exist('nStatus'), g_tWT.ShowWhiskerIdentity = nStatus;
else, g_tWT.ShowWhiskerIdentity = ~g_tWT.ShowWhiskerIdentity; end

% Update user-menu
switch g_tWT.ShowWhiskerIdentity
    case 0
        sStatus = 'off';        
    case 1
        sStatus = 'on';        
    otherwise
        g_tWT.ShowWhiskerIdentity = 0;
        sStatus = 'on';
end
set(findobj('Label', 'Show whisker identities'), 'checked', sStatus);

wt_display_frame

return
