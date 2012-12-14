function wt_play_movie( varargin )
% WT_PLAY_MOVIE
% Play movie, optionally save movie to disk.
% Takes an optional argument, which can be the string:
%   'save'  Save animated movie to disk as AVI file

global g_tWT

if nargin == 1, sOption = varargin{1};
else sOption = []; end
bWinResized = 0;

persistent sDefAns sDefLoPass;

% Check first if AVI exists on disk
if ~exist(g_tWT.MovieInfo.Filename, 'file')
    wt_set_status('AVI file no longer exists on disk. Cannot preview this file.')
    return
end

% Set screen refresh rate
if strcmp(sOption, 'preview')
    if isempty(sDefAns) sDefAns = {'20'}; end
    % Ask for number of frames to display unless we are in batch mode
    tDBStack = dbstack;
    if ~any(strcmp({tDBStack.name}, 'wt_batch_redo'))
        sDefAns = inputdlg('Number of frames to display', 'Set frames', 1, sDefAns);
    end
    if isempty(sDefAns), return
    else
        nStep = round(g_tWT.MovieInfo.NumFrames / str2num(sDefAns{1}));
    end
else
    nStep = g_tWT.MovieInfo.ScreenRefresh;
end

clear mex

% Determine frames to play
nFirstFrame = round(get(g_tWT.Handles.hSlider, 'Value'));
if isempty(g_tWT.MovieInfo.EyeNoseAxLen) % no head movements
    vFrames = nFirstFrame:nStep:g_tWT.MovieInfo.NumFrames;
else    % with head movements
    vHeadFrames = find(~isnan(g_tWT.MovieInfo.Nose(:,1)));
    nFirstFrame = max([vHeadFrames(1) nFirstFrame]);
    vFrames = nFirstFrame:nStep:vHeadFrames(end);
end

% If head movements have been tracked, ask if movie should be played in
% head-centered or video coordinates
if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen)
    sCoordinates = questdlg('Do you want the movie to played in head-centered coordinates (faster) or world coordinates (slower)?', 'Select coordinate system', 'Head-centered', 'World', 'Cancel', 'Head-centered');
    switch sCoordinates
        case 'Head-centered'
            g_tWT.DisplayMode = 1;
            set(findobj('Label', 'Toggle viewing mode'), 'checked', 'on');
        case 'World'
            g_tWT.DisplayMode = 0;
            set(findobj('Label', 'Toggle viewing mode'), 'checked', 'off');
        case 'Cancel', return;
    end
end

% Use blank frame if 'Hide Image' was selected
if g_tWT.HideImage
    vX = get(g_tWT.FrameAx,'Xlim');
    vY = get(g_tWT.FrameAx,'Ylim');
    mImgZeros = zeros(vY(2), vX(2));
else mImgZeros = []; end

% Prepare for saving
sLastFrame = {'-1'};
if strcmp(sOption, 'save')
    % Output destination
    [sFilename, sFilepath] = uiputfile('*.avi', 'Save movie as');
    if ~sFilename, return; end

    % Compressor
    sCompressor = questdlg('Select video compression method', 'Select compressor', 'None','Indeo5', 'Cinepak', 'None');

    % Create AVI stream
    tMov = avifile([sFilepath sFilename], ...
        'Compression', sCompressor, ...
        'Fps', g_tWT.MovieInfo.FramesPerSecond, ... % save at original framerate
        'Quality', 80 );

    % Ask for end frame
    while ~(str2num(sLastFrame{1}) > nFirstFrame)
        sLastFrame = inputdlg('Last frame (must be higher than current frame)', 'Last frame');
        if isempty(sLastFrame), return, end
    end
    if isempty(sLastFrame), return, end

    nFs = g_tWT.MovieInfo.FramesPerSecond;
    
    % First frame
    nFirstFrameSec = (nFirstFrame / nFs); % s

    % Last frame
    nLastFrame = str2num(char(sLastFrame));
    nLastFrameSec = (nLastFrame / nFs); % s
    
    
    vFrames = vFrames(1):min([nLastFrame vFrames(end)]);
    sAnsTraces = questdlg('Do you want to create a movie that includes traces of whisker angle? Note that as the movie is created, MATLAB will cycle between two windows causing a lot of flicker. This is OK. Dont close or move any windows (including non-MATLAB windows) as the movie is being generated.', 'WT', 'Yes', 'No', 'Yes');
end

if g_tWT.MovieInfo.EyeNoseAxLen, bHeadIsTracked = 1;
else bHeadIsTracked = 0; end

