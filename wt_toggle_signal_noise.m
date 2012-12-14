function wt_toggle_signal_noise
% WT_TOGGLE_SIGNAL_NOISE
% Toggle the option whether the whisker tracking signal/noise window should
% be updated during tracking.
%
global g_tWT

% Toggle verbose status
g_tWT.ShowSR = ~g_tWT.ShowSR;

% Update user-menu
switch g_tWT.ShowSR
    case 0
        sStatus = 'off';        
    case 1
        sStatus = 'on';
        wt_plot_signal_noise([]);
    otherwise
        wt_error('Display mode status is undefined. Click continue to set verbose to OFF.')
        g_tWT.ShowSR = 0;
        sStatus = 'off';
end
set(findobj('Label', 'Show signal-to-noise...'), 'checked', sStatus);

return
