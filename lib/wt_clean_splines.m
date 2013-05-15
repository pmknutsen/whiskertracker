% WT_CLEAN_SPLINES
%
% Clean splinepoints by removing movements of certain amplitude and
% duration. Also included is an optional low-pass filter (mainly intended
% to filter head-movements before tracking whiskers). Note that all
% changes made are permanent
%
% Syntax: wt_clean_splines(W, OPT), where
%           W is the index of the whisker to be cleaned
%           OPT is an optional string command only used by the function
%           internally.
%
% If you call the function directly, you never need to give the OPT
% parameter. This function will only work when the WT GUI is launched, and
% then only on the currently loaded movie.
%

function wt_clean_splines(w, varargin)

global g_tWT

persistent nWd;
persistent nAmp;
persistent nLp;
if nargin == 3, nLp = varargin{2}; % use passed low-filt value when saving changes
else, nLp = 0; % default low-pass (0 means no low-pass)
end

if isempty(nWd)
    nWd = 2; % default pulse-width
    nAmp = 2; % default pulse-amplitude
end
mOrigSplPoints = [];

% Check if we should execute one of the sub-routines straight away...
if nargin >= 2
    switch varargin{1}
        case 'setwidth'
            nWd = str2num(char(inputdlg(sprintf('Set maximum jitter-width (in frames). Save changes from the menu after reviewing the changes.\n'), 'Set width')));
        case 'setamplitude'
            nAmp = str2num(char(inputdlg(sprintf('Set maximum jitter-amplitude. Save changes from the menu after reviewing the changes.\n'), 'Set amplitude')));
        case 'lowpass'
            sLowPass = 'Set low-pass frequency. Save changes from menu after reviewing the changes.\n';
            nLp = str2num(char(inputdlg(sLowPass, 'Set low-pass frequency')));
        case 'savechanges'
            SaveModifiedSplines(w, nWd, nLp, nAmp);
            return;
    end
end

cTitles = [];
if w == 0
    % Clean head-movements
    mOrigSplPoints = [g_tWT.MovieInfo.RightEye g_tWT.MovieInfo.LeftEye];
    cTitles = [{'Right-eye X'}, {'Right-eye Y'}, {'Left-eye X'}, {'Left-eye Y'}];
else
    mOrigSplPoints = [];
    
    for s = 1:size(g_tWT.MovieInfo.SplinePoints, 1)
        for nDim = 1:2
            if (s == 1) & (nDim == 1), continue, end
            vData = reshape(g_tWT.MovieInfo.SplinePoints(s,nDim,:,w), size(g_tWT.MovieInfo.SplinePoints, 3), 1);
            mOrigSplPoints = [mOrigSplPoints vData];
            if nDim == 2, sDim = 'Hor';, else sDim = 'Rad';, end;
            cTitles{size(cTitles,2)+1} = sprintf('Point# %d - %s', s, sDim);
        end
    end
end

% Plot original splines
PlotModifiedSplines(mOrigSplPoints, cTitles, nWd, nLp, nAmp, w); % start with default pulse-width = 2

return;


%%%% PLOT_MODIFIED_SPLINES %%%%
function PlotModifiedSplines(mSplPoints, cTitles, nWd, nLp, nAmp, w)
global g_tWT
figure(333); clf;
set(gcf, 'DoubleBuffer', 'on', 'Menu', 'None', 'Name', 'WT Clean', 'NumberTitle', 'off')

% Plot splineas in different sub-panes
for s = 1:size(mSplPoints,2)
    subplot(size(mSplPoints,2), 1, s); hold on
    vXlim = [0 size(mSplPoints,1)];
    vYlim = [min(mSplPoints(:,s))-5 max(mSplPoints(:,s))+5];

    % Figure title
    if s == 1
        title(sprintf('Original trace is red, new trace in blue. Width=%d, Amplitude=%d Low-pass=%d', nWd, nAmp, nLp))
    end
    
    % Plot original trace
    vY = mSplPoints(:,s);
    vY(find(vY == 0)) = NaN;
    plot(1:size(mSplPoints,1), vY, 'r')

    % Plot cleaned trace
    mSlpPointsCleaned = CleanTrace(mSplPoints(:,s), nWd, nLp, nAmp);
    plot(1:size(mSplPoints,1), mSlpPointsCleaned, 'b')

    % Set axes properties
    set(gca, 'xlim', vXlim, 'ylim', vYlim, 'FontSize', 8, ...
        'xtick', vXlim(1):250:vXlim(2), ...
        'ytick', [] )
    ylabel('Pixel')
    if s == size(mSplPoints,2), xlabel('Frame#'), end
    title(cTitles{s})
end

% Create figure menu
uimenu(gcf, 'Label', 'Width', 'Callback', [sprintf('wt_clean_splines(%d, ''setwidth'')', w)]);
uimenu(gcf, 'Label', 'Amplitude', 'Callback', [sprintf('wt_clean_splines(%d, ''setamplitude'')', w)]);
uimenu(gcf, 'Label', 'Low-pass', 'Callback', [sprintf('wt_clean_splines(%d, ''lowpass'')', w)]);
uimenu(gcf, 'Label', 'Save changes', 'Callback', [sprintf('wt_clean_splines(%d, ''savechanges'', %d); close(%d); figure(%d)', w, nLp, gcf, findobj('Tag', 'WTMainWindow') )]);
uimenu(gcf, 'Label', 'Exit', 'Callback', [sprintf('close(%d)', gcf)]);

