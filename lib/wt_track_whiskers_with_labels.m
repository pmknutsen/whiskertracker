function wt_track_whiskers_with_labels(sDefAns, sDefAnsOut, nXlim, nXlim_out)
% WT_TRACK_WHISKERS_WITH_LABELS
% Use whisker labels to interpolate/extrapolate the whisker shaft location
% in each frame. The user selects the basepoint and endpoint location. The
% function then interpolates a spline between the whisker-labels and
% extrapolates the additional distance to the base and tip.
%
% Inputs:
%   sDefAns     Base extrapolation (yes/no; default is to ask)
%   sDefAnsOut  Tip extrapolation (yes/no; default is to ask)
%   nXlim       Distance to extrapolate radial base location
%   nXlim_out   Distance to extrapolate radial tip location
%

global g_tWT

g_tWT.StopProc = 0;

g_tWT.MovieInfo.SplinePoints = [];

% Ask user if shaft should be extrapolated to base
if isempty(sDefAns)
    sAnswer = questdlg('Do you want to extrapolate the whisker medially?', 'WT', 'Cancel', 'Yes', 'No', 'No');
    if strcmpi(sAnswer, 'cancel'), return, end
else
    sAnswer = sDefAns;
end

% Ask user if shaft should be extrapolated laterally (towards the tip)
if isempty(sDefAns)
    sAnswerOut = questdlg('Do you want to extrapolate the whisker laterally?', 'WT', 'Cancel', 'Yes', 'No', 'No');
    if strcmpi(sAnswerOut, 'cancel'), return, end
else
    sAnswerOut = sDefAnsOut;
end

% Get current frame
nFrame = 1; % use 1st frame as default
if isfield(g_tWT, 'CurrentFrameBuffer')
    if isfield(g_tWT.CurrentFrameBuffer, 'Frame')
        nFrame = g_tWT.CurrentFrameBuffer.Frame;
    end
end

