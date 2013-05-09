function wt_clear_whisker(vChWhiskers, vFrames)
% WT_CLEAR_WHISKER
% Delete all or parts of tracked data of selected whiskers, or delete all
% tracked whiskers.
%
% Syntax:   wt_clear_whisker(1)         Delete whisker with index 1
%           wt_clear_whisker([2 3])       Delete whiskers with indices 2 and 3
%           wt_clear_whisker('all')     Delete all whiskers
%           wt_clear_whisker(1, 50:80)  Delete frames 50 to 80 of whisker 1

global g_tWT

% Confirm, unless we're in batch mode
if ~g_tWT.BatchMode
    sBtn = questdlg('Do you really want to clear the selected whisker(s)?', 'Delete whisker', 'Yes', 'No', 'No' );
    if ~strcmp('Yes', sBtn), return; end
end

if isnumeric(vChWhiskers) && exist('vFrames', 'var') % Delete fragment of selected whisker
    vFrames(vFrames > size(g_tWT.MovieInfo.SplinePoints,3)) = [];
    try g_tWT.MovieInfo.SplinePoints(:,:,vFrames,vChWhiskers) = 0; end
    try g_tWT.MovieInfo.Angle(vFrames, vChWhiskers) = NaN; end
    try g_tWT.MovieInfo.Curvature(vFrames, vChWhiskers) = NaN; end
    try g_tWT.MovieInfo.PositionOffset(vFrames, vChWhiskers) = NaN; end
    try g_tWT.MovieInfo.Intersect(vFrames, :, vChWhiskers) = NaN; end
    % The following line ensures that the entire whisker is deleted below
    % if there are no tracked frames left
    if isempty(find(g_tWT.MovieInfo.SplinePoints(:,:,:,vChWhiskers), 1))
        g_tWT.MovieInfo.SplinePoints(:,:,:,vChWhiskers) = [];
    end
end

if isnumeric(vChWhiskers) && ~exist('vFrames', 'var') % Delete all frames of selected whisker
    try g_tWT.MovieInfo.SplinePoints(:,:,:,vChWhiskers) = []; end %#ok<*TRYNC>
    try g_tWT.MovieInfo.WhiskerLabels(vChWhiskers) = []; end
    try g_tWT.MovieInfo.Angle(:, vChWhiskers) = []; end
    try g_tWT.MovieInfo.Curvature(:, vChWhiskers) = []; end
    try g_tWT.MovieInfo.PositionOffset(:, vChWhiskers) = []; end
    try g_tWT.MovieInfo.Intersect(:, :, vChWhiskers) = []; end
    try g_tWT.MovieInfo.MidPointConstr(1:2, vChWhiskers) = []; end
    try g_tWT.MovieInfo.ObjectRadPos(vChWhiskers,:) = []; end
    try g_tWT.MovieInfo.WhiskerSide(vChWhiskers) = []; end
    try
        vKeepIndx = setdiff(1:length(g_tWT.MovieInfo.WhiskerIdentity), vChWhiskers);
        g_tWT.MovieInfo.WhiskerIdentity = {g_tWT.MovieInfo.WhiskerIdentity{vKeepIndx}};
    end
    try g_tWT.MovieInfo.LastFrame(vChWhiskers) = []; end
end

if strcmp(vChWhiskers, 'all') ... % delete all whiskers if this was selected
        || isempty(g_tWT.MovieInfo.SplinePoints) % OR if last whisker was deleted above
    g_tWT.MovieInfo.SplinePoints = [];
    g_tWT.MovieInfo.WhiskerLabels = {};
    g_tWT.MovieInfo.Angle = [];
    g_tWT.MovieInfo.Intersect = [];
    g_tWT.MovieInfo.PositionOffset = [];
    g_tWT.MovieInfo.Curvature = [];
    g_tWT.MovieInfo.ObjectRadPos = [];
    g_tWT.MovieInfo.WhiskerIdentity = {};
    g_tWT.MovieInfo.LastFrame = [];
end

% Clear all displayed whiskers
hChild = get(g_tWT.FrameAx,'Children');
cTags = get(hChild, 'Tag');
for c = 1:length(cTags)
    if strfind(cTags{c}, 'whisker'), delete(hChild(c)), end
    if strfind(cTags{c}, 'scatpt'), delete(hChild(c)), end
end

wt_display_frame % refresh frame

return
