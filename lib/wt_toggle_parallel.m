function wt_toggle_parallel
% WT_TOGGLE_PARELLEL
% Toggle on/off parellel processing mode from WT GUI.
%
%

global g_tWT

% Toggle verbose status
g_tWT.ParallelMode = ~g_tWT.ParallelMode;

% Update user-menu
switch g_tWT.ParallelMode
    case 0
        sStatus = 'off';        
        wt_set_status('Parallel processing turned off')
    case 1
        sStatus = 'on';        
        wt_set_status('Parallel processing turned on')
    otherwise
        wt_set_status('Parallel processing turned off')
        g_tWT.VerboseMode = 0;
        sStatus = 'off';
end
set(findobj('Label', 'Use Parallel Processing'), 'checked', sStatus);

return
