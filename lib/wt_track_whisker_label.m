function wt_track_whisker_label(nWhisker, sOption, nLabel)
% WT_TRACK_WHISKER_LABEL
% Tracks a label (ie. a physical marker) attached to the whisker shaft.
%
%
% Notes:
% The locations of whisker labels can be region-limited by adding an
% outline called LABELLIM
%

global g_tWT

nCurrFrame = round(get(g_tWT.Handles.hSlider, 'Value')); % current frame
sMethod = 'nearest'; % method of interpolation during image rotation

vObjIndx = [];
switch sOption % if neither option is met, continue with automatic tracking
    case 'manual_without_deletion' % track label manually from current frame without deletion
        if isempty(g_tWT.MovieInfo.WhiskerLabels), return, end
        vObjIndx = nLabel;
        wt_prep_gui; wt_display_frame;
    case 'manual_with_deletion' % track label manually from current frame with deletion
        if isempty(g_tWT.MovieInfo.WhiskerLabels), return, end
        sBtn = questdlg('Do you really want to clear frames tracked onwards from this point?', 'Track manual', 'Yes', 'No', 'No' );
        if ~strcmp('Yes', sBtn), return; end
        g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame+1:end,:,nLabel) = NaN;
        vObjIndx = nLabel;
        wt_prep_gui; wt_display_frame;
    case 'continue' % continue tracking label from current frame
        if isempty(g_tWT.MovieInfo.WhiskerLabels), return, end
        vObjIndx = nLabel;
    case 'continuefixed' % continue tracking by placing label in a fixed location
        if isempty(g_tWT.MovieInfo.WhiskerLabels), return, end
        vObjIndx = nLabel;
    case 'continue-all' % continue tracking all labels from the frame until which they have already been tracked
        if isempty(g_tWT.MovieInfo.WhiskerLabels), return, end
        vObjIndx = nLabel;
    case 'delete' % delete existing label
        if isempty(g_tWT.MovieInfo.WhiskerLabels), return, end
        sBtn = questdlg('Do you really want to clear the selected label?', 'Delete label', 'Yes', 'No', 'No' );
        if ~strcmp('Yes', sBtn), return; end
        g_tWT.MovieInfo.WhiskerLabels{nWhisker}(:,:,nLabel) = NaN;
        sTag = sprintf('whiskerlabel-%d-%d', nWhisker, nLabel);
        delete(findobj('Tag', sTag))
        wt_display_frame
        return
    case 'delete-all' % delete ALL existing labels
        if isempty(g_tWT.MovieInfo.WhiskerLabels), return, end
        sBtn = questdlg('Do you really want to clear all whisker labels?', 'Delete labels', 'Yes', 'No', 'No' );
        if ~strcmp('Yes', sBtn), return; end
        g_tWT.MovieInfo.WhiskerLabels = {};
        wt_display_frame
        return
    case 'mark' % mark new whisker label
        try [nX nY] = ginput(1); % Select initial location of label
        catch return; end % location not marked

        % Adjust coordinates if its a two-sided frame and labels for a
        % left-side whisker is being marked
        if g_tWT.MovieInfo.WhiskerSide(nWhisker) == 2
            vAxSize = get(g_tWT.FrameAx, 'XLim');
            nX = nX - vAxSize(2)/2; % only change X
        end
        
        % Iterate over frames that the whisker has been tracked
        if nWhisker > length(g_tWT.MovieInfo.WhiskerLabels) || isempty(g_tWT.MovieInfo.WhiskerLabels)
            vObjIndx = 1;
        else
            if isempty(g_tWT.MovieInfo.WhiskerLabels{nWhisker}), vObjIndx = 1; end
            vObjIndx = size(g_tWT.MovieInfo.WhiskerLabels{nWhisker}, 3) + 1;
        end
        g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame, 1:2, vObjIndx) = [nX nY];
        g_tWT.MovieInfo.WhiskerLabels{nWhisker}(g_tWT.MovieInfo.WhiskerLabels{nWhisker} == 0) = NaN; % replace zeros with NaNs
        wt_display_frame
        return
end

% If 'continue-all' was selected, find first of all last-tracked-frames for all labels
if strcmpi(sOption, 'continue-all')
    nCurrFrame = [];
    for w = 1:length(g_tWT.MovieInfo.WhiskerLabels) % iterate over whiskers
        if isempty(g_tWT.MovieInfo.WhiskerLabels{w}), continue, end
        for o = 1:size(g_tWT.MovieInfo.WhiskerLabels{w}, 3) % iterate over labels
            vIndx = find(~isnan(g_tWT.MovieInfo.WhiskerLabels{w}(:,1,o)));
            if isempty(vIndx), continue, end
            if isempty(nCurrFrame), nCurrFrame = vIndx(end); end
            if vIndx(end) < nCurrFrame, nCurrFrame = vIndx(end); end
        end
    end
