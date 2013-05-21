function wt_set_status(sString)
% wt_set_status(S)
% Change content of status bar where S is the string to display.
%   ex. wt_set_status('status bar string')
%
% If the string contains the words 'warning' or 'error', the string is
% briefly highlighted in red.

global g_tWT

csRedWords = {'warning', 'error'};

set(g_tWT.Handles.hStatusText, 'string', sString, 'ForegroundColor', 'black');

for c = 1:length(csRedWords)
    if ~isempty(strfind(lower(sString), csRedWords{c}))
        set(g_tWT.Handles.hStatusText, 'ForegroundColor', 'red');
        hTimer = timer('TimerFcn', @ReturnToBlack, 'StartDelay', 1, 'TasksToExecute', 1, ...
            'ExecutionMode', 'singleShot', 'tag', 'wt_status_update_timer');
        start(hTimer)
    end
end

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