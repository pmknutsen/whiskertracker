function wt_toggle_show_label_identity(nStatus)
% WT_TOGGLE_SHOW_IDENTITY
%

global g_tWT

% Toggle verbose status
if exist('nStatus'), g_tWT.ShowLabelIdentity = nStatus;
else g_tWT.ShowLabelIdentity = ~g_tWT.ShowLabelIdentity; end

% Update user-menu
switch g_tWT.ShowLabelIdentity
    case 0
        sStatus = 'off';        
        set(gcbo, 'checked', 'off')
    case 1
        sStatus = 'on';        
        set(gcbo, 'checked', 'on')
    otherwise
        g_tWT.ShowLabelIdentity = 0;
        sStatus = 'on';
        set(gcbo, 'checked', 'on')
end
set(findobj('Label', 'Show names next to labels'), 'checked', sStatus);

wt_display_frame

return
