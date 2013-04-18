function [nScore, nScoreStd, nScoreN] = wt_find_next_whisker(nChWhisker, nCurrentFrame, nPreviousFrame, mImg, sSpeed)
% WT_FIND_NEXT_WHISKER
% Locate whisker in frame.
%
% Syntax: wt_find_next_whisker(W, F_curr, F_prev, IMG), where
%           W is the whisker ID/index to be tracked
%           F_curr is the current frame in which the whisker will be
%           located
%           F_prev is the previous frame
%           IMG is a copy of the frame/image
%

global g_tWT
persistent p_fQuadFun
if isempty(p_fQuadFun)
    p_fQuadFun = inline('1 - exp( -(x-b(1)).^2 / (2*b(2).^2) )', 'b', 'x');
end

% Construct the velocity matrix
%  - the velocity matrix attempts to extrapolate the new position of the
%    whisker from its current velocity
if g_tWT.MovieInfo.UsePosExtrap % Position extrapolation matrix
    mVelMat = wt_extrapolate_position(g_tWT.MovieInfo.SplinePoints(:,:,nPreviousFrame,nChWhisker), ...
        mImg, ...
        g_tWT.MovieInfo.SplinePoints(:, :, 1:nPreviousFrame, nChWhisker) );
    if g_tWT.VerboseMode
        hFig = findobj('Tag', 'EXTRAPOLATION_WINDOW');
        if isempty(hFig)
            hFig = figure;
            set(hFig, 'Tag', 'EXTRAPOLATION_WINDOW', 'DoubleBuffer', 'on', 'Name', 'WT - EXTRAPOLATION_WINDOW', 'numbertitle', 'off')
        else, figure(hFig), end
        colormap gray
        subplot(1,3,1); imagesc(mImg); title('Original')
        subplot(1,3,2); imagesc(mVelMat); title('VelocityMatrix')
        subplot(1,3,3); imagesc(mImg.*mVelMat); title('Original*VelocityMatrix')
    end
else, mVelMat = ones(size(mImg)); end

