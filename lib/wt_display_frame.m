function wt_display_frame( varargin )
% wt_display_frame
% Refresh or display new video-frame.
%
% Input parameters:
%   Framenumber
%   Preprocessed image (optional)
%   Whisker to color (the others will be in black;
%       must be 0 if 4th parameters is given)
%   String option (optional), any of:
%           nohead - don't plot head markers
%

global g_tWT
if isempty(g_tWT) return; end

persistent nCurrentFrame % NOTE: is emptied when this file is changed!!!
if isempty(nCurrentFrame), nCurrentFrame = 1; end % show 1st frame by default
if ~isempty(varargin), nCurrentFrame = varargin{1}; end

if (nCurrentFrame > g_tWT.MovieInfo.NumFrames) || (nCurrentFrame < 0)
    wt_error('Requested frame is out of range.')
elseif isempty(nCurrentFrame)
    wt_error('Invalid frame request (did you enter a letter?)')
end

% Get frame image object handle
hImg = findobj(g_tWT.FrameAx, 'Type', 'image');

% Check if head has been tracked in this movie
if g_tWT.MovieInfo.EyeNoseAxLen, bHeadIsTracked = 1; else bHeadIsTracked = 0; end

% Chosen whisker: if given, this whisker will be plotted in color and others in black.
if nargin == 3, nChWhisker = varargin{3};
else nChWhisker = 0; end

% String option
if nargin == 4, sOption = varargin{4};
else sOption = ''; end

% Display current frame
if length(varargin) >= 2
    mFrame = varargin{2}; % use passed image as current frame (no need to crop etc)
else
    % Use buffered image if only refreshing frame, otherwise load new from disk.
    if nargin == 0 && g_tWT.CurrentFrameBuffer.Frame == nCurrentFrame && ~isempty(g_tWT.CurrentFrameBuffer.Img)
        mFrame = g_tWT.CurrentFrameBuffer.Img;
    else
        if isempty(g_tWT.MovieInfo.FilenameUncompressed)
            % Check if AVI exists
            if exist(g_tWT.MovieInfo.Filename, 'file')
                mFrame = wt_load_avi(g_tWT.MovieInfo.Filename, nCurrentFrame);
            else
                if isempty(g_tWT.CurrentFrameBuffer.Img)
                    mFrame = zeros(g_tWT.MovieInfo.Width, g_tWT.MovieInfo.Height);
                else
                    mFrame = g_tWT.CurrentFrameBuffer.Img;
                end
                wt_set_status('AVI file does not exist on disk. Displaying frame buffer.')
            end
        else
            mFrame = wt_load_avi(g_tWT.MovieInfo.FilenameUncompressed, nCurrentFrame);
        end
        g_tWT.CurrentFrameBuffer.Img = mFrame;
        g_tWT.CurrentFrameBuffer.Frame = nCurrentFrame;
    end

    % Check if this is a behaving video
    if bHeadIsTracked
        % Rotate frame
        mFrame = imrotate(mFrame, g_tWT.MovieInfo.Rot, 'bicubic'); % Rotate image
        if g_tWT.MovieInfo.Flip(1), mFrame = flipud(mFrame); end % Flip Up-Down
        if g_tWT.MovieInfo.Flip(2), mFrame = fliplr(mFrame); end % Flip Left-Right
        
        % Pre-process frame if there is head-movements data
        if ~isempty(g_tWT.MovieInfo.Nose(nCurrentFrame,:)) ...
                && ~isnan(prod(g_tWT.MovieInfo.Nose(nCurrentFrame,:))) ...
                && g_tWT.DisplayMode
            mFrame = wt_crop_behaving_video(mFrame, ...
                [g_tWT.MovieInfo.RightEye(nCurrentFrame,:); g_tWT.MovieInfo.LeftEye(nCurrentFrame,:); g_tWT.MovieInfo.Nose(nCurrentFrame,:)] , ...
                g_tWT.MovieInfo.HorExt, g_tWT.MovieInfo.RadExt, 'nearest');
            mFrame = cat(2, mFrame{1}, mFrame{2});
        end
    else
        % Movie without head-movements recorded
        if ~isempty(g_tWT.MovieInfo.Roi) % Crop image
            vXX = round(g_tWT.MovieInfo.Roi(2) ...
                :  min([size(mFrame,1) (g_tWT.MovieInfo.Roi(2)+g_tWT.MovieInfo.Roi(4))])  );
            vYY = round( g_tWT.MovieInfo.Roi(1) ...
                : min([size(mFrame,2) (g_tWT.MovieInfo.Roi(1)+g_tWT.MovieInfo.Roi(3))]) );
            mFrame = mFrame(vXX, vYY, :);
        end
        mFrame = imrotate(mFrame, g_tWT.MovieInfo.Rot, 'bicubic'); % Rotate image
        if g_tWT.MovieInfo.Flip(1), mFrame = flipud(mFrame); end % Flip Up-Down
        if g_tWT.MovieInfo.Flip(2), mFrame = fliplr(mFrame); end % Flip Left-Right        
    end
