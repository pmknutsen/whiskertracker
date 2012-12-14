function wt_set_default_reference_line
% WT_SET_DEFAULT_REFERENCE_LINE

global g_tWT

g_tWT.MovieInfo.RefLine = [0 1; 0 2];

% Plot reference line or move it
hObj = findobj(g_tWT.FrameAx, 'Tag', 'reference_line');
if ~isempty(hObj)
    delete(hObj);
end

% Refresh display
wt_display_frame

return
