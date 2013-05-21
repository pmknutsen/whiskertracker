function wt_load_movie(varargin)
% WT_LOAD_MOVIE
% Load new movie into WT. Run the WT GUI before executing this function.
%
% Syntax: wt_load_movie(N), where N can be:
%           0           Load next movie in File->Movies
%           -1          Load previous movie in File->Movies
%           1 and up    Load the Nth movie in File->Movies
%           string      Load movies represented by string, where string
%                       contains the full or relative path to the movie
%
% You can call this function from other applications by calling it with the
% string parameter (i.e. passing the filename as a string). In any case,
% the WT GUI must be running before doing this.
%

global g_tWT
persistent p_nCurrMov

% If we are in batch mode, then save changes by default. Ask otherwise.
bAsk = 1;
if isfield(g_tWT, 'BatchLock')
    if strcmpi(g_tWT.BatchLock, 'on')
        bAsk = 0;
    end
end
if g_tWT.BatchMode
    bAsk = 0;
end

if bAsk
    wt_save_data('check1st')
else
    wt_save_data;
end

% If a movie is currently loaded, check that its uncompressed is deleted (if it exists)
if isfield(g_tWT.MovieInfo, 'FilenameUncompressed')
    if ~isempty(g_tWT.MovieInfo.FilenameUncompressed)
        delete(g_tWT.MovieInfo.FilenameUncompressed);
    end
end

if isempty(varargin)
    return;
else
    if isnumeric(varargin{1})
        switch varargin{1}
            case 0 % load next
                if isempty(p_nCurrMov), p_nCurrMov = 1;
                else p_nCurrMov = p_nCurrMov + 1; end
                if p_nCurrMov > size(g_tWT.Movies, 2)
                    errordlg('The current movie is the last movie in the loading list', 'WT Error');
                    p_nCurrMov = p_nCurrMov - 1;
                    return
                end
                sFileName = g_tWT.Movies(p_nCurrMov).filename;
            case -1 % load previous
                if isempty(p_nCurrMov), p_nCurrMov = 1;
                else p_nCurrMov = p_nCurrMov - 1; end
                if p_nCurrMov < 1
                    errordlg('The current movie is the first movie in the loading list', 'WT Error');
                    p_nCurrMov = 1;
                    return
                end
                sFileName = g_tWT.Movies(p_nCurrMov).filename;
            otherwise % load N'th movie                
                p_nCurrMov = varargin{1};
                sFileName = g_tWT.Movies(p_nCurrMov).filename;
        end
    else
        % Load movie identified by a string
        sFileName = varargin{1};
        g_tWT.Movies = struct([]);
        g_tWT.Movies(1).filename = sFileName;
        p_nCurrMov = 1;
    end
end

% Load info from video file (if it exists), UNLESS user selected a .mat file
if ~strcmp(sFileName(end-3:end), '.mat')
    if exist(sFileName, 'file')
        tMovieInfo = struct([]);
        if exist('VideoReader')
            clInfo = VideoReader(sFileName);
        elseif exist('mmreader')
            clInfo = mmreader(sFileName);
        end
        if exist('clInfo')
            tMovieInfo(1).Filename = sFileName;
            tMovieInfo(1).NumFrames = clInfo.NumberOfFrames;
            tMovieInfo(1).FramesPerSecond = clInfo.FrameRate;
            tMovieInfo(1).Width = clInfo.Width;
            tMovieInfo(1).Height = clInfo.Height;
            tMovieInfo(1).ImageType = clInfo.VideoFormat;
        else
            tMovieInfo = aviinfo(sFileName);
        end
        g_tWT.MovieInfo = tMovieInfo;
    else
        wt_error(sprintf('Cannot read %s', wt_check_path(sFileName)));
    end
end

