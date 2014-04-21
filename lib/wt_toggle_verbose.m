function wt_toggle_verbose
% wt_toggle_verbose
% Toggle status indicator of the Debug menu item.
%

global g_tWT

% Toggle verbose status
g_tWT.VerboseMode = ~g_tWT.VerboseMode;

% Update user-menu
switch g_tWT.VerboseMode
    case 0
        sStatus = 'off';
        set(gcbo, 'checked', 'off')
    case 1
        sStatus = 'on';
        set(gcbo, 'checked', 'on')
    otherwise
        wt_error('Verbose mode status is undefined. Click continue to set verbose to OFF.')
        g_tWT.VerboseMode = 0;
        sStatus = 'off';
end
set(findobj('Label', 'Show debug window'), 'checked', sStatus);

return