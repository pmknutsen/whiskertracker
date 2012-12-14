function varargout = plot_vertical_angle(sWT, varargin)
% Compute and plot vertical whisker angle.
% Also stores vertical angle in g_tWT.MovieInfo structure
%

global g_tWT

% Whisker IDs
cIDs = g_tWT.MovieInfo.WhiskerIdentity;
cStrings = {};
for ID = 1:length(cIDs)
    cStrings{end+1} = sprintf('Distance between labels on %s (mm):', cell2mat(cIDs{ID}));
end

% Get label distance from user variables (if its there)
nD_fixed = [];
if isfield(g_tWT.MovieInfo, 'tUserVariables')
    nIndx = find(strcmp({g_tWT.MovieInfo.tUserVariables.sVariable}, 'nLabelDist'));
    if ~isempty(nIndx)
        nD = str2num(g_tWT.MovieInfo.tUserVariables(nIndx).sValue);
    end
end

% Get distance between whisker labels from user
if isempty(nD_fixed)
    cAnswers = inputdlg(cStrings, 'WT', 1);
end

hFig = figure;

for w = 1:length(g_tWT.MovieInfo.WhiskerLabels)
    if isempty(nD_fixed)
        nD = str2num(cAnswers{w});
    else
        nD = nD_fixed;
    end
    
    if isfield(g_tWT.MovieInfo, 'PixelsPerMM')
        vVertAngle = wt_get_vertical_angle(g_tWT.MovieInfo.WhiskerLabels{1}, nD, g_tWT.MovieInfo.PixelsPerMM);
    else
        vVertAngle = wt_get_vertical_angle(g_tWT.MovieInfo.WhiskerLabels{1}, nD, 'NaN');
    end
    g_tWT.MovieInfo.VerticalAngle(:, w) = vVertAngle;

    % Plot vertical angle
    figure(hFig)
    subplot(length(g_tWT.MovieInfo.WhiskerLabels),1,w)
    plot(g_tWT.MovieInfo.VerticalAngle(:, w))
    xlabel('Time (samples)')
    ylabel('Angle (deg)')
    axis tight
end

% Link X axis on all subplots
linkaxes(get(hFig, 'children'), 'x');

hTit = title(g_tWT.MovieInfo.Filename);
set(hTit,'Interpreter','none','fontSize',8)

return
