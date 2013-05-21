function wt_set_status(sString)
% wt_set_status(S)
% Change content of status bar where S is the string to display.
%   ex. wt_set_status('status bar string')

global g_tWT

set(g_tWT.Handles.hStatusText, 'string', sString, 'ForegroundColor', 'red');
hTimer = timer('TimerFcn', @ReturnToBlack, 'StartDelay', 1, 'TasksToExecute', 1, ...
    'ExecutionMode', 'singleShot', 'tag', 'wt_status_update_timer');
start(hTimer)

drawnow

return

% return text color to black
function ReturnToBlack(varargin)
global g_tWT
set(g_tWT.Handles.hStatusText, 'ForegroundColor', 'black');
hTimer = timerfind('tag', 'wt_status_update_timer');
stop(hTimer)
delete(hTimer)
return