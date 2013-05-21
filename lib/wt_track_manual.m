function nNewFrame = wt_track_manual(varargin)
% wt_track_manual(I)
%   Track whisker manually where I is the index of the whisker to track.
%

global g_tWT

% Check that file is loaded and that file is found on disk
if ~exist(g_tWT.MovieInfo.Filename, 'file')
    wt_set_status('Warning: Cannot locate movie file.')
    return;
end

if ~g_tWT.DisplayMode, wt_toggle_display_mode, end

% Options
sOptions = [];
if nargin == 2, sOptions = varargin{2}; end

% Check that at least one whisker has been marked. If not, return.
if isempty(g_tWT.MovieInfo.SplinePoints)
    sErrString = 'No whiskers have yet been marked. Mark a whisker from Whiskers->Mark new and try again.';
    errordlg (sErrString); error(sErrString); return;
end

% Current frame
nFirstFrame = round(get(g_tWT.Handles.hSlider, 'Value'));
nChWhisker = varargin{1};

% Range of frames
vDoFrames = nFirstFrame:g_tWT.MovieInfo.NumFrames;

hFrameWin = findobj('Tag', 'WTMainWindow');

if strcmp(sOptions, 'without_deletion')
    set(hFrameWin, 'color', [1 .5 0])
else
    % Warn that data will be deleted (if there's anything to delete...)
    if size(g_tWT.MovieInfo.SplinePoints, 3) > nFirstFrame
        sAnsw = questdlg('Data forward in time will be deleted. Ok?', 'Warning', 'Ok', 'Cancel', 'Cancel');
        if strcmp(sAnsw, 'Cancel'), return; end
        % Delete current results
        g_tWT.MovieInfo.SplinePoints(:, :, nFirstFrame+1:end, nChWhisker) = ...
            zeros(size(g_tWT.MovieInfo.SplinePoints(:,:,nFirstFrame+1:end,nChWhisker)));
        g_tWT.MovieInfo.Angle(nFirstFrame+1:end, nChWhisker) = 0;
    end
    set(hFrameWin, 'color', 'red') % change figure background    
end
set(g_tWT.Handles.hSlider,'visible','off') % disable slider temporarily
g_tWT.StopProc = 0;

% Create filters
if isempty(g_tWT.FiltVec)
    g_tWT.FiltVec = wt_create_filters(g_tWT.MovieInfo.WhiskerWidth, g_tWT.MovieInfo.FilterLen); 
end

% Iterate over all frames from current frame until user requests to resume
% to full automatic tracking
vAxSize = get(g_tWT.FrameAx, 'XLim');
for nFrame = vDoFrames(1):g_tWT.MovieInfo.NoFramesToLoad:vDoFrames(end)
    % Buffer frames
    nLastFrame = (nFrame+g_tWT.MovieInfo.NoFramesToLoad)-1;
    if nLastFrame > g_tWT.MovieInfo.NumFrames, nLastFrame = g_tWT.MovieInfo.NumFrames; end        
    vLoadFrames = nFrame:nLastFrame;
    if isempty(g_tWT.MovieInfo.FilenameUncompressed)
        mFrames = wt_load_avi(g_tWT.MovieInfo.Filename, vLoadFrames);
    else
        mFrames = wt_load_avi(g_tWT.MovieInfo.FilenameUncompressed, vLoadFrames);
    end

    % Iterate over frames
    for f = 1:size(mFrames, 3)
        if g_tWT.StopProc, break, end % stop tracking if user clicks on the Play/> button
        nCurrentFrame = vLoadFrames(f);
        if nCurrentFrame > g_tWT.MovieInfo.LastFrame(nChWhisker) % stop tracking if past last frame
            nBtn = 2; % stop tracking as if user has clicked on the Play/> button
            break;
        end
        mImg = mFrames(:,:,f);
        g_tWT.CurrentFrameBuffer.Img = mImg;
        g_tWT.CurrentFrameBuffer.Frame = nCurrentFrame;

        % Subtract background frame
        mImg = wt_subtract_bg_frame(mImg, nCurrentFrame);          
        
        % Determine if head is tracked in current frame
        if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen), bHeadIsTracked = 1;
        else, bHeadIsTracked = 0; end
        
        % Pre-process frame
        if bHeadIsTracked
            % Abort if head-movements are not known for the current frame
            if isnan(g_tWT.MovieInfo.Nose(nCurrentFrame,1))
                wt_set_status(sprintf('Stopped tracking as head location is not known for current frame (%d)', nCurrentFrame))
                set(hFrameWin, 'color', [.8 .8 .8])
                return;
            end
            
            % Pre-process image (crop, rotate & invert)
            [mImg, VOID] = wt_image_preprocess(mImg);
            
            % Movie with head-movements recorded
            if ~isnan(g_tWT.MovieInfo.RightEye(nCurrentFrame,1)) & ~isnan(g_tWT.MovieInfo.LeftEye(nCurrentFrame,1))
                mImg = wt_crop_behaving_video(mImg, ...
                    [g_tWT.MovieInfo.RightEye(nCurrentFrame,:); ...
                        g_tWT.MovieInfo.LeftEye(nCurrentFrame,:); ...
                        g_tWT.MovieInfo.Nose(nCurrentFrame,:)] , ...
                    g_tWT.MovieInfo.HorExt, g_tWT.MovieInfo.RadExt, 'nearest');
            end
            
            mImgCroppedOnly = cat(2, mImg{1}, mImg{2});
            mImg = mImg{g_tWT.MovieInfo.WhiskerSide(nChWhisker)};
            
            %try, [mImg, VOID] = wt_image_preprocess(mImg{g_tWT.MovieInfo.WhiskerSide(nChWhisker)});
            %catch, wt_error('Failed pre-processing image.'); end
        else
            % Movie with no head-movements
            try, [mImg, mImgCroppedOnly] = wt_image_preprocess(mImg);
            catch, wt_error(sprintf('Failed pre-processing image: %s', lasterr)); end
        end

        % Locate next whisker
        if (nFirstFrame == 1), nPreviousFrame = 1;
        elseif (nCurrentFrame == nFirstFrame), nPreviousFrame = nFirstFrame;
        else, nPreviousFrame = nCurrentFrame - 1; end
        
        [nScore, nScoreStd, nScoreN] = wt_find_next_whisker(nChWhisker, nCurrentFrame, nPreviousFrame, mImg, 'fast');

        % Refresh display
        wt_display_frame(nCurrentFrame, mImgCroppedOnly, nChWhisker);

        % Plot signal-to-noise
        if g_tWT.ShowSR, wt_plot_signal_noise(nScore./nScoreStd), g_tWT.StopProc = 0; end

        % Allow user to move any point
        while 1
            try
                [nX, nY, nBtn] = ginput(1);  % user may hit RETURN if he does not want to input data
            catch
                nBtn = 2; % no input data, treat as if middle button hit
            end
            if isempty(nBtn) nBtn = 2; end % no input
            if nBtn >= 2 break; end % go to next frame when middle or right mousebutton is clicked        

            % Get current coordinates in frame
            vX = g_tWT.MovieInfo.SplinePoints(:,1,nCurrentFrame,nChWhisker);

            % Correct vX for whiskers on right side in behaving vids
            if g_tWT.MovieInfo.WhiskerSide(nChWhisker) == 2, nX = nX - vAxSize(2)/2; end            
            vY = g_tWT.MovieInfo.SplinePoints(:,2,nCurrentFrame,nChWhisker);
            [y, nIndx] = min(sqrt(abs(vX-nX).^2 + abs(vY-nY).^2)); % locate closest point

            mSplinePoints = g_tWT.MovieInfo.SplinePoints(:,:,nCurrentFrame,nChWhisker);
            switch nIndx % Exchange points
                case 1
                    mSplinePoints(1,:) = round([vX(1) nY]);
                case 2
                    if length(vX)==4 % swap mid-points if necessary
                        if nX > vX(3)
                            mSplinePoints(3,:) = round([nX nY]);
                            mSplinePoints(2,:) = [mSplinePoints(3,1)-1 mSplinePoints(3,2)];
                        else
                            mSplinePoints(2,:) = round([nX nY]);
                        end
                    else
                        mSplinePoints(2,:) = round([nX nY]);
                    end
                case 3
                    if length(vX)==4 % swap mid-points if necessary
                        if nX < vX(2)
                            mSplinePoints(2,:) = round([nX nY]);
                            mSplinePoints(3,:) = mSplinePoints(2,:);
                        else
                            mSplinePoints(3,:) = round([nX nY]);
                        end
                    else
                        mSplinePoints(3,:) = round([vX(3) nY]);
                    end
                case 4
                    mSplinePoints(4,:) = round([vX(4) nY]);       
            end

            % Adjust length of new spline
            [mSplinePoints(:,1), mSplinePoints(:,2)] = wt_adjust_whisker_length(nChWhisker, mSplinePoints(:,1), mSplinePoints(:,2));            

            % Update t_gMovieInfo.SplinePoints
            g_tWT.MovieInfo.SplinePoints(:, :, nCurrentFrame, nChWhisker) = round(mSplinePoints);

            % Redraw whisker
            wt_draw_whisker(nChWhisker, nCurrentFrame, 'nomenu')

        end
        if nBtn == 2 break; end % stop tracking if middle mousebutton is clicked
    end
    if nBtn == 2 break; end % stop tracking if middle mousebutton is clicked
end

% Reset display
wt_prep_gui;
wt_display_frame

return;
