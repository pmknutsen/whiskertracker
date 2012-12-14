function wt_mark_whisker(varargin)
% WT_MARK_WHISKER
% Mark new whisker, or add/remove spline-points that define whiskerpoints.
% Syntax: wt_mark_whisker(OPT), where
%           OPT is an optional string that runs one of the following
%           subroutines:
%               'new'           - mark a new whisker
%               'addpoint'      - add splinepoint to existing whisker
%               'removepoint'   - remove splinepoint from existing whisker
%               'movebasepoint' - move the whisker base point
%               'setfulllength' - mark the full length of the whisker
%               'setlastframe'  - mark the last frame on which to track the
%                                   whisker
%
% The default subroutine is 'new'. For all other subroutines, 
% you must provide a second parameter which is the whisker ID/index
% to modify.

if nargin >= 1
    sSub = varargin{1};
    nW = varargin{2};
else, sSub = 'new'; end

switch sSub
    case 'new'
        MarkNewWhisker;
    case 'addpoint'
        AddPoint(nW);
    case 'removepoint'
        RemovePoint(nW);
    case 'setlastframe'
        SetLastFrame(nW);
    case 'setfulllength'
        SetFullLength(nW);
        return
    case 'movebasepoint'
        MoveBasePoint(nW);
end

wt_display_frame % refresh current frame

return;

%%%% MARKNEWWHISKER %%%%%%%%%%%%%%%%%%%%%%%
function MarkNewWhisker
global g_tWT

nFirstFrame = round(get(g_tWT.Handles.hSlider, 'Value'));

% If current frame is before head was tracked, move it to 1st frame with
% head
if ~isempty(g_tWT.MovieInfo.Nose)
    vIndx = find(~isnan(g_tWT.MovieInfo.Nose(:,1)));
    if nFirstFrame < vIndx(1), nFirstFrame = vIndx(1); end
    wt_display_frame(nFirstFrame);
end

axes(g_tWT.FrameAx); hold on
vX = []; vY = [];
hDots = [];
try
    for i = 1:3
            [vX(i), vY(i)] = ginput(1);  % user can hit RETURN
            hDots(end+1) = line(vX(i), vY(i));
            set(hDots(end), 'color', 'g', 'marker', '.')
    end
catch
    return  % in case the user did not input data but instead hit RETURN
end
delete(hDots)

% Sort points
mCoords = round(sortrows([vX' vY']));

% If this is a two-sided frame, detect which side this whisker belongs to
nCurrentFrame = get(g_tWT.Handles.hSlider, 'Value');
if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen)
    if ~isnan(prod(g_tWT.MovieInfo.Nose(nCurrentFrame, :))) % head is known only if nose is known
        vAxSize = get(g_tWT.FrameAx, 'XLim');
        % Locate side based on x val of first point
        if mCoords(1,1) < vAxSize(2)/2
            % Left part of frame (right side of rat). Don't change mCoords
            nSide = 1;
        else
            % Right part of frame (left side of rat)
            % Change mCoords to absolute coordinates in right frame part
            mCoords(:,1) = mCoords(:,1) - vAxSize(2)/2; % only change X
            nSide = 2;
        end
    else, nSide = 1; end
else nSide = 1; end

% Save whisker splinepoints
if isempty(g_tWT.MovieInfo.SplinePoints), nIndx = 1;
else, nIndx = size(g_tWT.MovieInfo.SplinePoints, 4) + 1; end
g_tWT.MovieInfo.SplinePoints(1:3, 1:2, nFirstFrame, nIndx) = mCoords;% ./ g_tWT.MovieInfo.ResizeFactor;
g_tWT.MovieInfo.Angle(nFirstFrame, nIndx) = 0;
g_tWT.MovieInfo.Intersect(nFirstFrame, 1:2, nIndx) = [0 0];
g_tWT.MovieInfo.MidPointConstr(1:2, nIndx) = [0 0]';
g_tWT.MovieInfo.WhiskerSide(nIndx) = nSide; % 0=left, 1=right
g_tWT.MovieInfo.LastFrame(nIndx) = g_tWT.MovieInfo.NumFrames;

