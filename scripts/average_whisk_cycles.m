function varargout = average_whisk_cycles(sWT, varargin)
% Collect statistics for the mechanics analysis and export to Excel.
%
% INSTALLATION:
% To run this script, copy it to the ./scripts folder where WT has been
% installed (most likely, this has already been done for you). To run the
% script, select the menu item Options -> Scripts -> average_whisk_cycles.m
%
% PURPOSE:
% This script loads the whisker angle and curvature and averages whisking
% cycles based on a user-supplied whisking frequency. The script will
% extract periods corresponding to the whisk cycle-duration (starting from
% frame 1) and will average all such periods until the end of the video.
%
% HOW TO USE:
%
% 

% Error checking
% 1) Check that only 1 whisker has been marked
if size(sWT.MovieInfo.Angle,2) ~= 1 | ~isfield(sWT.MovieInfo, 'Curvature') | ~isfield(sWT.MovieInfo, 'Angle')
    return
end

% Get whisker frequency from user, unless specified in function input
if isempty(varargin)
    sAns = inputdlg('Whisking frequency (Hz)','Whisking frequency',1,{'5'});
    nFreq = str2num(sAns{1}); % whisking frequency (Hz)
else, nFreq = varargin{1}; end
nPeriod = sWT.MovieInfo.FramesPerSecond/nFreq; % whisk cycle duration (frames)

% Extract all whisk cycles
nFrames = size(sWT.MovieInfo.Angle, 1);
mAngle = [];
mCurvature = [];
for f1 = 1:nPeriod:nFrames
    if (f1+nPeriod) > nFrames, continue; else f2 = f1 + nPeriod - 1; end
    vRange = f1:f2;
    mAngle(:,end+1) = sWT.MovieInfo.Angle(vRange);
    mCurvature(:,end+1) = sWT.MovieInfo.Curvature(vRange);
end

hFig = figure;
set(hFig, 'Position', [383 210 537 705])
subplot(4,1,1)
plot(sWT.MovieInfo.Angle, 'k')
axis tight
ylabel('Angle'); xlabel('Frames')
title(sWT.MovieInfo.Filename)

subplot(4,1,2)
plot(sWT.MovieInfo.Curvature, 'k')
axis tight
ylabel('Curvature'); xlabel('Frames')

subplot(4,2,5)
plot(mAngle); axis tight
ylabel('Angle'); xlabel('Frames')

subplot(4,2,6)
plot(mCurvature); axis tight
ylabel('Curvature'); xlabel('Frames')

subplot(4,2,7)
plot(mean(mAngle')); axis tight
ylabel('Angle (average)'); xlabel('Frames')

subplot(4,2,8)
plot(mean(mCurvature')); axis tight
ylabel('Curvature (average)'); xlabel('Frames')

varargout{1} = mAngle;
varargout{2} = mCurvature;
varargout{3} = mean(mAngle');
varargout{4} = mean(mCurvature');
varargout{5} = sWT.MovieInfo.Filename;

return
