function bStop = wt_plot_signal_noise(vSR)
% wt_plot_signal_noise
% Plots the signal-to-noise ratio of the whisker against the background.
% The ratio itself is computed in the find_next_whisker.dll. This function
% just accepts the number(s) to plot. Adds a red, horizontal bar for
% setting the threshold at which tracking should be automatically stopped.
%
% Syntax:
%  wt_plot_signal_noise(N)  : add N to XDATA in SR window
%  wt_plot_signal_noise([]) : reset SR plot

global g_tWT

persistent p_hSRWin p_nAutoclear p_nClock p_vFPS

% Clear tracking speed variable
if isempty(vSR), p_vFPS = []; end

% Update tracking speed counter (current and average FPS)
if ~isempty(p_nClock)
    nElapsedTime = etime(clock, p_nClock);
    p_nClock = clock;
    p_vFPS = [p_vFPS length(vSR)/nElapsedTime]; % tracking speed, fps
    set(findobj('tag','fps'), 'label', sprintf('Tracking speed: %.1f fps', mean(p_vFPS)))
else
    p_nClock = clock;
end

if isempty(p_nAutoclear) p_nAutoclear = 500;
else
    if ~isempty(findobj('tag', 'AutoClearButton'))
        p_nAutoclear = get(findobj('tag', 'AutoClearButton'), 'UserData');
    end
end

% Figure
if isempty(p_hSRWin) || ~ishandle(p_hSRWin)
    p_hSRWin = figure;
    set(p_hSRWin, 'Name', 'S/N  Use mouse to set threshold', ...
        'MenuBar', 'none', ...
        'NumberTitle', 'off', ...
        'Position', [450 370 480 200], ...
        'CloseRequestFcn', 'wt_toggle_signal_noise;delete(gcbo)', ...
        'Color', 'k', ...
        'Tag', 'wt_sn_figure' )
    uimenu(gcf, 'Label', 'Clear', 'callback', 'wt_plot_signal_noise([])')
    uimenu(gcf, 'Label', sprintf('Set autoclear (%d frames)', p_nAutoclear), 'callback', @SetAutoClear, 'Tag', 'AutoClearButton')
    uimenu(gcf, 'Label', 'Tracking speed: 0 fps', 'Tag', 'fps')
end

% Axes
hAxes = findobj('tag', 'wt_sn_axes');
if isempty(hAxes)
    hAxes = subplot('Position', [.075 .15 .9 .8]);
    set(gca, 'FontSize', 7, 'color', 'k', ...
        'xcolor', 'w', 'ycolor', 'w', ...
        'ButtonDownFcn', @SetThreshold, ...
        'tag', 'wt_sn_axes' )
    ylabel('S/N');
    xlabel('Time (frames)')
end

% Plot
hLines = findobj(hAxes(end), 'type', 'line'); % there are two line objects: S/N and THRESHOLD
if isempty(hLines)
    hLines(1) = line(1,1);
    hThreshLine = line(0,2);
    set(hLines(1), 'Tag', 'SR', 'linestyle', '.', 'Marker', '.', 'color', [0 .8 0]);
    set(hThreshLine, 'Tag', 'THRESH', 'color', 'r', 'LineStyle', ':');
end

% Return if the input is empty
hSR = findobj('tag','SR');
if isempty(vSR)
    vSR = 0;
else
    hSR = hSR(1);
    vSR = [get(hSR, 'ydata') vSR];
    %if length(vSR) > 1
    %    vSR(1) = [];
    %end
end

set(hAxes, 'ylim', [0 max(vSR)+2])
set(findobj('tag','SR'), 'ydata', vSR, 'xdata', 0:length(vSR)-1)
vYdata = get(findobj('tag','THRESH'), 'ydata');
if iscell(vYdata), vYdata = vYdata{1}; end
set(findobj('tag', 'THRESH'), 'ydata', repmat(vYdata(1), 1, length(vSR)), 'xdata', 0:length(vSR)-1)

hLines = get(hAxes(end), 'children'); % there are two line objects: S/N and THRESHOLD

% Evaluate SR
vThresh = get(findobj('tag','THRESH'), 'ydata');
if iscell(vThresh) vThresh = vThresh{1}; end
if (vSR(end) <= vThresh(end)) && vSR(end)~=0
    beep
    g_tWT.StopProc = 1;
end

% If length of vSR > p_nAutoclear, clear the display
if length(vSR) > p_nAutoclear, wt_plot_signal_noise([]), end

return

%%% Change SR threshold %%%
function SetThreshold(varargin)

mPnts = get(gca,'CurrentPoint');
nY = mPnts(1,2);

nXlim = get(gca, 'xlim');
set(findobj('tag','THRESH'), 'xdata', 0:nXlim(2), ...
    'ydata', repmat(nY,1,length(0:nXlim(2))) )

return


%%% Change Autoclear %%%
function SetAutoClear( varargin )
sAutoClFrames = inputdlg('Number of frames between autoclear', 'Set autoclear', 1);
if isempty(char(sAutoClFrames)), return, end
nAutoClFrames = str2num(char(sAutoClFrames));
set(findobj('tag', 'AutoClearButton'), 'Label', sprintf('Set autoclear (%d frames)', nAutoClFrames), 'UserData', nAutoClFrames);
return

