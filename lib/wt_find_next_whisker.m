function [nScore, nScoreStd, nScoreN] = wt_find_next_whisker(nChWhisker, nCurFrame, nPrevFrame, mImg, sSpeed)
% wt_find_next_whisker
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

% Initialize fitting function
if isempty(p_fQuadFun)
    p_fQuadFun = inline('1 - exp( -(x-b(1)).^2 / (2*b(2).^2) )', 'b', 'x');
end
if g_tWT.ParallelMode && exist('matlabpool', 'file')
    nPoolSize = matlabpool('size');
else
    nPoolSize = 0;
end

% Setting fitting parameters (somewhat optimized for speed)
if exist('nlinfit') % statistics toolbox
    sFitFun = 'nlinfit';
    tOptions = statset('Display', 'off', 'MaxIter', 10, 'TolFun', 1e-2, 'TolX', 1e-4);
elseif exist('lsqcurvefit') % optimization toolbox
    sFitFun = 'lsqcurvefit';
    tOptions = optimset('Display', 'off', 'MaxIter', 10, 'TolFun', 1e-3, 'TolX', 1e-4);
else
    sFitFun = 'none';
    tOptions = struct([]);
end

warning('off', 'MATLAB:polyfit:PolyNotUnique')

% Construct the velocity matrix
%  - the velocity matrix attempts to extrapolate the new position of the
%    whisker from its current velocity
if g_tWT.MovieInfo.UsePosExtrap % Position extrapolation matrix
    mVelMat = wt_extrapolate_position(g_tWT.MovieInfo.SplinePoints(:,:,nPrevFrame,nChWhisker), ...
        mImg, ...
        g_tWT.MovieInfo.SplinePoints(:, :, 1:nPrevFrame, nChWhisker) );

    if g_tWT.VerboseMode
        % Update/display debug window
        hFig = findobj('Tag', 'WT_DEBUG_EXTRAPOLATION_WINDOW');
        if isempty(hFig)
            hFig = figure;
            set(hFig, 'Tag', 'WT_DEBUG_EXTRAPOLATION_WINDOW', 'DoubleBuffer', 'on', ...
                'Name', ['WT Debug - ' mfilename], 'numbertitle', 'off', 'toolbar', 'none')
        end
        colormap gray
        hAx = subplot(1, 3, 1, 'parent', hFig);
        imagesc(mImg, 'parent', hAx);
        title('Original')
        subplot(1, 3, 2, 'parent', hFig);
        imagesc(mVelMat, 'parent', hAx);
        title(hAx, 'VelocityMatrix')
        subplot(1, 3, 3, 'parent', hFig);
        imagesc(mImg.*mVelMat, 'parent', hAx);
        title(hAx, 'Original*VelocityMatrix')
    end
    
else
    mVelMat = ones(size(mImg));
end

