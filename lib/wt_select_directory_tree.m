function wt_select_directory_tree
% WT_SELECT_DIRECTORY_TREE
% Select all movies recursively from all sub-directories below a selected
% top-level directory.
%
% This function prompts the user to select a top-level directory and
% generates a list of all AVI movies, with complete paths, contained in the
% entire directory tree under the selected top-level directory.
%
% The list of retrieved movies can be accessed through the menu item Files
% -> Movies.
%

global g_tWT

% Select top-level directory
if ~isempty(g_tWT.AccessedPaths), sCurrPath = g_tWT.AccessedPaths{1};
else sCurrPath = '0'; end
sPath = uigetdir(sCurrPath, 'Select top-level directory of selection');

if ~sPath, return, end

cd(sPath) % change path to last selected

if ~all(sPath), return; end % cancel if no path was selected

% Iterate recursively over all sub-directories and extract paths of AVI
% movies
cSelection = GetFilePaths(sPath, '.avi');

% Display error and abort if no AVIs were found
if isempty(cSelection)
    warndlg('No AVI movies were found below the chosen directory', 'No movies found')
    return
end

% Reset current selection list
g_tWT.Movies = struct([]);

% Assign new selection to g_tWT
for f = 1:length(cSelection)
    g_tWT.Movies(f).filename = wt_check_path(cSelection{f});
end

% Re-initialize GUI
wt_prep_gui;

% Load and display first movie
wt_load_movie(1);


return



% --- Get paths of videos in a directory and its sub-directories
% Recursive search for .bin files from a selected directory
% inputs: sSuffix    Find files this file extension (e.g. '.avi')
%         sBaseDir   Base directory
function cPaths = GetFilePaths(sBaseDir, sSuffix)
cPaths = {};
tDirList = dir(sBaseDir);
for t1 = 3:length(tDirList)
    if tDirList(t1).isdir % depth = 1
        % recursively call this function
        sBaseDirRecurs = wt_check_path([sBaseDir '/' tDirList(t1).name]);
        cPaths2 = GetFilePaths(sBaseDirRecurs, sSuffix);
        cPaths = {cPaths{:}, cPaths2{:}};
    else
        % Add .bin files to paths cell
        if strcmp(tDirList(t1).name(end-3:end), sSuffix)
            sFilename = wt_check_path([sBaseDir '/' tDirList(t1).name]);
            cPaths{end+1} = sFilename;
        end
    end
end

