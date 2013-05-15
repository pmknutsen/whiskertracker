function wt_set_reference_line
% wt_set_reference_line
%

global g_tWT

axes(g_tWT.FrameAx)

% Get coordinates
[vX vY] = ginput(2);
g_tWT.MovieInfo.RefLine = sortrows([round(vX) round(vY)], 2);

% Delete old reference line objects in GUI
hObj = findobj(g_tWT.FrameAx, 'Tag', 'reference_line');
delete(hObj)

% Refresh display
wt_display_frame

return
