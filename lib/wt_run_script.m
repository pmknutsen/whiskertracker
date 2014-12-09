function wt_run_script(varargin)
% WT_RUN_SCRIPT
% Select a WT script from disk and run it.
%
% Usage:
%
%   wt_run_script()         [default]
%       Run a single script for the currently loaded movie only.
%
%   wt_run_script('batch')
%       Run a single script once for all movies in the current directory.
%       The current directory must already have been selected with File->
%       Open Directory.
%
%       This mode is evoked by selecting Options -> Scripts -> Run Batch
%       Script from the menu.
%
%       Note that this function when run in the default (single movie) mode
%       can also be repeated as a batch job by selecting Options -> Batch
%       Redo from the menu.
% 
%   wt_run_script(SCRIPT)
%       Run the script designated by the string SCRIPT. The script must
%       already exist in the ./scripts folder where WT is installed.
%

global g_tWT

% Get default path of ./scripts
sPath = which('wt');
sPath = checkfilename([sPath(1:end-4) 'scripts\']);

% If the function to be run was not specified as in input, select file
% manually
if isempty(varargin)
    [sFile, sPath] = uigetfile('*.m', 'Pick an M-file', sPath);
elseif strcmpi(varargin{1}, 'batch')
    % Run script as batch job

    % Get script file
    [sFile, sPath] = uigetfile('*.m', 'Pick an M-file', sPath);
    
    % Save script action in Batch Redo function
    wt_batch_redo(['wt_run_script(''' sFile ''')'])
    
    % Run Batch Redo function and exit
    wt_batch_redo('redo')
    return
else
    sFile = varargin{1};
end

% The remainder of this function runs if a script is run for a single movie

% Save action for later global Redo
wt_batch_redo(['wt_run_script(''' sFile ''')'])

if sFile == 0, return, end

sCurrDir = pwd;
cd(sPath)

wt_fix_data % fix data errors before running script
eval([sFile(1:end-2) '(g_tWT);'])

cd(sCurrDir)

return
