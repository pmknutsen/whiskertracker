function wt_save_data(varargin)
% WT_SAVE_DATA
% Save data of currently open movie.
%
% Usage:
%   wt_save_data(sOption)
%
%   where sOption cane be:
%   'defpath'  Request user for path to save data to ('Save as')
%   'check1st' Check content on disk. Save only if not same as in memory.
%
% If save file already exists, the function always first copies it to a
% backup file (.mbk) before replacing the existing file.
%

global g_tWT
if isempty(g_tWT), return, end
g_tMovieInfo = g_tWT.MovieInfo; % for backward compatibility

% Construct .mat filename to save data to, if it does not already exist
if ~isfield(g_tWT, 'DefaultSavePath'), return; end

if isempty(g_tWT.DefaultSavePath)
    vStrIndx = 1:findstr(g_tWT.MovieInfo.Filename, '.avi')-1;
    if isempty(vStrIndx)
        vStrIndx = 1:findstr(g_tWT.MovieInfo.Filename, '.bin')-1;
    end
    g_tWT.DefaultSavePath = sprintf('%s.mat', g_tWT.MovieInfo.Filename(vStrIndx));
end

% Check whether to save or not (compare with data on disk)
if isempty(varargin), varargin{1} = ''; end
if strcmp(varargin{1}, 'check1st')
    % If there is a '*' in the figure title, ask whether to save changes
    if ~isempty(strfind(get(g_tWT.WTWindow, 'Name'), '*'))
        switch questdlg('Do you wish to save changes?','WT','Yes','No','Yes')
            case 'No', return
            case 'Cancel', return
        end
    else
        return
    end
end

% Check that lengths of data vectors fit to the length of the movie (in
% case they were loaded from a previous movie)
try
    if size(g_tWT.MovieInfo.SplinePoints,3) > g_tWT.MovieInfo.NumFrames
        sAns = questdlg('The number of tracked frames exceeds the number of total frame in the movie! Did you load the datafile of another movie? Select Fix to remove redundant frames.', ...
            'Warning','Fix','Ignore','Cancel','Fix');
        switch sAns
            case 'Fix' % remove tracked frames that don't exist in current movie
                nSpl = size(g_tWT.MovieInfo.SplinePoints,3);
                nFrames = g_tWT.MovieInfo.NumFrames;
                g_tWT.MovieInfo.SplinePoints(:,:,(nFrames+1):nSpl,:) = [];
            case 'Cancel', return,
        end
    end
    if ...
            size(g_tWT.MovieInfo.Angle,1) > g_tWT.MovieInfo.NumFrames || ...
            size(g_tWT.MovieInfo.Intersect,1) > g_tWT.MovieInfo.NumFrames || ...
            size(g_tWT.MovieInfo.PositionOffset,1) > g_tWT.MovieInfo.NumFrames || ...
            size(g_tWT.MovieInfo.Curvature,1) > g_tWT.MovieInfo.NumFrames || ...
            size(g_tWT.MovieInfo.RightEye,1) > g_tWT.MovieInfo.NumFrames || ...
            size(g_tWT.MovieInfo.LeftEye,1) > g_tWT.MovieInfo.NumFrames || ...
            size(g_tWT.MovieInfo.Nose,1) > g_tWT.MovieInfo.NumFrames
        wt_error('The length of one or more vectors in g_tWT.MovieInfo (e.g. Angle, Curvature) is larger than the total number of frames in the movie. Did you load the datafile of another movie? To correct this problem, go to Organize Plots and re-calculate all measurements.')
    end
end

% Construct .mbk filename to backup data to, if file name ends in .mat
sDefaultBackupPath = [];
nPrefixName = findstr(g_tWT.DefaultSavePath, '.mat'); % check that user name ends with .mat
if ~isempty(nPrefixName)
    vStrIndx = 1:nPrefixName-1;  % user name ends with .mat
    sDefaultBackupPath = sprintf('%s.mbk', g_tWT.DefaultSavePath(vStrIndx));
end

if nargin==1
    if strcmp(varargin{1}, 'defpath')
        % Let user define file to save data to
        [sFilename, sFilepath] = uiputfile('*.mat', 'Select output file');
        if sFilename==0
            return
        end

        % User defines save name -- construct Backup File Name if possible
        g_tWT.DefaultSavePath = sprintf('%s%s', sFilepath, sFilename);
        sDefaultBackupPath = [];
        nPrefixName = findstr(g_tWT.DefaultSavePath, '.mat'); % check that user name ends with .mat
        if ~isempty(nPrefixName)
            vStrIndx = 1:nPrefixName-1;  % user name ends with .mat
            sDefaultBackupPath = sprintf('%s.mbk', g_tWT.DefaultSavePath(vStrIndx));
        end
    end
end

% PATCH - Sometimes Curvature is an empty cell and MatLab fails during
% save(). If Curvature is an empty cell, substitute with an empty matrix
% instead.
if isfield(g_tMovieInfo, 'Curvature')
    if isempty(g_tMovieInfo.Curvature)
        g_tMovieInfo.Curvature = [];
    end
end

% Save first video frame in .mat file
if isfield(g_tWT, 'CurrentFrameBuffer')
    if exist(g_tWT.MovieInfo.Filename, 'file')
        mFrame = wt_load_avi(g_tWT.MovieInfo.Filename, 1, 'none');
        g_tMovieInfo.FrameBuffer(1).Img = mFrame;
        g_tMovieInfo.FrameBuffer(1).Frame = 1;
    end
end

% Save data
try
    % Save .mat files
    % If the Save File already exists, first copy it to a Backup file (.mbk),
    % then save
    if exist(g_tWT.DefaultSavePath, 'file') && ~isempty(sDefaultBackupPath)
        copyfile(g_tWT.DefaultSavePath, sDefaultBackupPath, 'f');
    end

    if strcmp(version('-release'), '14')
        save(g_tWT.DefaultSavePath, 'g_tMovieInfo', '-v6'); % save in Matlab 6 format
    else
        save(g_tWT.DefaultSavePath, 'g_tMovieInfo')
    end

    % Compress .mat file (also deletes original)
    if g_tWT.CompressData
        % Delete old .gz file if it exists
        delete([g_tWT.DefaultSavePath '.gz']);
        sPath = which('wt_load_data');
        eval(sprintf('!%s\\bin\\gzip %s', sPath(1:(end-14)), g_tWT.DefaultSavePath))
    end

catch
    wt_error(lasterr)
end

return
