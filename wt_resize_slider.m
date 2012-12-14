function wt_resize_slider

global g_tWT

if ~isfield(g_tWT.Handles, 'hSlider'), return, end
if isempty(g_tWT.Handles.hSlider), return, end

% Resize slider
set(g_tWT.Handles.hSlider, 'units', 'normalized' ...
    , 'Position', [.05 .025 .83 .03] ... % fig opos = .05 .05 .9 .9
    , 'Style', 'slider' ...
    , 'Min', 1 ...
    , 'CallBack', [ 'global g_tWT; set(g_tWT.Handles.hSlider, ''Value'', round(get(g_tWT.Handles.hSlider, ''Value''))); wt_display_frame(get(g_tWT.Handles.hSlider, ''Value''))' ] );
% Slider height is fixed in pixels
set(g_tWT.Handles.hSlider, 'units', 'pixels');
vPos = get(g_tWT.Handles.hSlider, 'position');
set(g_tWT.Handles.hSlider, 'Position', [vPos(1) 20 vPos(3) 17]);

% 'Go to frame' push-button
if isfield(g_tWT.Handles, 'hGoToButton')
    if ishandle(g_tWT.Handles.hGoToButton)
        set(g_tWT.Handles.hGoToButton, 'units', 'normalized', 'Position', [.88 .025 .07 .03] );
        % Fix height in pixels
        set(g_tWT.Handles.hGoToButton, 'units', 'pixels');
        vPos = get(g_tWT.Handles.hGoToButton, 'position');
        set(g_tWT.Handles.hGoToButton, 'Position', [vPos(1) 20 vPos(3) 17]);
    end
end

% 'Go to last tracked frame' push button
if isfield(g_tWT.Handles, 'hGoToEndButton')
    if ishandle(g_tWT.Handles.hGoToEndButton)
        set(g_tWT.Handles.hGoToEndButton, 'units', 'normalized', 'Position', [.95 .025 .03 .03] );
        % Fix button height in pixels
        set(g_tWT.Handles.hGoToEndButton, 'units', 'pixels');
        vPos = get(g_tWT.Handles.hGoToEndButton, 'position');
        set(g_tWT.Handles.hGoToEndButton, 'Position', [vPos(1) 20 vPos(3) 17]);
    end
end

% 'Go to first tracked frame' push button
if isfield(g_tWT.Handles, 'hGoToFirstButton')
    if ishandle(g_tWT.Handles.hGoToFirstButton)
        set(g_tWT.Handles.hGoToFirstButton, 'units', 'normalized', 'Position', [.02 .025 .03 .03]);
        % Fix button height in pixels
        set(g_tWT.Handles.hGoToFirstButton, 'units', 'pixels');
        vPos = get(g_tWT.Handles.hGoToFirstButton, 'position');
        set(g_tWT.Handles.hGoToFirstButton, 'Position', [vPos(1) 20 vPos(3) 17]);
    end
end

% Status text field below slider
if isfield(g_tWT.Handles, 'hStatusText')
    if ishandle(g_tWT.Handles.hStatusText)
        set(g_tWT.Handles.hStatusText, 'units', 'normalized', 'Position', [.02 .005 .96 .02]);
        % Fix height in pixels
        set(g_tWT.Handles.hStatusText, 'units', 'pixels');
        vPos = get(g_tWT.Handles.hStatusText, 'position');
        set(g_tWT.Handles.hStatusText, 'Position', [vPos(1) 2 vPos(3) 15]);
    end
end

return