% Set whisker identity
wt_set_identity(nIndx);

return;


%%%% ADDPOINT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function AddPoint(nW)
global g_tWT
nPtLim = 4; % max num of allowed splinepoints
nCurrFrame = round(get(g_tWT.Handles.hSlider, 'Value'));
mWhisker = g_tWT.MovieInfo.SplinePoints(:,:,nCurrFrame,nW);
if size(mWhisker,1) >= 4
    if mWhisker(4,1) ~= 0
        hWarnDlg = warndlg(sprintf('The maximum number of allowed points (%d) has already been reached.', nPtLim), 'WT Error');
        waitfor(hWarnDlg); return;
    else
        mWhisker = mWhisker(1:3,:);
    end
end

% Get new point and check that its within X bounds of existing whisker
vAxSize = get(g_tWT.FrameAx, 'XLim');
while 1
    [nX, nY] = ginput(1); % get position of new object
    if g_tWT.MovieInfo.WhiskerSide(nW) == 2
        nX = nX - vAxSize(2)/2;
    end
    if nX <= max(mWhisker(:,1)) & nX >= min(mWhisker(:,1)), break
    else
        sAns = questdlg('The marked point is outside boundaries of current whisker.', ...
            'Error in input', ...
            'Try again', 'Cancel', 'Try again' );
       if strcmp(sAns, 'Cancel'), return; end
    end
end

plot(nX + vAxSize(2)/2, nY, 'r.'); % plot new point
mWhisker = round(sortrows([mWhisker; nX nY]));
if size(g_tWT.MovieInfo.SplinePoints,1) ~= 4
    g_tWT.MovieInfo.SplinePoints(4,1:2,:,nW) = 0; % expand all frames with an extra row of values (NaN)
end
g_tWT.MovieInfo.SplinePoints(:,:,nCurrFrame,nW) = mWhisker; % save new point

return;

%%%% REMOVEPOINT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RemovePoint(nW)
global g_tWT

nCurrFrame = get(g_tWT.Handles.hSlider, 'Value');
mWhisker = g_tWT.MovieInfo.SplinePoints(:,:,nCurrFrame,nW);
if size(mWhisker,1) >= 4
    if mWhisker(4,1) == 0
        hWarnDlg = warndlg('There are no points to delete.', 'WT Error');
        waitfor(hWarnDlg);
        return;
    end
end

[nX, nY] = ginput(1); % get position of new object
vAxSize = get(g_tWT.FrameAx, 'XLim');
if g_tWT.MovieInfo.WhiskerSide(nW) == 2
    nX = nX - vAxSize(2)/2;
end

% Find closest point (only 2nd or 3rd)
[y, nIndx] = min(sqrt(abs(mWhisker(2:3,1)-nX).^2 + abs(mWhisker(2:3,2)-nY).^2));
nIndx = nIndx + 1;
% Verify removal of point
sAns = questdlg(sprintf('You have chosen to delete point number %d from the left. Please confirm.', nIndx), ...
    'WT Confirm', ...
    'OK', 'Cancel', 'Cancel');
if strcmp(sAns, 'Cancel'), return; end

% Remove point
switch nIndx
    case 2 % remove 1st midpoint
        g_tWT.MovieInfo.SplinePoints(2:3,:,nCurrFrame,nW) = g_tWT.MovieInfo.SplinePoints(3:4,:,nCurrFrame,nW);
        g_tWT.MovieInfo.SplinePoints(4,:,nCurrFrame,nW) = 0;
    case 3 % remove 2nd midpoint
        g_tWT.MovieInfo.SplinePoints(3,:,nCurrFrame,nW) = g_tWT.MovieInfo.SplinePoints(4,:,nCurrFrame,nW);
        g_tWT.MovieInfo.SplinePoints(4,:,nCurrFrame,nW) = 0;
