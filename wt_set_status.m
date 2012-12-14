function wt_set_status(sString)
% WT_SET_STATUS
% Change content of status bar; 
%   ex. wt_set_status('status bar string')

global g_tWT

set(g_tWT.Handles.hStatusText, 'string', sString);
drawnow

return