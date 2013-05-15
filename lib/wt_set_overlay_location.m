function wt_set_overlay_location()
% WT_SET_OVERLAY_LOCATION

global g_tWT

% Ask for location of overlays
hFig = figure('visible', 'off');
set(hFig, 'units', 'pixels', 'position', [1 1 200 200], 'menuBar', 'none', 'numberTitle', 'off', 'name', 'Overlay Location')
centerfig(hFig)
set(hFig, 'visible', 'on')

% Toggle buttons
uicontrol('style', 'pushbutton', 'string', 'Upper Left', 'position', [0 100 100 100], ...
    'callback', 'set(gcf,''visible'',''off'',''tag'',''UpperLeft'')');
uicontrol('style', 'pushbutton', 'string', 'Upper Right', 'position', [100 100 100 100], ...
    'callback', 'set(gcf,''visible'',''off'',''tag'',''UpperRight'')');
uicontrol('style', 'pushbutton', 'string', 'Lower Left', 'position', [0 0 100 100], ...
    'callback', 'set(gcf,''visible'',''off'',''tag'',''LowerLeft'')');
uicontrol('style', 'pushbutton', 'string', 'Lower Right', 'position', [100 0 100 100], ...
    'callback', 'set(gcf,''visible'',''off'',''tag'',''LowerRight'')');

% Wait for user to click a button
waitfor(hFig, 'visible');
g_tWT.OverlayLocation = get(hFig, 'tag');
close(hFig)
wt_display_frame

return