end

%axes(g_tWT.FrameAx)

% Update image axes with new video frame (or blank)
if g_tWT.HideImage
    if isempty(hImg)
        %hImage = imagesc(ones(size(mFrame)), 'parent', g_tWT.FrameAx);
        hImage = imshow(ones(size(mFrame)), 'parent', g_tWT.FrameAx, ...
            'InitialMagnification', 'fit', 'Border', 'loose');
        colormap('gray');
    else
        set(hImg, 'cdata', ones(size(mFrame)));
    end
else
    if isempty(hImg)
        %hImage = imagesc(mFrame, 'parent', g_tWT.FrameAx);
        hImage = imshow(uint8(mFrame), 'parent', g_tWT.FrameAx, ...
            'InitialMagnification', 'fit', 'Border', 'loose');
        colormap('gray');
        vImgSize = size(get(hImage, 'cdata'));
    else
        set(hImg, 'cdata', mFrame);
        % Set axis to real-size
        vImgSize = size(get(hImg, 'cdata'));
    end
end

% Plot whiskers
%axes(g_tWT.FrameAx);
hold(g_tWT.FrameAx, 'on');
if ~isempty(g_tWT.MovieInfo.SplinePoints)
    for w = 1:size(g_tWT.MovieInfo.SplinePoints, 4)
        try
            wt_draw_whisker(w, nCurrentFrame);
        end
        wt_draw_whisker_label(w, nCurrentFrame);
    end
end
hold off;

% Plot outlines
%axes(g_tWT.FrameAx); hold on
hold(g_tWT.FrameAx, 'on');
if isfield(g_tWT.MovieInfo, 'Outlines')
    for o = 1:length(g_tWT.MovieInfo.Outlines)
        wt_create_outline('draw', o);
    end
end
hold off

% If display mode is 0 (i.e. in absolute mode) then also plot eyes and nose
hHead = findobj('Tag','head-triangle');
if ~g_tWT.DisplayMode && bHeadIsTracked && ~strcmp(sOption, 'nohead')
    mHead = [ g_tWT.MovieInfo.RightEye(nCurrentFrame, :)
        g_tWT.MovieInfo.LeftEye(nCurrentFrame, :)
        g_tWT.MovieInfo.Nose(nCurrentFrame, :) ];
    if isempty(hHead)
        hold on
        hLin = plot(g_tWT.FrameAx, [mHead(:,1);mHead(1,1)], [mHead(:,2);mHead(1,2)]);
        set(hLin, 'Marker', 'o', 'MarkerfaceColor', 'r', 'Color', 'g', 'MarkeredgeColor', 'r', 'Tag', 'head-triangle')
    else
        set(hHead, 'xdata', [mHead(:,1);mHead(1,1)], 'ydata', [mHead(:,2);mHead(1,2)], 'Tag', 'head-triangle')
    end
else delete(hHead), end

