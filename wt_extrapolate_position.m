function mImgFilter = wt_extrapolate_position(mW0, mImg, mWA)
% WT_EXTRAPOLATE_POSITION
% Create an image-mask that will 'highlight' the likely position of the
% whisker in current frame, based on velocity information in previos
% frames.
%
%   1 - Linear interpolation of whisker shape in the X preceeding frames
%   2 - Select end-points and mid-point (half-way along the interpolated whisker)
%   3 - Filter trajectory of all three points
%   4 - Cubic extrapolation of new position
%   5 - Generate scaled gaussian filter
%   6 - Show debug window that contains: filtered velocity and extrapolated
%       position

% Whisker Tracker (WT)
%
% Authors: Per Magne Knutsen, Dori Derdikman
%
% (c) Copyright 2004 Yeda Research and Development Company Ltd.,
%     Rehovot, Israel
%
% This software is protected by copyright and patent law. Any unauthorized
% use, reproduction or distribution of this software or any part thereof
% is strictly forbidden. 
%
% Citation:
% Knutsen, Derdikman, Ahissar (2004), Tracking whisker and head movements
% of unrestrained, behaving rodents, J. Neurophys, 2004, 2005

global g_tWT

nX = 20; % use 10 frames back
bDebug = g_tWT.VerboseMode;

% Return immediately if fewer than X frames have already been processed
if length(find(mWA(2,1,:))) < nX + 1 % check tracked frames in 2nd X value
    mImgFilter = ones(size(mImg));
    return;
end

% Resize whisker-coordinates to fit image
mW0 = mW0;% * g_tWT.MovieInfo.ResizeFactor;
mWA = mWA;% * g_tWT.MovieInfo.ResizeFactor;

% Linear extrapolation of whisker shape in X preceeding frames
mXX = []; mYY = [];
for f = size(mWA, 3)-nX:size(mWA, 3)
    if isempty(find(mWA(:,1,f))), continue, end
    vX = mWA(find(mWA(:,1,f)),1,f);
    vY = mWA(find(mWA(:,1,f)),2,f);
    vXX = [vX(1) vX(1)+(vX(end)-vX(1))/2 vX(end)];
    mYY = [mYY; spline(vX(find(vX)), vY(find(vX)), vXX)];
    mXX = [mXX; vXX];
end

% Filter whisker trajectory
persistent A B;
nFilterOrder = 4;
if isempty(A)
    nFreq = 1/4;
    [B,A] = butter(nFilterOrder, nFreq);
end
if size(mYY, 1) > 3*nFilterOrder
    mYY = filtfilt(B, A, mYY);
end

% Cubic extrapolation of new position
vNewY = interp1(1:size(mYY,1), mYY, size(mYY,1)+1, 'cubic', 'extrap');
vNewXX = mXX(end,1):mXX(end,end);
[vXX, vNewYY] = wt_spline(mXX(end,:), vNewY, mXX(end,1):mXX(end,end));
[C,IA,IB] = intersect(round(mXX(end,:)), vNewXX);
vNewX = C;
vNewY = vNewYY(IB);

% Generate scales gaussian filter centered on whisker location, with spread
% scaled according to new whisker position limits.
vJit = g_tWT.MovieInfo.HorJitter;
vJit = [vJit(1) vJit(1)+vJit(2) vJit(1)+vJit(2)+vJit(3)];
[vXX, vNewYYUpLim] = wt_spline(vNewX, vNewY+vJit, vNewXX);
[vXX, vNewYYDownLim] = wt_spline(vNewX, vNewY-vJit, vNewXX);

mImgFilter = zeros(size(mImg));
nMaxHw = round(max(abs((vNewYY - vNewYYUpLim))) * g_tWT.MovieInfo.ExtrapFiltHw) + 10;
mImgFilter = wt_zeropad(mImgFilter, nMaxHw, 0); % zeropad image
nAlpha = 2; % used to characterize the gaussion ('sharpness')
for x = 1:length(vNewXX)
    nHw = abs((vNewYY(x) - vNewYYUpLim(x))) * g_tWT.MovieInfo.ExtrapFiltHw;
    vFG = gausswin(nHw*2+1, nAlpha)';
    vYIndx = (round(vNewYY(x)-nHw):round(vNewYY(x)+nHw)) + nMaxHw;
    vYIndx = vYIndx(find(vYIndx > 0));
    if length(vYIndx) == 1, break, end
    vFG = interp1(linspace(vYIndx(1),vYIndx(end),length(vFG)), vFG, vYIndx, 'nearest');
    if vNewXX(x) == size(mImg, 2), break;
    else, mImgFilter(vYIndx, vNewXX(x)) = vFG'; end
end
mImgFilter = mImgFilter(nMaxHw+1:(size(mImg,1)+nMaxHw), :); % remove zeropad
mImgFilter = mImgFilter / max(mImgFilter(:)); % normalize to max

% Debug
if bDebug
    hFig = findobj('Tag', 'EXTRAPOLATE_POSITION_WINDOW');
    if isempty(hFig)
        hFig = figure;
        set(hFig, 'Tag', 'EXTRAPOLATE_POSITION_WINDOW', 'DoubleBuffer', 'on', 'Name', 'WT - EXTRAPOLATE_POSITION_WINDOW', 'numbertitle', 'off')
    else, figure(hFig), end
    subplot(2,1,1);
    plot(mYY); hold on
    plot(repmat([size(mYY,1) size(mYY,1)+1],3,1)', [mYY(end,:); vNewY])
    plot(repmat(size(mYY,1),3,1), mYY(end,:)); grid on
    title('Extrapolation of new whisker location (Y axis)')
    subplot(2,2,3); title('Whisker and generated filter')
    plot(mXX(end,:), mYY(end,:), 'g'); hold on
    plot(vNewXX, vNewYY, 'b');
    plot(vNewX, vNewY, 'bo')
    plot(vNewXX, vNewYYUpLim, 'r')
    plot(vNewXX, vNewYYDownLim, 'r')
    grid on
    title('Whisker and limits')
    subplot(2,2,4)
    imagesc(mImgFilter.*mImg); hold on
    plot(mXX(end,:), mYY(end,:), 'g'); hold on
    plot(vNewXX, vNewYY, 'b');
    plot(vNewXX, vNewYYUpLim, 'r')
    plot(vNewXX, vNewYYDownLim, 'r')    
    title('Filter * Image')
    truesize; colormap gray
end


return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function w = gausswin(N, a)

% Index vector
k = -(N-1)/2:(N-1)/2;

% Equation 44a from [1]
w = exp((-1/2)*(a * k/(N/2)).^2)'; 

return;