end

counter = 1;
nLastFrame = g_tWT.MovieInfo.NumFrames;
g_tWT.StopProc = 0;
while nCurrFrame <= nLastFrame

    % Load frame buffer
    vBufferedFrames = (nCurrFrame+1):(nCurrFrame+g_tWT.MovieInfo.NoFramesToLoad);
    vBufferedFrames(vBufferedFrames > g_tWT.MovieInfo.NumFrames) = [];
    if isempty(vBufferedFrames), break, end
    mFrames = wt_load_avi(g_tWT.MovieInfo.Filename, vBufferedFrames); % load frame buffer
    
    for f = 1:length(vBufferedFrames) % iterate over buffered images
        
        if g_tWT.StopProc, break, end
        
        nCurrFrame = vBufferedFrames(f);
        if nCurrFrame > nLastFrame, break, end % last frame reached

        mFrame = mFrames(:,:,f);

        % Determine if head is tracked in current frame
        if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen), bHeadIsTracked = 1;
        else bHeadIsTracked = 0; end

        mFrame = wt_subtract_bg_frame(mFrame, nCurrFrame); % subtract background
        
        if bHeadIsTracked
            % Abort if head-movements are not known for the current frame
            if isnan(g_tWT.MovieInfo.Nose(nCurrFrame,1))
                sMsg = sprintf('Stopped tracking as head location is not known for current frame (%d)', nCurrFrame);
                if g_tWT.VerboseMode, wt_error(sMsg)
                else wt_set_status(sMsg), end
                g_tWT.StopProc = 1; break
            end

            % Crop frame according to head-position
            if ~isnan(g_tWT.MovieInfo.RightEye(nCurrFrame,1)) && ~isnan(g_tWT.MovieInfo.LeftEye(nCurrFrame,1))
                mImg = wt_crop_behaving_video(mFrame, ...
                    [g_tWT.MovieInfo.RightEye(nCurrFrame,:); ...
                        g_tWT.MovieInfo.LeftEye(nCurrFrame,:); ...
                        g_tWT.MovieInfo.Nose(nCurrFrame,:)] , ...
                    g_tWT.MovieInfo.HorExt, g_tWT.MovieInfo.RadExt, sMethod);
            end
            
            % Join two images
            mFrame = cat(2, mImg{1}, mImg{2});
            for f = unique(g_tWT.MovieInfo.WhiskerSide); % only process parts of frame that we need
                try [mImg{f}, VOID] = wt_image_preprocess(mImg{f});
                catch wt_error('Failed pre-processing image. Try Debug.'); end
                if g_tWT.MovieInfo.Invert == 0, mImg{f} = mImg{f} .* -1; end                
            end
        else
            % Movie with no head-movements
            try [mFrame, ~] = wt_image_preprocess(mFrame);
            catch, wt_error('Failed pre-processing image. Try Debug.'); end
            if g_tWT.MovieInfo.Invert == 1, mFrame = mFrame .* -1; end
        end

        % Manual tracking with/without deletion
        if any(strcmpi(sOption, {'manual_without_deletion' 'manual_with_deletion'}))
            % Extrapolate if required
            mXY_old = g_tWT.MovieInfo.WhiskerLabels{nWhisker}(1:nCurrFrame-1, :, vObjIndx);
            if size(mXY_old, 1) > 2 && g_tWT.MovieInfo.UsePosExtrap
                vX = round(interp1(1:size(mXY_old,1), mXY_old(:,1), size(mXY_old,1)+1, 'linear', 'extrap')); % interpolate X
                vY = round(interp1(1:size(mXY_old,1), mXY_old(:,2), size(mXY_old,1)+1, 'linear', 'extrap')); % interpolate Y
            else
                vX = round(g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame-1, 1, vObjIndx));
                vY  = round(g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame-1, 2, vObjIndx));
            end
            
            % Locate spot in processed image
            if bHeadIsTracked, mUseFrame = mImg{g_tWT.MovieInfo.WhiskerSide(nWhisker)};
            else mUseFrame = mFrame; end
            
            % If the outline LABELLIM exists, mask image
            % according to the LABELLIM ROI coords
            if isfield(g_tWT.MovieInfo, 'Outlines')
                nIndx = find(strcmp('LABELLIM', [g_tWT.MovieInfo.Outlines.Name]));
                if ~isempty(nIndx)
                    mXY = g_tWT.MovieInfo.Outlines(nIndx).Coords;
                    mMask = roipoly(mUseFrame, mXY(:,1), mXY(:,2));
                    mUseFrame(~mMask) = 0;%mUseFrame .* mMask;
                end
            end
            
            [vNewPos, nScore, nScoreStd] = wt_track_spot(mUseFrame.*-1, [vX vY], [], g_tWT.LabelFilter.Filter, 0, g_tWT.LabelFilter.Threshold);

            if isempty(vNewPos) || all(isnan(vNewPos)) % if no new position was found (e.g. user clicked too far from whisker), use position of last frame
                vNewPos = g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame-1, :, vObjIndx);
            end
            g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame, :, vObjIndx) = vNewPos;
            nButton = 1;
            while nButton == 1 % loop until user clicks right mouse-button
                %wt_display_frame(nCurrFrame, mFrame);
                wt_display_frame(nCurrFrame, mUseFrame);
                [nX, nY, nButton] = ginput(1);
                % Correct location if head is tracked and a left-side label is tracked
                if g_tWT.MovieInfo.WhiskerSide(nWhisker) == 2
                    vAxSize = get(g_tWT.FrameAx, 'XLim');
                    nX = nX - vAxSize(2)/2; % only change X
                end                
                if nButton == 1, g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame, :, vObjIndx) = [nX nY]; end
            end
            switch nButton
                case 2, g_tWT.StopProc = 1; break % exit manual mode
                case 3, continue % go to next frame
            end
        else % automatic tracking
            if strcmpi(sOption, 'continue-all') % continue tracking all labels
                for w = 1:length(g_tWT.MovieInfo.WhiskerLabels) % iterate over whiskers
                    if isempty(g_tWT.MovieInfo.WhiskerLabels{w}), continue, end
                    for o = 1:size(g_tWT.MovieInfo.WhiskerLabels{w}, 3) % iterate over labels
                        bSkip = 0;
                        if size(g_tWT.MovieInfo.WhiskerLabels{w}, 1) >= nCurrFrame
                            if all(g_tWT.MovieInfo.WhiskerLabels{w}(nCurrFrame,:,o) > 0) % skip already tracked labels
                                bSkip = 1;
                            end
                        end
                        if ~bSkip
                            % Extrapolate likely location of the label in next frame
                            mXY_old = g_tWT.MovieInfo.WhiskerLabels{w}(1:nCurrFrame-1, :, o);
                            if size(mXY_old, 1) > 2 && g_tWT.MovieInfo.UsePosExtrap
                                vX = round(interp1(1:size(mXY_old,1), mXY_old(:,1), size(mXY_old,1)+1, 'linear', 'extrap')); % interpolate X
                                vY = round(interp1(1:size(mXY_old,1), mXY_old(:,2), size(mXY_old,1)+1, 'linear', 'extrap')); % interpolate Y
                            else
                                vX = round(g_tWT.MovieInfo.WhiskerLabels{w}(nCurrFrame-1, 1, o));
                                vY = round(g_tWT.MovieInfo.WhiskerLabels{w}(nCurrFrame-1, 2, o));
                            end
                            if bHeadIsTracked, mUseFrame = mImg{g_tWT.MovieInfo.WhiskerSide(w)};
                            else mUseFrame = mFrame; end
                            
                            % If the outline LABELLIM exists, mask image
                            % according to the LABELLIM ROI coords
                            if isfield(g_tWT.MovieInfo, 'Outlines')
                                nIndx = find(strcmp('LABELLIM', [g_tWT.MovieInfo.Outlines.Name]));
                                if ~isempty(nIndx)
                                    mXY = g_tWT.MovieInfo.Outlines(nIndx).Coords;
                                    mMask = roipoly(mUseFrame, mXY(:,1), mXY(:,2));
                                    mUseFrame(~mMask) = 0;%mUseFrame .* mMask;
                                end
                            end
                            
                            [g_tWT.MovieInfo.WhiskerLabels{w}(nCurrFrame, :, o), nScore, nScoreStd] = ...
                                wt_track_spot(mUseFrame.*-1, [vX vY], [], g_tWT.LabelFilter.Filter, g_tWT.VerboseMode, g_tWT.LabelFilter.Threshold);

                            % Range limit
                            if ~RangeLimit(g_tWT.MovieInfo.WhiskerLabels{w}(nCurrFrame, :, o))
                                % Use previous frame coordinates if label fell outside LABELLIM ROI
                                if nCurrFrame > 1 % only correct 2nd frame and onwards
                                    g_tWT.MovieInfo.WhiskerLabels{w}(nCurrFrame, :, o) = ...
                                        g_tWT.MovieInfo.WhiskerLabels{w}(nCurrFrame-1, :, o);
                                end
                            end
                            
                            % Plot signal-to-noise
                            if g_tWT.ShowSR, wt_plot_signal_noise(nScore./nScoreStd); drawnow, end
                        end
                    end
                end
            else % continue tracking a single selected label
                % Extrapolate likely location of the label in next frame
                mXY_old = g_tWT.MovieInfo.WhiskerLabels{nWhisker}(1:nCurrFrame-1, :, vObjIndx);
                if size(mXY_old, 1) > 2 && g_tWT.MovieInfo.UsePosExtrap
                    vX = round(interp1(1:size(mXY_old,1), mXY_old(:,1), size(mXY_old,1)+1, 'linear', 'extrap')); % interpolate X
                    vY = round(interp1(1:size(mXY_old,1), mXY_old(:,2), size(mXY_old,1)+1, 'linear', 'extrap')); % interpolate Y
                else
                    vX = round(g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame-1, 1, vObjIndx));
                    vY = round(g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame-1, 2, vObjIndx));
                end
                if bHeadIsTracked, mUseFrame = mImg{g_tWT.MovieInfo.WhiskerSide(nWhisker)};
                else mUseFrame = mFrame; end
                if strcmpi(sOption, 'continuefixed')
                    g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame, :, vObjIndx) = ...
                        g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame-1, :, vObjIndx);
                else
                    [g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame, :, vObjIndx), nScore, nScoreStd] = ...
                        wt_track_spot(mUseFrame.*-1, [vX vY], [], g_tWT.LabelFilter.Filter, g_tWT.VerboseMode, g_tWT.LabelFilter.Threshold);
                    % Range limit
                    if ~RangeLimit(g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame, :, vObjIndx))
                        % Use previous frame coordinates if label fell outside LABELLIM ROI
                        if nCurrFrame > 1 % only correct 2nd frame and onwards
                            g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame, :, vObjIndx) = ...
                                g_tWT.MovieInfo.WhiskerLabels{nWhisker}(nCurrFrame-1, :, vObjIndx);
                        end
                    end
                    % Plot signal-to-noise
                    if g_tWT.ShowSR, wt_plot_signal_noise(nScore./nScoreStd); drawnow, end
                end
            end

            % Refresh display
            if counter == g_tWT.MovieInfo.ScreenRefresh
                %wt_display_frame(nCurrFrame, mFrame);
                wt_display_frame(nCurrFrame, mUseFrame);
                counter = 1;
            else counter = counter + 1; end

        end

    end
    if g_tWT.StopProc, break, end