% Draw line that goes parallel to snout
if ~isempty(g_tWT.MovieInfo.RefLine)
    hObj = findobj(g_tWT.FrameAx, 'Tag', 'reference_line');
    if isempty(hObj)    % plot reference lince if it hasn't already been
        %axes(g_tWT.FrameAx);
        vLine = interp1(g_tWT.MovieInfo.RefLine(:,2), g_tWT.MovieInfo.RefLine(:,1), 1:size(mFrame,1), 'linear', 'extrap');
        hold on;
        hLine = plot(g_tWT.FrameAx, vLine, 1:size(mFrame,1), 'r', 'linewidth', 1);
        set(hLine, 'Tag', 'reference_line')
        hDot = [];
        hDot(1) = plot(g_tWT.FrameAx, g_tWT.MovieInfo.RefLine(1,1), g_tWT.MovieInfo.RefLine(1,2), '.', 'color', 'red', 'markersize', 18);
        hDot(2) = plot(g_tWT.FrameAx, g_tWT.MovieInfo.RefLine(2,1), g_tWT.MovieInfo.RefLine(2,2), '.', 'color', 'red', 'markersize', 18);
        set(hDot, 'Tag', 'reference_line')
        hTxt = [];
        hTxt(1) = text(g_tWT.MovieInfo.RefLine(1,1), g_tWT.MovieInfo.RefLine(1,2), ' A', 'color', 'red', ...
            'fontweight', 'bold', 'fontsize', 12, 'parent', g_tWT.FrameAx);
        hTxt(2) = text(g_tWT.MovieInfo.RefLine(2,1), g_tWT.MovieInfo.RefLine(2,2), ' B', 'color', 'red', ...
            'fontweight', 'bold', 'fontsize', 12, 'parent', g_tWT.FrameAx);
        set(hTxt, 'Tag', 'reference_line')
    end
end

% Place text that marks direction
%if g_tWT.MovieInfo.Invert, vTextColor = [1 1 1];
%else vTextColor = [0 0 0]; end
%hTxtDir = findobj(g_tWT.FrameAx, 'Type', 'text', 'tag', 'antpost');
%if ~bHeadIsTracked
%    if isempty(hTxtDir)
%        hTxtDir = text(size(mFrame,2)/2, size(mFrame,1)-4, 'Nose', 'parent', g_tWT.FrameAx);
%    end
%    set(hTxtDir, 'color', vTextColor, ...
%        'fontsize', 10, ...
%        'horizontalalignment', 'center', ...
%        'fontweight', 'bold', ...
%        'tag', 'antpost' )
%else
%    % If head is tracked, show instead strings that indicate left and right
%    % side of rat's head
%    if g_tWT.DisplayMode
%        hTxtSide = findobj(g_tWT.FrameAx, 'Type', 'text', 'tag', 'side');
%        delete(hTxtSide);
%        hTxtSide = text([size(mFrame,2)/2-5 size(mFrame,2)-5], [10 10], {'R' 'L'}, 'parent', g_tWT.FrameAx);
%        set(hTxtSide(:), 'color', vTextColor, ...
%            'fontsize', 16, ...
%            'horizontalalignment', 'right', ...
%            'fontweight', 'bold', 'tag', 'side')    
%    end
%end

