% WT_ROTATE_FRAME
%


function wt_rotate_frame( nDir )

global g_tWT

% Display warning message
if ~isfield(g_tWT.MovieInfo, 'SplinePoints'), return, end

if ~isempty(g_tWT.MovieInfo.SplinePoints)
    sQuestResp = questdlg('Changing the ROI will delete already marked whiskers. Continue?', 'Warning', 'Yes', 'No', 'Yes');
    if strcmp(sQuestResp, 'No') return; end
end

nAngles = [0 90 180 270];
nCurrPos = find(nAngles == g_tWT.MovieInfo.Rot);

% Determine new 'clock' position
if nDir == 0 % return to default
    g_tWT.MovieInfo.Rot = 0;
    g_tWT.MovieInfo.Roi = [1 1 g_tWT.MovieInfo.Width-1 g_tWT.MovieInfo.Height-1];% * g_tWT.MovieInfo.ResizeFactor;
else
    nNewPos = nCurrPos - nDir;
    switch nNewPos
        case 0
            g_tWT.MovieInfo.Rot = nAngles(4);
        case 5
            g_tWT.MovieInfo.Rot = nAngles(1);
        otherwise
            g_tWT.MovieInfo.Rot = nAngles(nNewPos);
    end
end

g_tWT.MovieInfo.SplinePoints = [];

% Refresh frame
wt_display_frame

return