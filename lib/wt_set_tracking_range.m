function wt_set_tracking_range
% wt_set_tracking_range
% Set the movement range of whisker splines interactively

global g_tWT

% Create dialog with +/- buttons
hFig = figure;
vPos = get(hFig, 'position');
set(hFig, 'MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Range', 'Resize', 'off', ...
    'position', [vPos(1:2) 160 90], 'closeRequestFcn', @CloseRangeWin)

uicontrol(hFig, 'style', 'text', 'string', 'Slow', 'position', [5 50 70 30], 'backgroundcolor', [.3 .9 .3])
uicontrol(hFig, 'style', 'text', 'string', 'Fast', 'position', [5 10 70 30], 'backgroundcolor', [.9 .3 .3])

uicontrol(hFig, 'style', 'pushbutton', 'position', [85 50 30 30], 'string', '+', 'callback', @UpdateRanges, 'tag', 'slow_up')
uicontrol(hFig, 'style', 'pushbutton', 'position', [120 50 30 30], 'string', '-', 'callback', @UpdateRanges, 'tag', 'slow_dn')

uicontrol(hFig, 'style', 'pushbutton', 'position', [85 10 30 30], 'string', '+', 'callback', @UpdateRanges, 'tag', 'fast_up')
uicontrol(hFig, 'style', 'pushbutton', 'position', [120 10 30 30], 'string', '-', 'callback', @UpdateRanges, 'tag', 'fast_dn')

UpdateRanges()

% TODO:
%  - Ok button

return

% Auxillary functions
function UpdateRanges(varargin)
global g_tWT

% Update values in HorJitterSlow and HorJitter
vSlow = g_tWT.MovieInfo.HorJitterSlow;
vFast = g_tWT.MovieInfo.HorJitter;
sTag = get(gcbo, 'tag');
switch sTag(6:7)
    case 'up'
        nCh = 1;
    case 'dn'
        nCh = -1;
end
switch sTag(1:4)
    case 'slow'
        vSlow = vSlow + nCh;
    case 'fast'
        vFast = vFast + nCh;
end

% Verify ranges are not negative
vSlow(vSlow < 0) = 0;
vFast(vFast < 0) = 0;

g_tWT.MovieInfo.HorJitterSlow = vSlow;
g_tWT.MovieInfo.HorJitter = vFast;

% Get current spline of the first labelled whisker
mSpl = g_tWT.MovieInfo.SplinePoints;
if isempty(mSpl) return; end
nFrame = get(g_tWT.Handles.hSlider, 'value');
if nFrame > size(mSpl, 3) return; end
mSpl = mSpl(:, :, nFrame, 1);
if ~any(mSpl(:)) return; end

% Slow range
vXX = min(mSpl(:,1)):max(mSpl(:,1));
[~, vYY_mid_slow] = wt_spline(mSpl(:,1), mSpl(1:3,2), vXX);
[~, vYY_top_slow] = wt_spline(mSpl(:,1), mSpl(1:3,2)+cumsum(vSlow'), vXX);
[~, vYY_btm_slow] = wt_spline(mSpl(:,1), mSpl(1:3,2)-cumsum(vSlow'), vXX);

% Fast range
[~, vYY_mid_fast] = wt_spline(mSpl(:,1), mSpl(1:3,2), vXX);
[~, vYY_top_fast] = wt_spline(mSpl(:,1), mSpl(1:3,2)+cumsum(vFast'), vXX);
[~, vYY_btm_fast] = wt_spline(mSpl(:,1), mSpl(1:3,2)-cumsum(vFast'), vXX);

% Update display
hObjSlow = findobj(g_tWT.WTWindow, 'tag', 'spline_range_indicator_slow');
hObjFast = findobj(g_tWT.WTWindow, 'tag', 'spline_range_indicator_fast');
if isempty([hObjSlow hObjFast])
    hObjFast = fill([vXX fliplr(vXX)], [vYY_top_fast fliplr(vYY_btm_fast)], 'r', ...
        'parent', g_tWT.FrameAx, ...
        'tag', 'spline_range_indicator_fast');
    hObjSlow = fill([vXX fliplr(vXX)], [vYY_top_slow fliplr(vYY_btm_slow)], 'g', ...
        'parent', g_tWT.FrameAx, ...
        'tag', 'spline_range_indicator_slow');
    set([hObjFast hObjSlow], 'facealpha', .3)
else
    set(hObjFast, 'xdata', [vXX fliplr(vXX)], 'ydata', [vYY_top_fast fliplr(vYY_btm_fast)])
    set(hObjSlow, 'xdata', [vXX fliplr(vXX)], 'ydata', [vYY_top_slow fliplr(vYY_btm_slow)])
end

return


% Close range selection dialog
function CloseRangeWin(varargin)
global g_tWT

% Delete range indicator in main window
hObjSlow = findobj(g_tWT.WTWindow, 'tag', 'spline_range_indicator_slow');
hObjFast = findobj(g_tWT.WTWindow, 'tag', 'spline_range_indicator_fast');
delete([hObjSlow hObjFast])

delete(gcbo)

return