return;


%%%% SAVE_MODIFIED_SPLINES %%%%
function SaveModifiedSplines(w, nWd, nLp, nAmp)
global g_tWT
% Give warning to user
switch questdlg('These changes are irreversible! Are you should you want to save these changes?', 'Warning', 'Yes', 'No', 'No')
    case 'No'
        return;
    case 'Yes'
        if w == 0
            g_tWT.MovieInfo.RightEye(:,1) = CleanTrace(g_tWT.MovieInfo.RightEye(:,1), nWd, nLp, nAmp);
            g_tWT.MovieInfo.RightEye(:,2) = CleanTrace(g_tWT.MovieInfo.RightEye(:,2), nWd, nLp, nAmp);
            g_tWT.MovieInfo.LeftEye(:,1)  = CleanTrace(g_tWT.MovieInfo.LeftEye(:,1), nWd, nLp, nAmp);
            g_tWT.MovieInfo.LeftEye(:,2)  = CleanTrace(g_tWT.MovieInfo.LeftEye(:,2), nWd, nLp, nAmp);
            g_tWT.MovieInfo.Nose = wt_find_nose(g_tWT.MovieInfo.RightEye, g_tWT.MovieInfo.LeftEye, g_tWT.MovieInfo.EyeNoseAxLen);
        else
            %%% new
            mOrigSplPoints = [];
            for s = 1:size(g_tWT.MovieInfo.SplinePoints, 1)
                for nDim = 1:2
                    if (s == 1) & (nDim == 1), continue, end
                    vData = squeeze(g_tWT.MovieInfo.SplinePoints(s,nDim,:,w));
                    g_tWT.MovieInfo.SplinePoints(s,nDim,:,w) = ...
                        CleanTrace(vData, nWd, nLp, nAmp);                    
                end
            end
            
            % Replace NaN's with zeros
            g_tWT.MovieInfo.SplinePoints(find(isnan(g_tWT.MovieInfo.SplinePoints))) = 0;
            
            %%%
                       
%            mOrigSplPoints = [ ...
%                    reshape(g_tWT.MovieInfo.SplinePoints(1,2,:,w), size(g_tWT.MovieInfo.SplinePoints, 3), 1) ...
%                    (reshape(g_tWT.MovieInfo.SplinePoints(2,2,:,w), size(g_tWT.MovieInfo.SplinePoints, 3), 1)) ...
%                    (reshape(g_tWT.MovieInfo.SplinePoints(3,2,:,w), size(g_tWT.MovieInfo.SplinePoints, 3), 1)) ...
%                    (reshape(g_tWT.MovieInfo.SplinePoints(2,1,:,w), size(g_tWT.MovieInfo.SplinePoints, 3), 1)) ];
%            % Y coordinates
%            for s = 1:3
%                mSlpPointsCleaned = CleanTrace(mOrigSplPoints(:,s), nWd, nLp, nAmp);
%                g_tWT.MovieInfo.SplinePoints(s, 2, : ,w) = mSlpPointsCleaned;
%            end
%            % X coordinate for mid spline-point
%            mSlpPointsCleaned = CleanTrace(mOrigSplPoints(:,4), nWd, nLp, nAmp);
%            g_tWT.MovieInfo.SplinePoints(2, 1, : ,w) = mSlpPointsCleaned;
            
            g_tWT.MovieInfo.Angle(:,w) = zeros(size(g_tWT.MovieInfo.Angle(:,w))); % clear angle
            
        end
end
wt_set_status(sprintf('Saved trace %d with width = %d and low-pass = %d', w, nWd, nLp, nAmp))

return;


%%%% CLEAN_TRACE %%%%
function vNew = CleanTrace(vOld, nMaxWidth, nLowPass, nMaxAmp)
global g_tWT
vNew = vOld;
% Iterate over range of widths and amplitudes, and clean out detected jitter
for w = 1:nMaxWidth
    for a = 1:nMaxAmp
        vTempl = [0 ones(1,w) 0] * a;
        for i = 1:length(vNew)-(w+1)
            vec = vNew(i:i+length(vTempl)-1)';
            if sum(abs(vTempl - abs((vec-vec(1))))) == 0
                vNew(i:i+length(vTempl)-1) = vNew(i);
            end
        end
    end
end
% Low-pass filter
vNew(find(vNew == 0)) = NaN;
if nLowPass > 0
    vIn = vNew;
    [a,b] = butter(3, nLowPass/(g_tWT.MovieInfo.FramesPerSecond/2), 'low');
    vFiltSrsIndx = find(~isnan(vIn));
    vFiltSeries = vIn(vFiltSrsIndx);
    vOut = zeros(size(vIn))*NaN;
    vOut(vFiltSrsIndx) = filtfilt(a, b, vFiltSeries);
    vNew = vOut;
end

return;