% Get whisker spline of previous frame
nPrevFrame = max([nPrevFrame 1]);
mCurrSpline = round(g_tWT.MovieInfo.SplinePoints(:, :, nPrevFrame, nChWhisker));
vRemRows = find(~sum(mCurrSpline, 2)');
mCurrSpline(vRemRows,:) = []; % Remove [0 0] rows

% Select spline movement range
if strcmp(sSpeed, 'auto') % auto-select range
    % Compute angle in previous frame
    [nA, nI] = wt_get_angle(mCurrSpline, g_tWT.MovieInfo.RefLine, g_tWT.MovieInfo.AngleDelta);
    g_tWT.MovieInfo.Angle(nPrevFrame, nChWhisker) = nA;
    g_tWT.MovieInfo.Intersect(nPrevFrame, 1:2, nChWhisker) = nI;
    if nA < g_tWT.MovieInfo.nHorAutoThresh
        sSpeed = 'slow';
    else
        sSpeed = 'fast';
    end
end

switch sSpeed
    case 'fast'
        % Use 'fast' settings
        mEnumRange = [0 g_tWT.MovieInfo.RadJitter 0; g_tWT.MovieInfo.HorJitter]';
    case 'slow'
        % Use 'slow' settings
        mEnumRange = [0 g_tWT.MovieInfo.RadJitter 0; g_tWT.MovieInfo.HorJitterSlow]';
end

% Verify that movement range is valid
if size(mCurrSpline, 1) == 4
    if mCurrSpline(4, 1) == 0
        mCurrSpline(4, :) = [];
    else
        mEnumRange = [mEnumRange(1,:); mEnumRange(2,:); mEnumRange(2,:); mEnumRange(3,:)];
    end
end

% Cell MEX routine
if g_tWT.RepositionOnly
    % If we are only doing repositioning, grab already tracked location
    mNewSpline = round(mCurrSpline);
    nScore = 2;
    nScoreStd = 0;
    nScoreN = 0;
else
    try
        warning('off', 'MATLAB:mex:deprecatedExtension');
        [mNewSpline, nScore, nScoreStd, nScoreN] = find_next_whisker(mCurrSpline, mEnumRange, mImg, g_tWT.FiltVec, mVelMat );
    catch
        wt_error(lasterr, 'error')
    end
end

% TEMPORARY PATCH
%  When score==0, values returned by find_next_whisker may reach
%  extreme values. When this happens, keep values from last frame.
if nScore == 0
    if nCurFrame == 1
        g_tWT.MovieInfo.SplinePoints(:,:,nCurFrame,nChWhisker) = g_tWT.MovieInfo.SplinePoints(:,:,nCurFrame,nChWhisker);
    else
        g_tWT.MovieInfo.SplinePoints(:,:,nCurFrame,nChWhisker) = g_tWT.MovieInfo.SplinePoints(:,:,nCurFrame-1,nChWhisker);
    end
    wt_set_status('Warning: Cannot discern whisker from background. Using coordinates of previous frame.')
else
    % Improve tracking accuracy by interpolating position of individual points along the
    % whisker spline to a better estimated location of whisker center.
    % Note: This refinement takes a bit hit on performance.
    if g_tWT.RepositionOnly
        nProfileRad = g_tWT.MovieInfo.WhiskerWidth * 2;
        if g_tWT.MovieInfo.nTrackAccAdj > 0
            % 1.0  Fit every point along spline
            % 0.0  Fit none of the points along the spline
            % If a value above 0% is selected, the minimum number of points is 3
            vXX = min(mNewSpline(:,1)):max(mNewSpline(:,1));
            nLen = length(vXX);
            nFit = round(nLen * g_tWT.MovieInfo.nTrackAccAdj); % number of points to fit
            if nFit < 3 % minimum is 3 points
                nFit = 3;
            end
            vIndx = unique(round(linspace(1, nLen, nFit)));
            [vXi, vYi] = wt_spline(mNewSpline(:,1), mNewSpline(:,2), vXX(vIndx));
            mAdjustPoints = [vXi' vYi'];
            
            if nPoolSize > 1 % run parallel version (parfor loop)
                mFullSpline = OptimizeWhiskerPlacementPar(g_tWT, p_fQuadFun, mAdjustPoints, nProfileRad, mImg, sFitFun, tOptions);
            else % run non-parellel code (for loop)
                mFullSpline = OptimizeWhiskerPlacement(g_tWT, p_fQuadFun, mAdjustPoints, nProfileRad, mImg, sFitFun, tOptions);
            end
            
            [vX, vY] = wt_spline(mFullSpline(:,1), mFullSpline(:,2), mNewSpline(:,1));
            if size(mFullSpline, 1) > 3
                [vP] = polyfit(mFullSpline(:,1), mFullSpline(:,2), 3);
                vX = mNewSpline(:,1);
                vY = vP(1).*vX.^3 + vP(2).*vX.^2 + vP(3).*vX + vP(4);
                mNewSpline = [vX vY];
            else
                mNewSpline = mFullSpline;
            end
        end
    end
    g_tWT.MovieInfo.SplinePoints(1:size(mNewSpline,1),:, nCurFrame, nChWhisker) = mNewSpline;
end

% Add [0 0] rows removed earlier
if ~isempty(vRemRows)
    g_tWT.MovieInfo.SplinePoints(vRemRows, :, nCurFrame, nChWhisker) = zeros(length(vRemRows),2);
end

% Check whisker length
vX = g_tWT.MovieInfo.SplinePoints(:, 1, nCurFrame, nChWhisker);
vY = g_tWT.MovieInfo.SplinePoints(:, 2, nCurFrame, nChWhisker);
[vX vY] = wt_adjust_whisker_length(nChWhisker, vX, vY);
g_tWT.MovieInfo.SplinePoints(1:size(vX,1), 1, nCurFrame, nChWhisker) = vX;
g_tWT.MovieInfo.SplinePoints(1:size(vY,1), 2, nCurFrame, nChWhisker) = vY;

% Constrain mid-point
%  - user defined constraint
if sum(g_tWT.MovieInfo.MidPointConstr(:,nChWhisker)) ~= 0
    nMin = g_tWT.MovieInfo.MidPointConstr(1, nChWhisker);
    nMax = g_tWT.MovieInfo.MidPointConstr(2, nChWhisker);
    nMidPoint = g_tWT.MovieInfo.SplinePoints(2, 1, nCurFrame, nChWhisker);
    vX = g_tWT.MovieInfo.SplinePoints(:, 1, nCurFrame, nChWhisker);
    vY = g_tWT.MovieInfo.SplinePoints(:, 2, nCurFrame, nChWhisker);
    vXX = vX(1):vX(length(find(vX)));
    try
        [vXX, vYY] = wt_spline(vX, vY, vXX);
    catch
        wt_error('Failed with wt_spline');
    end
    if (nMidPoint <= nMin) % Min limit
        nNewX = max([(nMin + g_tWT.MovieInfo.RadJitter) min(vXX)]);
        g_tWT.MovieInfo.SplinePoints(2, 1, nCurFrame, nChWhisker) = nNewX;
        vNewYIndx = find(vXX == nNewX);
        g_tWT.MovieInfo.SplinePoints(2, 2, nCurFrame, nChWhisker) = vYY(vNewYIndx(1));
    end
    if (nMidPoint >= nMax) % Max limit
        nNewX = min([(nMax - g_tWT.MovieInfo.RadJitter) max(vXX)]);
        g_tWT.MovieInfo.SplinePoints(2, 1, nCurFrame, nChWhisker) = nNewX;
        vNewYIndx = find(vXX == nNewX);
        g_tWT.MovieInfo.SplinePoints(2, 2, nCurFrame, nChWhisker) = vYY(vNewYIndx(1));
    end
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wrapper functions for optimizing whisker placement

% Non-parallel processing version
function mFullSpline = OptimizeWhiskerPlacement(g_tWT, p_fQuadFun, mAdjustPoints, nProfileRad, mImg, sFitFun, tOptions)
mFullSpline = [];
warning('off', 'stats:nlinfit:IterationLimitExceeded')
warning('off', 'stats:nlinfit:IllConditionedJacobian')
for i = 1:size(mAdjustPoints, 1) % note use of parfor
    vXY = round(mAdjustPoints(i, :));
    % Get profile of whisker shaft
    vX = (vXY(2)-nProfileRad):(vXY(2)+nProfileRad);
    % skip if any part of the requested whisker cross-section falls outside
    % of the frame
    if ~(any(vX < 1) || any(vX > size(mImg, 1)))
        vY = mImg(vX, vXY(1));
        vY = (vY-min(vY))/max(vY-min(vY));
        vXXi = linspace(min(vX), max(vX), 200);
        vInitParms = [vX(nProfileRad+1) g_tWT.MovieInfo.WhiskerWidth/2];
        
        switch sFitFun
            case 'nlinfit'
                vB = nlinfit(vX(:), vY, p_fQuadFun, vInitParms, tOptions);
            case 'lsqcurvefit'
                vB = lsqcurvefit(p_fQuadFun, vInitParms, vX(:), vY, [], [], tOptions);
        end
        
        vYYi = p_fQuadFun(vB, vXXi);
        [nMin nMinIndx] = min(vYYi);
        mFullSpline(i, :) = [vXY(1) vXXi(nMinIndx)];
    end
end

return

% Parallel processing version (parfor loop)
function mFullSpline = OptimizeWhiskerPlacementPar(g_tWT, p_fQuadFun, mAdjustPoints, nProfileRad, mImg, sFitFun, tOptions)
mFullSpline = [];
parfor i = 1:size(mAdjustPoints, 1) % note use of parfor
    warning('off', 'stats:nlinfit:IterationLimitExceeded')
    warning('off', 'stats:nlinfit:IllConditionedJacobian')
    vXY = round(mAdjustPoints(i, :));
    % Get profile of whisker shaft
    vX = (vXY(2)-nProfileRad):(vXY(2)+nProfileRad);
    % skip if any part of the requested whisker cross-section falls outside
    % of the frame
    if ~(any(vX < 1) || any(vX > size(mImg, 1)))
        vY = mImg(vX, vXY(1));
        vY = (vY-min(vY))/max(vY-min(vY));
        vXXi = linspace(min(vX), max(vX), 200);
        vInitParms = [vX(nProfileRad+1) g_tWT.MovieInfo.WhiskerWidth/2];

        vB = [];
        switch sFitFun
            case 'nlinfit'
                vB = nlinfit(vX(:), vY, p_fQuadFun, vInitParms, tOptions);
            case 'lsqcurvefit'
                vB = lsqcurvefit(p_fQuadFun, vInitParms, vX(:), vY, [], [], tOptions);
        end
        
        vYYi = p_fQuadFun(vB, vXXi);
        [nMin nMinIndx] = min(vYYi);
        mFullSpline(i, :) = [vXY(1) vXXi(nMinIndx)];
    end
end
return