% Text above image
sFilename = g_tWT.MovieInfo.Filename;
vIndx = [strfind(sFilename, '\') strfind(sFilename, '/')];
sFilename = sFilename(max(vIndx)+1:end);
hTxtHeader = findobj(g_tWT.FrameAx, 'Type', 'text', 'tag', 'movieandframe');
sStr = sprintf('%s    Frame: %d/%d (%.1f FPS)', sFilename, ...
    round(nCurrentFrame), g_tWT.MovieInfo.NumFrames, g_tWT.MovieInfo.FramesPerSecond);
wt_set_status(sStr);
%if isempty(hTxtHeader)
%    hTxtHeader = text(1, -5, sStr, ...
%        'FontSize', 8, ...
%        'FontWeight', 'normal', ...
%        'Interpreter', 'none', ...
%        'parent', g_tWT.FrameAx, ...
%        'Tag', 'movieandframe' );
%else
%    set(hTxtHeader, 'string', sprintf('%s    Frame: %d/%d (%.1f FPS)', sFilename, ...
%        round(nCurrentFrame), g_tWT.MovieInfo.NumFrames, g_tWT.MovieInfo.FramesPerSecond))
%end

% Trigger overlays
if g_tWT.TriggerOverlays
    nW = 10; % width
    nH = 10; % height
    vX = get(g_tWT.FrameAx, 'xlim');
    vY = get(g_tWT.FrameAx, 'ylim');
    % Overlay location
    switch g_tWT.OverlayLocation
        case 'UpperLeft'
            nX = 1; nY = 1;
        case 'UpperRight'
            nX = vX(2) - nW*2;
            nY = 1;
        case 'LowerLeft'
            nX = 1;
            nY = vY(2) - nH;
        case 'LowerRight'
            nX = vX(2) - nW*2;
            nY = vY(2) - nH;
    end
    
    if ~isempty(g_tWT.MovieInfo.StimulusA)
        % Get color
        if length(g_tWT.MovieInfo.StimulusA) < nCurrentFrame
            sCol = 'k';
        elseif g_tWT.MovieInfo.StimulusA(nCurrentFrame)
            sCol = 'w';
        else
            sCol = 'k';
        end
        hFill = findobj('Tag', 'StimulusAOverlay');
        % Update color
        if isempty(hFill)
            hold on
            hFill = fill([nX nX+nW nX+nW nX], [nY nY nY+nH nY+nH], sCol);
            set(hFill, 'Tag', 'StimulusAOverlay', 'EdgeColor', 'none')
        else
            set(hFill, 'FaceColor', sCol, 'xdata', [nX nX+nW nX+nW nX], 'ydata', [nY nY nY+nH nY+nH])
        end
    end
    if ~isempty(g_tWT.MovieInfo.StimulusB)
        % Get color
        if g_tWT.MovieInfo.StimulusB(nCurrentFrame), sCol = 'w';
        else sCol = 'k'; end
        hFill = findobj('Tag', 'StimulusBOverlay');
        % Update color
        if isempty(hFill)
            hold on
            hFill = fill([nX+nW nX+nW*2 nX+nW*2 nX+nW], [nY nY nY+nH nY+nH], sCol);
            set(hFill, 'Tag', 'StimulusBOverlay', 'EdgeColor', 'none')
        else
            set(hFill, 'FaceColor', sCol, 'xdata', [nX+nW nX+nW*2 nX+nW*2 nX+nW], 'ydata', [nY nY nY+nH nY+nH])
        end
    end
else
    % Find and delete existing trigger overlays
    hFill = findobj('Tag', 'StimulusAOverlay');
    if ~isempty(hFill), delete(hFill); end
    hFill = findobj('Tag', 'StimulusBOverlay');
    if ~isempty(hFill), delete(hFill); end
end

% Update slider
if isempty(g_tWT.Handles.hSlider)
    g_tWT.Handles.hSlider = uicontrol(g_tWT.WTWindow, 'style', 'slider');
    set(g_tWT.Handles.hSlider, 'units', 'normalized' ...
        , 'Position', [.05 .025 .83 .03] ... % fig opos = .05 .05 .9 .9
        , 'Style', 'slider' ...
        , 'Min', 1 ...
        , 'CallBack', 'global g_tWT; set(g_tWT.Handles.hSlider, ''Value'', round(get(g_tWT.Handles.hSlider, ''Value''))); wt_display_frame(get(g_tWT.Handles.hSlider, ''Value''))' );
    % Slider height is fixed in pixels
    set(g_tWT.Handles.hSlider, 'units', 'pixels');
    vPos = get(g_tWT.Handles.hSlider, 'position');
    set(g_tWT.Handles.hSlider, 'Position', [vPos(1) 20 vPos(3) 17]);
end

set(g_tWT.Handles.hSlider, 'Max', g_tWT.MovieInfo.NumFrames ...
    , 'SliderStep', [1/g_tWT.MovieInfo.NumFrames 10/1/g_tWT.MovieInfo.NumFrames] ...
    , 'Value', nCurrentFrame );
hold on

% Update vertical slider in traces plots
hMarkers = findobj('tag','framemarker');
set(hMarkers, 'xdata', [nCurrentFrame nCurrentFrame].*(1000/g_tWT.MovieInfo.FramesPerSecond) ...
    , 'ydata', [-.5 1.5])

% Set image and axis properties
try set(hImage, 'HitTest', 'Off'); end
%vXlim = get(g_tWT.FrameAx, 'xlim');
%vYlim = get(g_tWT.FrameAx, 'ylim');
axis(g_tWT.FrameAx, 'image')
set(g_tWT.FrameAx, 'Visible', 'off', ...
    'box', 'on', ...
    'xtick', [], ...
    'ytick', [], ...
    'xticklabel', [], ...
    'yticklabel', [] );
    %'xlim', vXlim, ...
    %'ylim', vYlim )
    % following lines commented out to permit persistent zoom
    %'xlim', [0 size(mFrame, 2)], ...
    %'ylim', [0 size(mFrame, 1)] )

% Put image to back of axes
hImg = findobj(g_tWT.FrameAx, 'Type', 'image');
vChild = get(g_tWT.FrameAx, 'Children');
vChild(vChild == hImg(end)) = [];
vChild(end+1) = hImg(end);
set(g_tWT.FrameAx, 'Children', vChild)

drawnow

return
