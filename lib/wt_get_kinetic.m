function [vK, mK] = wt_get_kinetic(vCoords, nLoPass, nFs, nPixelsPerMM)
% WT_GET_KINETIC
% Calculate kinetic energy of whisker. 'Stand-alone' function (i.e. GUI
% does not need to be invoked).
%
% Syntax: [vK, mK] = wt_get_kinetic(V, LOP, FS, PIXMM), where
%           V is a vector that contains minimum 2 points that define the
%           spline shape of the whisker, in the format [X Y]
%           LOP is the low-pass frequency to filter splinepoints
%           FS is the movie's sampling rate in frames/second
%           PIXMM is number of pixels per millimeter
%           vK is the whisker's cumuluative kinetic energy
%           mK is the whisker's kinetic energy distributed across the
%           whisker shaft with time.
%
% Notes:
%   1. Both horizontal and radial movements of the splinepoints are
%      low-pass filtered.
%   2. This function is a stand-alone function, i.e. it does not depend on
%      the WT GUI in any way.
%

hWaitBar = waitbar(0, 'Computing kinetic energy...');

% Constants (from Neimark et al, 2003)
nRho = 1.4; % mean density of all whiskers (mg/mm^3)
nRadiusBase = 0.1307; % mean radius at base (of all whiskers, mm)
nRadiusSlope = 0.0017; % slope of radius
nRes = 0.25; % resolution in pixel
nFrames = size(vCoords, 3);
nPlot = 0;

% Low-pass filter splinepoints
if ~isempty(nLoPass) & nLoPass < nFs
    vCoords = wt_filter_splinepoints(vCoords, nFs, nLoPass);
end

% Find whisker's shortest length in entire movie
vLen = [];
for f = 1:nFrames
    vX = vCoords(:, 1, f); vX = vX(find(vX>0));
    vY = vCoords(:, 2, f); vY = vY(find(vY>0));
    vXX = vX(1):nRes:vX(end);
    [vXX, vYY] = wt_spline(vX, vY, vXX);
    vLen(f) = sum(sqrt(diff(vXX).^2 + diff(vYY).^2));
end
nMinLen = min(vLen);
vLoc = 1:nMinLen;

mK = [];
vK = [];

% Iterate over frames
for f = 2:nFrames
    waitbar(f/nFrames, hWaitBar)
    %  - whisker shape in previous frame
    vX = vCoords(:, 1, f-1); vX = vX(find(vX>0));
    vY = vCoords(:, 2, f-1); vY = vY(find(vX>0));
    vXXprev = vX(1):nRes:vX(end); [vXX, vYYprev] = wt_spline(vX, vY, vXXprev);
    %  - whisker shape in current frame
    vX = vCoords(:, 1, f); vX = vX(find(vX>0));
    vY = vCoords(:, 2, f); vY = vY(find(vY>0));
    vXXcurr = vX(1):nRes:vX(end); [vXX, vYYcurr] = wt_spline(vX, vY, vXXcurr);

    %  - get the [X Y] location of each point along whisker
    %    note: tried with repmat(..) and it was slower...
    vLenPrev = cumsum(sqrt(diff(vXXprev).^2 + diff(vYYprev).^2));
    vLenCurr = cumsum(sqrt(diff(vXXcurr).^2 + diff(vYYcurr).^2));
    for nLoc  = vLoc
        [nMin, vIndxPrev(nLoc)] = min(abs(vLenPrev - nLoc));
        [nMin, vIndxCurr(nLoc)] = min(abs(vLenCurr - nLoc));
    end
    %[vMin, vIndxPrev2] = min(abs(repmat(vLenPrev', 1, size(vLoc, 2)) - repmat(vLoc, size(vLenPrev, 2), 1)));
    %[vMin, vIndxCurr2] = min(abs(repmat(vLenCurr', 1, size(vLoc, 2)) - repmat(vLoc, size(vLenCurr, 2), 1)));

    %  - compute [X Y] velocity for each point along whisker
    vXvel = (vXXcurr(vIndxCurr(2:end)) - vXXprev(vIndxPrev(2:end))) ./ nPixelsPerMM; % mm
    vYvel = (vYYcurr(vIndxCurr(2:end)) - vYYprev(vIndxPrev(2:end))) ./ nPixelsPerMM; % mm

    %  - compute angle of each individual segment/point
    vTheta = abs(atan2(diff(vYYcurr(vIndxCurr)), diff(vXXcurr(vIndxCurr))));

    %  - distance of each point along whisker
    vDistance = vLoc(2:end) ./ nPixelsPerMM; % mm
    vRadius = nRadiusBase - (nRadiusSlope .* vDistance); % hits zero width at 77 mm, which is fine...

    %  - compute the whisker's cumulative kinetic energy
    mK(f,:) = (1/2 * pi * nRho) .* ( (vXvel.^2 + vYvel.^2) .* vRadius.^2 .* vTheta .* diff(vXXcurr(vIndxCurr)) );
    vK(f) = (1/2 * pi * nRho) .* sum( (vXvel.^2 + vYvel.^2) .* vRadius.^2 .* vTheta .* diff(vXXcurr(vIndxCurr)) );

    % PLOT
    if nPlot
        clf;
        % - whisker position
        subplot(4,1,1); hold on; title(sprintf('Whisker position, Frame# %d', f))
        plot(vXXcurr, vYYcurr)
        plot(vXXprev, vYYprev, 'r')
        legend('Curr', 'Prev'); grid on; xlabel('X [pix]'), ylabel('Y [pix]')
        % - whisker excursion as a function of whisker segment
        subplot(4,1,2); hold on; title('Segment excursion')
        plot(vXvel)
        plot(vYvel, 'r')
        legend('Vx', 'Vy'); grid on; xlabel('Whisker segment [pix]'), ylabel('Excursion [mm]')
        % - whisker angle as a function of whisker segment
        subplot(4,1,3); hold on; title('Segment angle')
        plot(vTheta)
        grid on; xlabel('Whisker segment (pix)'), ylabel('Angle [rad]')
        % - whisker kinetic energy as a function of whisker segment
        subplot(4,1,4); hold on; title('Segment kinetic energy')
        plot(vK)
        grid on; xlabel('Whisker segment (pix)'), ylabel('Kinetic energy [joules]')
    end
    
end
close(hWaitBar)

vK = vK'; % Dori 

return;