end

% Replace all frames where X is zero with NaN
for w = 1:length(g_tWT.MovieInfo.WhiskerLabels)
    vIndx = find(g_tWT.MovieInfo.WhiskerLabels{w}(:) == 0);
    g_tWT.MovieInfo.WhiskerLabels{w}(vIndx) = NaN;
    % Drop labels that only contain NaNs
    vDropIndx = [];
    for o = 1:size(g_tWT.MovieInfo.WhiskerLabels{w}, 3)
        nLen = length(find(~isnan(g_tWT.MovieInfo.WhiskerLabels{w}(:,:,o))));
        if nLen == 0, vDropIndx(end+1) = o; end
    end
    g_tWT.MovieInfo.WhiskerLabels{w}(:,:,vDropIndx) = [];
end

wt_display_frame

return

% RangeLimit
% Check if point is inside LABELLIM ROI if it exists in MovieInfo.Outlines
function bIn = RangeLimit(vXY)
bIn = 1; % default
global g_tWT
if isfield(g_tWT.MovieInfo, 'Outlines')
    nIndx = find(strcmp('LABELLIM', [g_tWT.MovieInfo.Outlines.Name]));
    if ~isempty(nIndx)
        % Range limit here
        mXY = g_tWT.MovieInfo.Outlines(nIndx).Coords;
        % Determine if point is inside or outside
        bIn = inpolygon(vXY(1), vXY(2), mXY(:,1), mXY(:,2));
    end
end
return