% DLL call
mCurrSpline = round(g_tWT.MovieInfo.SplinePoints(:, :, nPreviousFrame, nChWhisker));% * g_tWT.MovieInfo.ResizeFactor;
vRemRows = find(~sum(mCurrSpline'));
mCurrSpline(vRemRows,:) = []; % Remove [0 0] rows

% Check that the enumeration range is ok
if strcmp(sSpeed, 'fast'), mEnumRange = [0 g_tWT.MovieInfo.RadJitter 0; g_tWT.MovieInfo.HorJitter]';
else, mEnumRange = [0 g_tWT.MovieInfo.RadJitter 0; g_tWT.MovieInfo.HorJitterSlow]'; end
if size(mCurrSpline,1) == 4
    if mCurrSpline(4,1) == 0
        mCurrSpline(4,:) = [];
    else, mEnumRange = [mEnumRange(1,:);mEnumRange(2,:);mEnumRange(2,:);mEnumRange(3,:)]; end
end
[mNewSpline, nScore, nScoreStd, nScoreN] = find_next_whisker(mCurrSpline, mEnumRange, mImg, g_tWT.FiltVec, mVelMat );

% TEMPORARY PATCH
%  - when score==0, values returned by find_next_whisker may reach
%  extreme values. When this happens, keep values from last frame.
if nScore == 0
    if nCurrentFrame == 1
        g_tWT.MovieInfo.SplinePoints(:,:,nCurrentFrame,nChWhisker) = g_tWT.MovieInfo.SplinePoints(:,:,nCurrentFrame,nChWhisker);
    else
        g_tWT.MovieInfo.SplinePoints(:,:,nCurrentFrame,nChWhisker) = g_tWT.MovieInfo.SplinePoints(:,:,nCurrentFrame-1,nChWhisker);
    end
    wt_set_status('WARNING: Cannot discern whisker from background. Using coordinates of previous frame.')
else
    % OPTIONAL:
    % Improve tracking accuracy by interpolating position of
    % individual spline points to the exact location whisker center
    if 0
    nProfileRad = g_tWT.MovieInfo.WhiskerWidth * 2;
    for i = 1:size(mNewSpline, 1)
        vXY = round(mNewSpline(i, :));
        % Get profile of whisker shaft
        vX = (vXY(2)-nProfileRad):(vXY(2)+nProfileRad);
        vY = mImg(vX, vXY(1));
        vY = (vY-min(vY))/max(vY-min(vY));
        vXXi = linspace(min(vX), max(vX), 20);
        
        %vInitParms = [max(vY) vX(nProfileRad+1) g_tWT.MovieInfo.WhiskerWidth/2 min(vY)];
        vInitParms = [vX(nProfileRad+1) g_tWT.MovieInfo.WhiskerWidth/2];
        tOptions.MaxIter = 25;
        vB = nlinfit(vX(:), vY, p_fQuadFun, vInitParms, tOptions);
        vYYi = p_fQuadFun(vB, vXXi);
        [nMin nMinIndx] = min(vYYi);
        mNewSpline(i, :) = [vXY(1) vXXi(nMinIndx)];
    end
    end
    
    g_tWT.MovieInfo.SplinePoints(1:size(mNewSpline,1),:,nCurrentFrame,nChWhisker) = mNewSpline;% ./ g_tWT.MovieInfo.ResizeFactor;
end

% Add [0 0] rows removed earlier
if ~isempty(vRemRows)
    g_tWT.MovieInfo.SplinePoints(vRemRows, :, nCurrentFrame, nChWhisker) = zeros(length(vRemRows),2);
end

% Check whisker length
vX = g_tWT.MovieInfo.SplinePoints(:, 1, nCurrentFrame, nChWhisker);
vY = g_tWT.MovieInfo.SplinePoints(:, 2, nCurrentFrame, nChWhisker);
[vX vY] = wt_adjust_whisker_length(nChWhisker, vX, vY);
%g_tWT.MovieInfo.SplinePoints(1:size(vX,1), 1, nCurrentFrame, nChWhisker) = round(vX);
%g_tWT.MovieInfo.SplinePoints(1:size(vY,1), 2, nCurrentFrame, nChWhisker) = round(vY);
g_tWT.MovieInfo.SplinePoints(1:size(vX,1), 1, nCurrentFrame, nChWhisker) = vX;
g_tWT.MovieInfo.SplinePoints(1:size(vY,1), 2, nCurrentFrame, nChWhisker) = vY;

% Constrain mid-point
%  - user defined constraint
if sum(g_tWT.MovieInfo.MidPointConstr(:,nChWhisker)) ~= 0
    nMin = g_tWT.MovieInfo.MidPointConstr(1, nChWhisker);
    nMax = g_tWT.MovieInfo.MidPointConstr(2, nChWhisker);
    nMidPoint = g_tWT.MovieInfo.SplinePoints(2, 1, nCurrentFrame, nChWhisker);
    vX = g_tWT.MovieInfo.SplinePoints(:, 1, nCurrentFrame, nChWhisker);
    vY = g_tWT.MovieInfo.SplinePoints(:, 2, nCurrentFrame, nChWhisker);
    vXX = vX(1):vX(length(find(vX)));
    try
        [vXX, vYY] = wt_spline(vX, vY, vXX);
    catch, wt_error('Failed with wt_spline'); end
    if (nMidPoint <= nMin) % Min limit
        nNewX = max([(nMin + g_tWT.MovieInfo.RadJitter) min(vXX)]);
        g_tWT.MovieInfo.SplinePoints(2, 1, nCurrentFrame, nChWhisker) = nNewX;
        vNewYIndx = find(vXX == nNewX);
        g_tWT.MovieInfo.SplinePoints(2, 2, nCurrentFrame, nChWhisker) = vYY(vNewYIndx(1));
    end
    if (nMidPoint >= nMax) % Max limit
        nNewX = min([(nMax - g_tWT.MovieInfo.RadJitter) max(vXX)]);
        g_tWT.MovieInfo.SplinePoints(2, 1, nCurrentFrame, nChWhisker) = nNewX;
        vNewYIndx = find(vXX == nNewX);
        g_tWT.MovieInfo.SplinePoints(2, 2, nCurrentFrame, nChWhisker) = vYY(vNewYIndx(1));
    end
end

return

