function wt_run_script_help(varargin)
% WT_RUN_SCRIPT_HELP
% Select a WT script and display its help info in a new window
%

% Select script form default directory
sPath = which('wt');
sPath = checkfilename([sPath(1:end-4) 'scripts\']);
[sFile, sPath] = uigetfile('*.m', 'Pick an M-file', sPath);

if sFile == 0, return, end

sTxt = help([sPath sFile]);

if isempty(sTxt)
    sTxt = 'No help available for this script./'
end

hFig = figure;
set(hFig, 'menuBar', 'none', 'name', ['Help on ' sFile], 'numberTitle', 'off')
hEdit = uicontrol('Parent', hFig, 'Style', 'edit', 'String', sTxt, ...
    'units', 'normalized', 'position', [0 0 1 1], ...
    'backgroundcolor', 'w', 'max', 2, 'horizontalalignment', 'left');

return
