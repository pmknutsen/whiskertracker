function sMovies = wt_select_file
% WT_SELECT_FILE
%

global g_tWT

[sFilename, sFilepath] = uigetfile({'*.avi', 'AVI-files (*.avi)'; '*.mat', 'MAT-files (*.mat)';'*.*', 'All File (*.*)'}, 'Select file');

% Return immeditaley if user cancelled this action
if ~sFilename return; end

% Build list of files
g_tWT.Movies = struct([]);
g_tWT.Movies(1).filename = sprintf('%s%s', sFilepath, sFilename);

% Change current directory to that of the loaded file
cd(sFilepath);

% Reinitialize the gui menus etc.
wt_prep_gui;

% Clear ROI and rotation parameters
g_tWT.MovieInfo.Roi = [];
g_tWT.MovieInfo.Rot = 0;

% Load movie and display first frame
wt_load_movie(1);

return;