% Default tracking parameters
g_tWT.MovieInfo.Roi = [1 1 g_tWT.MovieInfo.Width-1 g_tWT.MovieInfo.Height-1];
g_tWT.MovieInfo.ImCropSize = [g_tWT.MovieInfo.Width g_tWT.MovieInfo.Height];
g_tWT.MovieInfo.FilenameUncompressed = [];
g_tWT.MovieInfo.Rot = 0;
g_tWT.MovieInfo.Flip = [0 0];
g_tWT.MovieInfo.Invert = 0;
g_tWT.MovieInfo.SplinePoints = [];
g_tWT.MovieInfo.WhiskerSide = [];
g_tWT.MovieInfo.Angle = [];
g_tWT.MovieInfo.PositionOffset = [];
g_tWT.MovieInfo.Intersect = [];
g_tWT.MovieInfo.AngleDelta = 0;
g_tWT.MovieInfo.HorJitter = [1 2 3];
g_tWT.MovieInfo.HorJitterSlow = [1 1 1];
g_tWT.MovieInfo.nHorAutoThresh = 100;
g_tWT.MovieInfo.RadJitter = 1;
g_tWT.MovieInfo.RefLine = [0 1; 0 2];
g_tWT.MovieInfo.ViewMag = 1;
g_tWT.MovieInfo.WhiskerWidth = 1;
g_tWT.MovieInfo.FilterLen = 11;
g_tWT.MovieInfo.UsePosExtrap = 0;
g_tWT.MovieInfo.WhiskerLabels = {};
g_tWT.MovieInfo.ExtrapFiltHw = 10;
g_tWT.MovieInfo.AverageFrames = [0 0];
g_tWT.MovieInfo.MidPointConstr = [];
g_tWT.MovieInfo.ScreenRefresh = 5;
g_tWT.MovieInfo.NoFramesToLoad = 100;
g_tWT.MovieInfo.RightEye = [];
g_tWT.MovieInfo.LeftEye = [];
g_tWT.MovieInfo.Nose = [];
g_tWT.MovieInfo.StimulusA = [];
g_tWT.MovieInfo.StimulusB = [];
g_tWT.MovieInfo.EyeNoseAxLen = [];
g_tWT.MovieInfo.RadExt = 150;
g_tWT.MovieInfo.HorExt = 50;
g_tWT.DisplayMode = 1;
g_tWT.HideImage = 0;
g_tWT.MovieInfo.ObjectRadPos = [];
g_tWT.MovieInfo.CalBarLength = [];
g_tWT.MovieInfo.CalibCoords = [0 0;0 0];
g_tWT.MovieInfo.LastFrame = [];
g_tWT.MovieInfo.WhiskerLength = [];
g_tWT.MovieInfo.BGFrameLowPass = 5;
g_tWT.DefaultSavePath = [];
g_tWT.PixelsPerMM = [];
g_tWT.ShowLabelIdentity = 0;

% If the user-selected file was a .mat file, then load that data
if strcmp(sFileName(end-3:end), '.mat') % is .mat
    if exist(sFileName, 'file') % and it exists...
        % Try to load
        tT = load(sFileName);
        if isfield(tT, 'g_tMovieInfo') % is a WT file
            % Replace all fields, one at a time
            csFields = fieldnames(tT.g_tMovieInfo);
            for c = 1:length(csFields)
                g_tWT.MovieInfo.(csFields{c}) = tT.g_tMovieInfo.(csFields{c});
            end
        else
            errordlg('The selected .mat file is not in a supported format', 'WT Error')
            return
        end
    end
end

% Reset the averaged frame
wt_subtract_bg_frame('reset');

% Load previously collected data
% If that fails (e.g. if there is none), then attempt to load the default
% parameters file (wt_default_parameteres)
try
    wt_load_data
catch
    try
        % Use local default parameters
        global g_tOptFields
        if ispc
            load('C:\wt_default_parameters.mat', 'g_tOptFields');
        elseif isunix
            load('~.wt_default_parameters', 'g_tOptFields');
        end
        wt_set_parameters('updatevars', size(fieldnames(g_tOptFields), 1))
    end
end

% Re-insert parameters from file info structure
if ~strcmp(sFileName(end-3:end), '.mat')
    g_tWT.MovieInfo.FramesPerSecond = tMovieInfo.FramesPerSecond;
    g_tWT.MovieInfo.NumFrames = tMovieInfo.NumFrames;
    g_tWT.MovieInfo.Width = tMovieInfo.Width;
    g_tWT.MovieInfo.Height = tMovieInfo.Height;
end

if ~isfield(g_tWT.MovieInfo, 'CalBarLength'), g_tWT.MovieInfo.CalBarLength = []; end
if ~isfield(g_tWT.MovieInfo, 'CalibCoords'), g_tWT.MovieInfo.CalibCoords = [0 0;0 0];    end
g_tWT.MovieInfo.FilenameUncompressed = [];

% Initialize image buffer
g_tWT.CurrentFrameBuffer.Img   = [];
g_tWT.CurrentFrameBuffer.Frame = 1;

% Display frame number 1, or the first frame where head-position is known
wt_prep_gui
if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen)
    vKnownFrames = find(~isnan(g_tWT.MovieInfo.Nose(:,1)));
    wt_display_frame(vKnownFrames(1));
else wt_display_frame(1), end

wt_autosize_window

% If notes exist for this movie, pop up the Notes window UNLESS we are in
% batch mode
if isfield(g_tWT.MovieInfo, 'Notes')
    tDBStack = dbstack;
    if ~any(strcmp({tDBStack.name}, 'wt_batch_redo'))
        if ~isempty(g_tWT.MovieInfo.Notes)
            wt_edit_notes
        end
    end
end

% If the WT Plots window is open, refresh it with new data
if ~isempty(findobj('name','WT Plots'))
    wt_graphs('refresh')
    wt_graphs('',1)
end

return
