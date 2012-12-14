function wt_toggle_display_mode(nStatus)
% WT_TOGGLE_DISPLAY_MODE

global g_tWT

% Check if head-movements are at all tracked in this video. If not, return.
if isempty(g_tWT.MovieInfo.EyeNoseAxLen), return; end

% Toggle verbose status
if exist('nStatus'), g_tWT.DisplayMode = nStatus;
else g_tWT.DisplayMode = ~g_tWT.DisplayMode; end

% Update user-menu
switch g_tWT.DisplayMode
    case 0
        sStatus = 'on';        
    case 1
        sStatus = 'off';        
    otherwise
        wt_error('Display mode status is undefined. Click continue to set verbose to OFF.')
        g_tWT.DisplayMode = 0;
        sStatus = 'on';
end
set(findobj('Label', 'Toggle viewing mode'), 'checked', sStatus);

wt_prep_gui
wt_display_frame

return
