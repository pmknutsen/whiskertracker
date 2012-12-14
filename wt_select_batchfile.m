function wt_select_batchfile
% WT_SELECT_BATCH_FILE
% Load a list of files specified in a selected text file. Display list in
% File -> Movies. Useful for selecting many movies for batch processing.
%
% The list of files should be specified in a text file with one movie per
% line. Examples:
%
%   Windows:
%       g:\video\113\11-2-2003\1\c_movie1.avi
%       g:\video\113\11-2-2003\1\c_movie2.avi
%
%   Linux/Unix:
%       /media/disk/BS/movie1.avi
%       /media/disk/BS/movie1.avi
%

global g_tWT

% Request user for location of batchfile
[sFilename, sFilepath] = uigetfile({'*.txt','TEXT-files (*.txt)';'*.dat','DAT-files (*.dat)';'*.*','All files (*.*)'}, 'Select file');
    
sBatchfile = wt_check_path(sprintf('%s%s', sFilepath, sFilename));

% Return immediately if user cancels
if ~sFilename, return; end

% Load file contents
bFail = 0;
try
    sFiles = textread(sBatchfile, '%s');
catch, bFail = 1; end

% Check that filenames are valid
g_tWT.Movies = struct([]);
for p = 1:length(sFiles)
    sThisFile = wt_check_path(sFiles{p});
    if exist(sThisFile, 'file')
        g_tWT.Movies(size(g_tWT.Movies,2)+1).filename = sThisFile;
    else, bFail = 1; end
end

if bFail
    waitfor(warndlg('An error occurred when processing the selection file. One or more paths may be invalid, or lines were not properly formatted.', 'WT'))
end

% Re-initialize the gui
wt_prep_gui;

% Load movie and display first frame
wt_load_movie(1);

return


