function wt_init_head_tracker(varargin)
% WT_INIT_HEAD_TRACKER
% Set a static position of the head. This position will be copied to all
% frames in the current movie.
% 
% Usage:
%   wt_init_head_tracker()
%   wt_init_head_tracker('static_head')
%

global g_tWT

nDisplayFrame = round(get(g_tWT.Handles.hSlider, 'Value')); % 1st slide
if ~isempty(g_tWT.MovieInfo.RightEye) && ~isempty(g_tWT.MovieInfo.SplinePoints)
    sBtn = questdlg('The head has already been tracked. Re-tracking head will delete all previous whisker tracking. Do you want to re-track the head?', 'Track head', 'Yes', 'No', 'No' );
    if strcmp('No', sBtn), return, end
end

% Clear previous head-coordinates
g_tWT.MovieInfo.SplinePoints = [];
g_tWT.MovieInfo.RightEye = [];
g_tWT.MovieInfo.LeftEye = [];
g_tWT.MovieInfo.Nose = [];
g_tWT.MovieInfo.EyeNoseAxLen = [];

% Get user input
wt_display_frame(nDisplayFrame) % display first frame in movie
bSuccess = wt_mark_eyes; % mark eyes
if (~bSuccess)
    return % user did not input eye information
end

% Allow user to select a static head position (e.g. to track whisker
% movements bilaterally in head-fixed or anesthetized rats)
if nargin > 0
    if strcmp(varargin{1}, 'static_head')
        
        % Duplicate marked head position across all frames
        vRows = find(~isnan(g_tWT.MovieInfo.RightEye(:,1)));
        g_tWT.MovieInfo.RightEye = repmat(g_tWT.MovieInfo.RightEye(vRows(1), :), g_tWT.MovieInfo.NumFrames, 1);
        g_tWT.MovieInfo.LeftEye = repmat(g_tWT.MovieInfo.LeftEye(vRows(1), :), g_tWT.MovieInfo.NumFrames, 1);
        g_tWT.MovieInfo.Nose = repmat(g_tWT.MovieInfo.Nose(vRows(1), :), g_tWT.MovieInfo.NumFrames, 1);

        % Default ROI
        g_tWT.MovieInfo.ImCropSize = round([g_tWT.MovieInfo.RadExt g_tWT.MovieInfo.EyeNoseAxLen+g_tWT.MovieInfo.HorExt*2]);
        
        % Refresh display
        wt_toggle_display_mode(1)
        wt_display_frame(get(g_tWT.Handles.hSlider, 'value'))
    end
else
    % Get filename without .avi suffix
    sFilename = g_tWT.MovieInfo.Filename(1:strfind(g_tWT.MovieInfo.Filename, '.avi')-1);
    bResult = wt_head_tracker(sFilename);
    if bResult
        wt_save_data % save new data
    else
        wt_load_movie(g_tWT.MovieInfo.Filename); % re-load old data
    end
end

return