if bHeadIsTracked
    sAnsBackG = questdlg('Do you want to subtract background?', 'WT', 'Yes', 'No', 'No');
    if ~g_tWT.DisplayMode
        sAnsHead = questdlg('Do you want to remove head markers?', 'WT', 'Yes', 'No', 'No');
    else sAnsHead = 'Yes'; end
else
    sAnsBackG = 'No';
    sAnsHead = 'Yes';
end

i = 1;
g_tWT.StopProc = 0;
r = 1;

if strcmp(sOption, 'save')
    wt_set_status('Saving frames. Do not close window. Click || button to abort.')
    
    % Prepare new figure window that contains trace+frame
    if strcmp(sAnsTraces, 'Yes')
        hNewFig = figure('color', 'w');
        vPos = get(hNewFig, 'position');
        set(hNewFig, 'position', [vPos(1:2) 600 450], 'renderer', 'OpenGL')

        % Movie panel
        hAngAx = axes('position', [.15 .1 .7 .3], 'fontsize', 7);
        nTraces = size(g_tWT.MovieInfo.Angle, 2);
        nEvents = 2; % number of event channels (A and B)
        % Draw patches representing events
        vStimA = g_tWT.MovieInfo.StimulusA;
        vStimB = g_tWT.MovieInfo.StimulusB;
        % Stim A
        axes(hAngAx); hold on
        vIndxAStart = find(diff(vStimA) == 1);
        vIndxAEnd = find(diff(vStimA) == -1);
        for p = 1:min(length(vIndxAStart), length(vIndxAEnd))
            nS = vIndxAStart(p) / nFs; % s
            nE = vIndxAEnd(p) / nFs; % s
            hP = patch([nS nS nE nE nS], [-360 360 360 -360 -360], 'r');
            set(hP, 'edgeColor', 'none', 'faceColor', 'r', 'faceAlpha', .5)
        end
        % Stim B
        vIndxAStart = find(diff(vStimB) == 1);
        vIndxAEnd = find(diff(vStimB) == -1);
        for p = 1:min(length(vIndxAStart), length(vIndxAEnd))
            nS = vIndxAStart(p) / nFs;
            nE = vIndxAEnd(p) / nFs;
            hP = patch([nS nS nE nE nS], [-360 360 360 -360 -360], 'b');
            set(hP, 'edgeColor', 'none', 'faceColor', 'b', 'faceAlpha', .5)
        end
        
        hLines = plot(hAngAx, zeros(2, nTraces), zeros(2, nTraces));
        colormap gray

        hMovPan = uipanel('BorderType', 'none',...
            'Units', 'normalized', ...
            'Position', [0 .35 1 .65], ...
            'Parent', hNewFig, ...
            'backgroundColor', 'w' );
        
        % Re-compute whisker angle is computed
        %wt_compute_kinematics('angle', 0);
        mAngle = g_tWT.MovieInfo.Angle;
        
        % Low-pass filter angle
        if isempty(sDefLoPass) sDefLoPass = '80'; end
        sAns = inputdlg('Enter low-pass filter (in Hz) to be applied to angle traces', ...
            'Low-pass filter', 1, {sDefLoPass});
        if isempty(sAns{1}), return, end
        sDefLoPass = sAns{1};
        nLoPass = str2num(sDefLoPass);

        [a,b] = butter(3, nLoPass/(nFs/2), 'low');
        for i = 1:size(mAngle, 2)
            vSeriesIn = mAngle(:,i);
            vFiltSrsIndx = find(~isnan(vSeriesIn));
            vFiltSeries = vSeriesIn(vFiltSrsIndx);
            vSeriesOut = zeros(size(vSeriesIn))*NaN;
            vSeriesOut(vFiltSrsIndx) = filtfilt(a, b, vFiltSeries);
            mAngle(:,i) = vSeriesOut;
        end
        
        nYMin = min(min(g_tWT.MovieInfo.Angle(nFirstFrame:nLastFrame,:))); % min in range
        nYMax = max(max(g_tWT.MovieInfo.Angle(nFirstFrame:nLastFrame,:))); % max in range
        
    end
end

