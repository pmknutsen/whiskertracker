function wt_constrain_midpoint( nWhisker )
% WT_CONSTRAIN_MIDPOINT%

global g_tWT

if ~g_tWT.DisplayMode, wt_toggle_display_mode, end

% Get region within which the midpoint should be constrained
[vX, vY, mA, vRect] = imcrop;
nMinRadPoint = round(vRect(1));
nMaxRadPoint = round(vRect(1)+vRect(3));
nCurrFrame = get(g_tWT.Handles.hSlider, 'Value');
nWhiskerBaseX = g_tWT.MovieInfo.SplinePoints(1,1,nCurrFrame,nWhisker);
if nMinRadPoint < nWhiskerBaseX, nMinRadPoint = nWhiskerBaseX; end

% Check if constraint is valid
if nMinRadPoint == nMaxRadPoint
    wt_error('You cannot select a single point. Click and drag the cursor for the width that you wish to limit the midpoint radial coordinate.')
end
if nMaxRadPoint <= nWhiskerBaseX
    wt_error('The right-hand end of the limit must be further radial than the whisker base point')
end

% do not allow x1=-x2 or x point < x(basepoint)


% If this frame has two panels (left and right side of face), then adjust
% coordinates of constraints relative to the pane in which the whisker
% belongs.
nCurrentFrame = get(g_tWT.Handles.hSlider, 'Value');
if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen) & ~isnan(prod(g_tWT.MovieInfo.Nose(nCurrentFrame, :)))
    vAxSize = get(g_tWT.FrameAx, 'XLim');
    if nMaxRadPoint >= vAxSize(2)/2
        % Change mCoords to absolute coordinates in right frame part
        nMinRadPoint = nMinRadPoint - vAxSize(2)/2;
        nMaxRadPoint = nMaxRadPoint - vAxSize(2)/2;
    end
end

% Store constraints in global namespace
g_tWT.MovieInfo.MidPointConstr(:, nWhisker) = [nMinRadPoint nMaxRadPoint]';

return