% Iterate over whiskers
for w = 1:length(g_tWT.MovieInfo.WhiskerLabels)

    % Get whisker label coordinates in current frame
    vX = squeeze(g_tWT.MovieInfo.WhiskerLabels{w}(nFrame,1,:));
    vY = squeeze(g_tWT.MovieInfo.WhiskerLabels{w}(nFrame,2,:));
    
    % Sort by X coordinate order
    [vX, vI] = sort(vX);
    vY = vY(vI);
    
    % Select medial-most (base) X-coordinate
    if strcmp(sAnswer, 'Yes') && isempty(nXlim)
        set(g_tWT.Handles.hStatusText, 'string', sprintf('Select base-location of whisker %s', cell2mat(g_tWT.MovieInfo.WhiskerIdentity{w})));
        [nXlim nYlim] = ginput(1);
        
        % Adjust for right-frame whiskers when head is tracked/marked
        if g_tWT.MovieInfo.WhiskerSide(w) == 2
            vAxSize = get(g_tWT.FrameAx, 'XLim');
            nXlim = nXlim - vAxSize(2)/2; % only change X
        end

        % Compute eucledian distance of base point from innermost X coord
        nXlim = sqrt([nXlim-vX(1)]^2 + [nYlim-vY(1)]^2);
    end

    % Select lateral-most (tip) X-coordinate
    if strcmp(sAnswerOut, 'Yes') && isempty(nXlim_out)
        set(g_tWT.Handles.hStatusText, 'string', sprintf('Select tip-location of whisker %s', cell2mat(g_tWT.MovieInfo.WhiskerIdentity{w})));
        [nXlim_out nYlim_out] = ginput(1);

        % Adjust for right-frame whiskers when head is tracked/marked
        if g_tWT.MovieInfo.WhiskerSide(w) == 2
            vAxSize = get(g_tWT.FrameAx, 'XLim');
            nXlim_out = nXlim_out - vAxSize(2)/2; % only change X
        end

        % Compute eucledian distance of base point from innermost X coord
        nXlim_out = sqrt([nXlim_out-vX(end)]^2 + [nXlim_out-vY(end)]^2);
    end
    
    set(g_tWT.Handles.hStatusText, 'string', sprintf('Assigning splinepoints to whisker %s. Please wait...', cell2mat(g_tWT.MovieInfo.WhiskerIdentity{w}))); drawnow
    for f = 1:size(g_tWT.MovieInfo.WhiskerLabels{w}, 1) % Iterate over frames
        vX = squeeze(g_tWT.MovieInfo.WhiskerLabels{w}(f,1,:));
        vY = squeeze(g_tWT.MovieInfo.WhiskerLabels{w}(f,2,:));
        vIndxRemX = find(isnan(vX));
        vIndxRemY = find(isnan(vY));
        vX([vIndxRemX vIndxRemY]) = [];
        vY([vIndxRemX vIndxRemY]) = [];
        if isempty(vX) || isempty(vY), continue, end

        % Extrapolate to base (by distance)
        if isnan(nXlim), nXlim = []; end
        if ~isempty(nXlim)
            % Extrapolate to double-length
            vXX = [vX(1)-(vX(end)-vX(1))]:vX(1);
            if length(vX) == 2
                vYY = interp1(vX, vY, vXX, 'linear', 'extrap');
            else
                vYY = interp1(vX, vY, vXX, 'spline', 'extrap');
            end
            vDD = sqrt([vX(1)-vXX].^2 + [vY(1)-vYY].^2);
            [nMin, nMinIndx] = min(abs(nXlim - vDD));
            nX_base = vXX(nMinIndx);
            nY_base = vYY(nMinIndx);
            
            if nX_base > vX(1), keyboard, end
        end

        % Extrapolate to tip (by distance)
        if isnan(nXlim_out), nXlim_out = []; end
        if ~isempty(nXlim_out)
            % Extrapolate to double-length
            vXX = vX(end):[vX(end)+(vX(end)-vX(1))];
            if length(vX) == 2
                vYY = interp1(vX, vY, vXX, 'spline', 'extrap');
            else
                vYY = interp1(vX, vY, vXX, 'spline', 'extrap');
            end
            vDD = sqrt([vX(end)-vXX].^2 + [vY(end)-vYY].^2);
            [nMin, nMinIndx] = min(abs(nXlim_out - vDD));
            nX_tip = vXX(nMinIndx);
            nY_tip = vYY(nMinIndx);
        end

        % Assign extrapolated values to data
        if ~isempty(nXlim)
            vX = [nX_base;vX];
            vY = [nY_base;vY];
        end
        if ~isempty(nXlim_out)
            vX = [vX;nX_tip];
            vY = [vY;nY_tip];
        end
        
        % If there are only two splinepoints (e.g. only base and tip were
        % tracked), interpolate a third point halfway between vX(1) and vX(2)
        if length(vX) == 2
            vXX = [vX(1) sum(vX)/2 vX(2)]';
            try % catch cases when points are not unique
                vYY = interp1(vX, vY, vXX, 'linear', 'extrap'); % linear because its a line...
            catch
                wt_error(sprintf('Failed computing spline in frame %d. Will not attempt to compute additional frames.', f), 'warn')
                break;
            end
            vX = vXX;
            vY = vYY;
        end
        g_tWT.MovieInfo.SplinePoints(1:length(vX),1,f,w) = vX;
        g_tWT.MovieInfo.SplinePoints(1:length(vX),2,f,w) = vY;
        % Update slider
        set(g_tWT.Handles.hSlider, 'value', f);
        
        % Checck if we should stop
        if isfield(g_tWT, 'StopProc')
            if g_tWT.StopProc
                break;
            end
        end
        drawnow
    end

    wt_display_frame(1)
    
    % Check if we should stop
    if isfield(g_tWT, 'StopProc')
        if g_tWT.StopProc
            break;
        end
    end

end


set(g_tWT.Handles.hStatusText, 'string', '');

if isempty(nXlim_out), nXlim_out = NaN; end
if isempty(nXlim), nXlim = NaN; end
wt_batch_redo(['wt_track_whiskers_with_labels(''' sAnswer ''', ''' sAnswerOut ''', ' num2str(nXlim) ', ' num2str(nXlim_out) ')']);

return