for r = 1:g_tWT.MovieInfo.NoFramesToLoad:length(vFrames)
    nEnd = min([length(vFrames) r+g_tWT.MovieInfo.NoFramesToLoad]);
    vLoadFrames = vFrames(r:nEnd);
    wt_set_status(['Loading next set of ' num2str(g_tWT.MovieInfo.NoFramesToLoad) ' frames...'])
    mFrames = wt_load_avi(g_tWT.MovieInfo.Filename, vLoadFrames);
    wt_set_status('')

    wt_set_status(['Press spacebar to stop'])
    for f = 1:g_tWT.MovieInfo.ScreenRefresh:length(vLoadFrames)
        if g_tWT.StopProc, break, end

        if strcmp(sAnsBackG, 'Yes') % subtract background
            mImg = wt_subtract_bg_frame(mFrames(:,:,f), vLoadFrames(f));
        else
            mImg = mFrames(:,:,f);
        end
        mImg = wt_image_preprocess(mImg); % rotate, crop etc
        
        % Pre-process frame if there is head-movements data
        if bHeadIsTracked && g_tWT.DisplayMode
            mImg = wt_crop_behaving_video(mImg, ...
                [g_tWT.MovieInfo.RightEye(vLoadFrames(f),:); g_tWT.MovieInfo.LeftEye(vLoadFrames(f),:); g_tWT.MovieInfo.Nose(vLoadFrames(f),:)] , ...
                g_tWT.MovieInfo.HorExt, g_tWT.MovieInfo.RadExt, 'nearest');
            mImg = cat(2, mImg{1}, mImg{2});
        end
        
        % Display frame
        if ~isempty(mImgZeros)  % show blank background
            wt_display_frame(vLoadFrames(f), mImgZeros);
        elseif ~bHeadIsTracked  % show image without head movements
            wt_display_frame(vLoadFrames(f), mImg)
        else                    % show image with head movements
            if strcmp(sAnsHead, 'Yes')
                wt_display_frame(vLoadFrames(f), mImg, 0, 'nohead'); % head markers
            else
                wt_display_frame(vLoadFrames(f), mImg); % no head markers
            end
        end
        drawnow
        
        % Store frame (for saving later)
        if strcmp(sOption, 'save')
            if strcmp(sAnsTraces, 'Yes') % grab frame with angles
                hNewFrameAx = copyobj(g_tWT.FrameAx, hMovPan); % Copy frame
                % If this is first frame, hold with an open modal box and
                % allow user to resize window
                if ~bWinResized
                    vXlim = get(hNewFrameAx, 'xlim');
                    vYlim = get(hNewFrameAx, 'ylim');
                    % Ask first whether an ROI should be applied to the
                    % image
                    sAns = questdlg('Do you want to crop the image?', 'WT Crop', 'Yes', 'No', 'No');
                    if strcmp(sAns, 'Yes')
                        axes(hNewFrameAx)
                        while 1
                            set(hNewFrameAx, 'xlim', vXlim, 'ylim', vYlim)
                            vP = ginput(2);
                            vP1 = vP(1,:);
                            vP2 = vP(2,:);
                            set(hNewFrameAx, 'xlim', [vP1(1), vP2(1)], 'ylim', [vP1(2), vP2(2)])
                            sAns = questdlg('Happy?', 'Crop', 'Yes', 'No', 'Yes');
                            if strcmp(sAns, 'Yes') break, end
                        end
                        vXlim = [vP1(1), vP2(1)];
                        vYlim = [vP1(2), vP2(2)];
                        set(hNewFrameAx, 'xlim', vXlim, 'ylim', vYlim)
                    end
                    uiwait(msgbox('Resize the preview window so that video frame and subplot for angles fit your taste. Close this dialog to resume saving.', 'Save WT Movie'));
                    bWinResized = 1;
                end
                axes(hAngAx)
                % Re-draw angle
                for l = 1:length(hLines)
                    vX = ([1:vLoadFrames(f)] ./ nFs); % s
                    set(hLines(l), 'xdata', vX, 'ydata', ...
                        mAngle(1:vLoadFrames(f), l) ) ;
                end
                nStartAx = floor(nFirstFrameSec*10)/10;
                nEndAx = ceil(nLastFrameSec*10)/10;
                set(hAngAx, 'xlim', [nStartAx nEndAx], 'ylim', [nYMin-2 nYMax+2])
                set(hNewFrameAx, 'xlim', vXlim, 'ylim', vYlim);
                xlabel('Time (s)'); ylabel('Angle (deg)')
                drawnow
                mF = getframe(hNewFig); % grab frame
                tMov = addframe(tMov, mF);
                cla(hNewFrameAx)
            else % grab frame without angles
                mF = getframe(g_tWT.FrameAx);
            end
            tMov = addframe(tMov, mF);
            i = i + 1;
        end
        
        % Pause briefly if we are in preview mode
        if strcmp(sOption, 'preview')
            pause(0.2);
        end
    
    end
    wt_set_status([''])
    if g_tWT.StopProc, break, end
end
wt_set_status([''])

% Open window for re-playing and saving movie
if strcmp(sOption, 'save')
    if strcmp(sAnsTraces, 'Yes'), close(hNewFig), end
    wt_set_status('')
    tMov = close(tMov);
end

return
