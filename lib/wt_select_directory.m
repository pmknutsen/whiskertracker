function sMovies = wt_select_directory(sPath)
% WT_SELECT_DIRECTORY
% Select a directory on disk as the current directory to load AVI movies
% from. All AVI movies in this directory are listed in File -> Movies.
%

global g_tWT

if ~exist('sPath', 'var')
    if ~isempty(g_tWT.AccessedPaths), sCurrPath = g_tWT.AccessedPaths{1};
    else sCurrPath = '0'; end
    sPath = uigetdir(sCurrPath, 'Select movie directory');
end

if ~sPath, return, end

cd(sPath) % change path to last selected

% Return immediately if user cancels
if ~sPath, return; end

% Build list of AVI and BIN files
sFiles = dir(wt_check_path(sprintf('%s\\*.avi', sPath)));
sFiles = [sFiles; dir(wt_check_path(sprintf('%s\\*.bin', sPath)))];

% Build list of MAT files
sMATFiles = dir(wt_check_path(sprintf('%s\\*.mat', sPath)));

% Error if there are no movies in chosen directory
if isempty(sFiles) && isempty(sMATFiles) && isempty(sBINFiles)
    warndlg('No video files were found in the chosen directory.', 'No movies found')
    return
elseif ~isempty(sMATFiles)
    % Ask to load any MAT files when found (and check they are WT files)
    sAns = questdlg('Would you like to load MAT files in this directory as well?', 'Load MAT files', ...
        'Yes', 'No', 'Yes');
    switch sAns
        case 'Yes'
            % Iterate over available MAT files and check they are in WT format
            vIndx = [];
            for f = 1:length(sMATFiles)
               tTMP = load(wt_check_path(sprintf('%s\\%s', sPath, sMATFiles(f).name)));
               if isfield(tTMP, 'g_tMovieInfo')
                   vIndx = [vIndx f];
               end
            end
            sFiles = [sFiles; sMATFiles(vIndx)];
    end
end

g_tWT.Movies = struct([]);
for f = 1:size(sFiles, 1)
    g_tWT.Movies(f).filename = wt_check_path(sprintf('%s\\%s', sPath, sFiles(f).name));
end

% Push current directory into list of previouslly accessed paths
nMatch = strmatch(sPath,g_tWT.AccessedPaths);
if isempty(nMatch)
    if isempty(g_tWT.AccessedPaths)
        g_tWT.AccessedPaths{1} = sPath;
    else
        g_tWT.AccessedPaths = cat(2, {sPath}, g_tWT.AccessedPaths);
    end
    if length(g_tWT.AccessedPaths) > 4
        g_tWT.AccessedPaths = g_tWT.AccessedPaths(1:4);
    end
else
    % Move current path up in list if it has been accessed before
    sMatch = g_tWT.AccessedPaths{nMatch(1)};
    g_tWT.AccessedPaths(nMatch) = [];
    g_tWT.AccessedPaths = cat(2, {sMatch}, g_tWT.AccessedPaths);
end

% Re-initialize GUI
wt_prep_gui;

% Load and display first movie
wt_load_movie(1);

return
