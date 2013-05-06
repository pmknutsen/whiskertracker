function wt_toggle_trigger_overlays(nStatus)
% WT_TOGGLE_TRIGGER_OVERLAYS

global g_tWT

hObj = findobj('Label', 'Show Overlays');

% Update user-menu
switch get(hObj, 'checked')
    case 'on'
        set(hObj, 'checked', 'off')
        g_tWT.TriggerOverlays = 0;
    case 'off'
        set(hObj, 'checked', 'on')
        g_tWT.TriggerOverlays = 1;
end

wt_display_frame

return
