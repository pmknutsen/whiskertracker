function import_vector_as_trigger(tWT)
% Import a Matlab variable as a trigger channel
%
% PURPOSE:
% WT by default supports two trigger channels, which are typically read
% directly from selected pixels in the video frames. This scripts allows
% you to import an existing Matlab variable as a trigger channel. The
% Matlab variable must be defined as a global variable, you need to provide
% its name and the framerate (Hz) at which is was recorded.
%
% This script assumes that the loaded vector and the video started at the
% same time.
%
% The vector will be loaded as trigger channel A.
%

global g_tWT % load global parameter

persistent sVarName nThisFs nThresh nOffset
if isempty(sVarName), sVarName = ''; end
if isempty(nThisFs), nThisFs = 40000; end
if isempty(nThresh), nThresh = 2; end
if isempty(nOffset), nOffset = 0; end

% Use last used parameters if we're running this script as a batch job
bAsk = 1;
if isfield(g_tWT, 'BatchLock')
    if strcmpi(g_tWT.BatchLock, 'on')
        bAsk = 0;
    end
end
if bAsk || isempty(sVarName)
    cAns = inputdlg({'Variable name (must be global)', 'Sample rate of vector (Hz)', 'Threshold', 'Offset (frames)'}, ...
        'Import trigger', 1, {sVarName num2str(nThisFs) num2str(nThresh) num2str(nOffset)});
    if isempty(cAns), return, end
    sVarName = cAns{1};
    nThisFs = str2double(cAns{2});
    nThresh = str2double(cAns{3});
    nOffset = str2double(cAns{4}); % frames
end

% Load global variable into variable vThisTrig
eval(sprintf('global %s;vThisTrig=%s;', sVarName, sVarName))

% Movie framerate
nFs = g_tWT.MovieInfo.FramesPerSecond;

% Resample imported variable to video frame rate
vNewTrig = decimate(vThisTrig, nThisFs/nFs);

% Threshold trigger
vThreshTrig = zeros(size(vNewTrig));
vThreshTrig(find(vNewTrig >= nThresh) + nOffset) = 1;

% Assign to Trigger A
g_tWT.MovieInfo.StimulusA = vThreshTrig;

return