end

return;


%%%% SETLASTFRAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetLastFrame(nW);
global g_tWT

% default is current frame
sLastFrame = inputdlg('Set last frame to track', 'Set last frame', 1, {num2str(get(g_tWT.Handles.hSlider, 'value'))});

% Change last frame value unless user hit Cancel or eXit
if ~isempty(sLastFrame)
    g_tWT.MovieInfo.LastFrame(nW) = str2num(char(sLastFrame));
end

return;


%%%% SETFULLLENGTH %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetFullLength(nW);
global g_tWT

if ~isfield(g_tWT.MovieInfo, 'WhiskerLength')
    g_tWT.MovieInfo.WhiskerLength = zeros(1,size(g_tWT.MovieInfo.SplinePoints,4)).*NaN;
elseif length(g_tWT.MovieInfo.WhiskerLength) < size(g_tWT.MovieInfo.SplinePoints,4)
    g_tWT.MovieInfo.WhiskerLength(nW) = NaN;
end

sCurrLen = num2str(g_tWT.MovieInfo.WhiskerLength(nW));

sAns = questdlg('How do you want to set the full whisker length?', 'WT', 'Measure','Enter value','Cancel','Measure');
switch sAns
    case 'Enter value'
        sLen = inputdlg('Enter whisker length in millimeters', 'WT', 1, {sCurrLen});
        if isempty(sLen), return, end
        nLen = str2num(cell2mat(sLen));
    case 'Measure'
        
        % Check that movie is calibrated
        if isempty(g_tWT.MovieInfo.CalBarLength) | all(g_tWT.MovieInfo.CalibCoords(:) == 0)
            wt_error('You must calibrate before marking the full whisker length. Select Image -> Calibrate... from the menu.')
        end
        
        if g_tWT.DisplayMode == 1, wt_toggle_display_mode, end, wt_display_frame % absolute view mode
        
        axes(g_tWT.FrameAx); hold on % get points
        vX = []; vY = [];
        try
            for i = 1:3
                [vX(i), vY(i)] = ginput(1);
                plot(vX(i), vY(i), 'g.')
            end
        catch, return, end
        mCoords = round(sortrows([vX' vY'])); % sort
        
        vXX = mCoords(1,1):mCoords(end,1);
        [vXX, vYY] = wt_spline(mCoords(:,1), mCoords(:,2), vXX); % spline
        plot(vXX, vYY, 'w:', 'linewidth', 2) % plot whisker
        
        nLen = sum(sqrt(diff(vXX).^2 + diff(vYY).^2)); % whisker length (pixels)
        nLen = nLen / g_tWT.MovieInfo.PixelsPerMM; % length (mm)
        msgbox(sprintf('Whisker length is %.1f mm', nLen), 'WT')
    case 'Cancel', return
end
g_tWT.MovieInfo.WhiskerLength(nW) = nLen; % length (mm)
g_tWT.MovieInfo.WhiskerLength(find(g_tWT.MovieInfo.WhiskerLength == 0)) = NaN;

return

%%%% MOVEBASEPOINT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MoveBasePoint(nW)
global g_tWT

nCurrentFrame = get(g_tWT.Handles.hSlider, 'Value');

[nX, nY] = ginput(1);

% If this is a two-sided frame, detect which side this whisker belongs to
nCurrentFrame = get(g_tWT.Handles.hSlider, 'Value');
if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen) % if head has been tracked...
    if ~isnan(prod(g_tWT.MovieInfo.Nose(nCurrentFrame, :))) % head is known only if nose is known
        vAxSize = get(g_tWT.FrameAx, 'XLim');
        if nX > vAxSize(2)/2 % Right part of frame (left side of rat)
            nX = nX - vAxSize(2)/2; % change X
        end
    end
end

g_tWT.MovieInfo.SplinePoints(1,1:2,nCurrentFrame,nW) = [round(nX) nY];
wt_display_frame;

return
