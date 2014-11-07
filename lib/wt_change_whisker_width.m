% WT_CHANGE_WHISKER_WIDTH
% Open dialog window and allow user to select width of displayed whiskers
% in pixels.
%

function wt_change_whisker_width

global g_tWT

sAns = inputdlg('Whisker width (pixels):', 'WT', 1, {num2str(g_tWT.WhiskerWidth)});

% Exceptions
if isempty(sAns), return; end
if g_tWT.WhiskerWidth < 1, g_tWT.WhiskerWidth = 1; end
if g_tWT.WhiskerWidth > 50, g_tWT.WhiskerWidth = 50; end

g_tWT.WhiskerWidth = str2num(sAns{1});

% Refresh display
wt_prep_gui
wt_display_frame

return;
