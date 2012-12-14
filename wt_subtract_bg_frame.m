% WT_SUBTRACT_BG_FRAME
% IMG_OUT = wt_subtract_bg_frame(IMG, F), where
%   IMG is the frame from which to subtract the background frame
%   F is the current frame number
%   IMG_OUT is IMG minus the background
%
% Subtract background frame from passed image. The passed coordinates are
% used to select what portion of the frames to subtract, in case the passed
% image has alredy been cropped. vCoords are in absolute coordinates. The
% current-frame parameter is used to determine whcih series of frames to
% subtract from the passed image, in case different background-frames have
% been calculated (e.g. before object entry and after object entry)
%
% The background frame is low-pass filtered if a number has been entered in
% the 'Low-pass background image (pixels)' field in the parameters GUI. The
% value entered is used to determine the diameter (in pixels) of a low-pass
% median filter.
%
% Output frame is scaled to same range as input frame.
%
% IMPORTANT NOTE:
% If in the matrix where background frame series are specified any row
% contains two zeros [0 0] then ALL background frames will be subtracted
% from ALL frames!
%

function mImgOut = wt_subtract_bg_frame(varargin)

global g_tWT
persistent p_tBgFrames
persistent p_nBGLowPass

if nargin == 1
    switch varargin{1}
        case 'reset'
            p_tBgFrames = struct([]);
            return;
    end
else
    mImgIn          = varargin{1};
    vCoords         = [1 1 g_tWT.MovieInfo.Width-1 g_tWT.MovieInfo.Height-1];% * g_tWT.MovieInfo.ResizeFactor;
    nCurrentFrame   = varargin{2};
end

bDebug = g_tWT.VerboseMode;

% Iterate over p_cBgFrames and decide which background-frames to scrap and
% which to keep. If all are scrapped, calculate all background frames. If
% all are kept, then don't recalculate any of them. Here we also shuffle
% the order of the background frames and case some are kept and new ones
% are inserted. For instance, new background frames will be calculated if
% the user changes the start- and stop-frame values of the background
% frames in the GUI.

% Select frame-series to average
mAvgFrames = g_tWT.MovieInfo.AverageFrames;

% Determine whether to subtract ALL background frames from current frame
nZeroRow = find(any(~all(mAvgFrames,2)));
if ~isempty(nZeroRow)
    bSubtractAll = 1;
    mAvgFrames(nZeroRow, :) = [];
else bSubtractAll = 0; end

% Exit immediately if background frames should not be used
if isempty(mAvgFrames)
    p_tBgFrames = struct([]);
    mImgOut = double(mImgIn);
    return;
end

% If the size of the background-frame smoothing window has changed, scrap
% all existing background frames and calculate these again (and then smooth
% with the new window)
if p_nBGLowPass ~= g_tWT.MovieInfo.BGFrameLowPass
    p_tBgFrames = struct([]); % clear persistent variable (we concatenate the existing frames below)
end
p_nBGLowPass = g_tWT.MovieInfo.BGFrameLowPass;

% Select which of the existing background frames to keep
tTempFrames = struct([]);
for bgA = 1:size(p_tBgFrames, 2)
    for bgB = 1:size(mAvgFrames, 1)
        if (p_tBgFrames(bgA).from == mAvgFrames(bgB,1)) ...
                && (p_tBgFrames(bgA).to == mAvgFrames(bgB,2))
            % Background-frame already exists...
            mAvgFrames(bgB,:) = [NaN NaN];
            nNewIndx = size(tTempFrames,2)+1;
            tTempFrames(nNewIndx).img = p_tBgFrames(bgA).img;
            tTempFrames(nNewIndx).from = p_tBgFrames(bgA).from;
            tTempFrames(nNewIndx).to = p_tBgFrames(bgA).to;
        end
    end
end
mAvgFrames(isnan(mAvgFrames)) = [];

p_tBgFrames = struct([]); % clear persistent variable (we concatenate the existing frames below)

% Determine how many background frames to calculate.
if isempty(mAvgFrames), nNoBgFrames = 0;
else nNoBgFrames = size(mAvgFrames, 1); end

% Initialize waitbar
for bg = 1:nNoBgFrames
    if ~exist('hWaitBar'), hWaitBar = waitbar(0, ''); end
    % Update waitbar
    waitbar(bg/(nNoBgFrames+1), hWaitBar, sprintf('Calculating background-frame %d of %d', bg, nNoBgFrames))

    nFrom = mAvgFrames(bg,1); % start range
    nTo = mAvgFrames(bg,2); % end range
    if nFrom == 0, nFrom = 1; end
    if nTo == 0, nTo = nFrom + 1; end

    if nFrom > nTo % check consistency in input
        wt_error('The first background frame has a higher frame-number than the last. Check values in Image->Parameters.')
    end

    nAviTo = nTo; % limit nTo to max frames
    if nTo > g_tWT.MovieInfo.NumFrames
        nAviTo = g_tWT.MovieInfo.NumFrames;
    end
    
    % Load background frames in chunks to avoid memory problems
    if g_tWT.MovieInfo.NoFramesToLoad >= (nTo - nFrom), vRanges = [nFrom nTo];
    else vRanges = nFrom:g_tWT.MovieInfo.NoFramesToLoad:nTo; end
    mAveragedFrames = [];
    for r = 2:length(vRanges)
        vRange = [vRanges(r-1) (vRanges(r)-1)]; % [min max]
        vFrames = max([1 vRange(1)]):min([vRange(2) g_tWT.MovieInfo.NumFrames]); % all frames to be loaded
        if isempty(g_tWT.MovieInfo.FilenameUncompressed)
            mFrames = wt_load_avi(g_tWT.MovieInfo.Filename, vFrames, 'noresize');
        else
            mFrames = wt_load_avi(g_tWT.MovieInfo.FilenameUncompressed, vFrames, 'noresize');
        end
        
        try mFrames = double(mFrames);
        catch, wt_error('Out of memory. Try to reduce the number of background frames.'), end

        mAveragedFrame = mean(mFrames, 3);
        mAveragedFrames(:,:,r-1) = mAveragedFrame;
    end
    mAveragedFrame = mean(mAveragedFrames,3);
    
    % Crop image
    mAveragedFrame = imcrop(mAveragedFrame, vCoords);

    % Smooth background image
    if isfield(g_tWT.MovieInfo, 'BGFrameLowPass')
        nLowPass = g_tWT.MovieInfo.BGFrameLowPass;
        if ~isempty(nLowPass) && (nLowPass > 1)
            mWin = ones(nLowPass);
            mAveragedFrame = conv2(mAveragedFrame, mWin, 'same') ./ numel(mWin);
        end
    end
    
    % Store averaged frame in the persistent holder variable
    p_tBgFrames(bg).img = mAveragedFrame;
    p_tBgFrames(bg).from = mAvgFrames(bg,1);
    p_tBgFrames(bg).to = mAvgFrames(bg,2);

end
if exist('hWaitBar'), close(hWaitBar); end

% Concatenate new background frames with the exisiting ones we stored in the beginning of this function
p_tBgFrames = cat(2, p_tBgFrames, tTempFrames);

% Sort background frames in ascending order by 'from' field
[vNewOrder vNewIndxOrd] = sortrows(char(p_tBgFrames.from));
p_tBgFrames = p_tBgFrames(vNewIndxOrd);

% Show all background frames in debug mode
if bDebug
    hFig = findobj('Tag', 'SUBTRACT_BACKGROUND_WINDOW');
    if isempty(hFig)
        hFig = figure;
        set(hFig, 'Tag', 'SUBTRACT_BACKGROUND_WINDOW', 'DoubleBuffer', 'on', 'Name', 'WT - SUBTRACT_BACKGROUND_WINDOW', 'numbertitle', 'off')
    else figure(hFig), end
    clf
    for bg = 1:size(p_tBgFrames,2)
        subplot(2,max([3 size(p_tBgFrames,2)]),bg)
        imagesc(p_tBgFrames(bg).img); colormap gray;
        title(sprintf('BG frame %d-%d', p_tBgFrames(bg).from, p_tBgFrames(bg).to))
    end
end

% Finally, subtract the appropriate background frame from the passed frame
% (use input parameter nCurrentFrame to determine which background frame to
% subtract)
mBgFrame = zeros(size(mImgIn));
mImgOut = mImgIn;
if bSubtractAll
    cAll = {p_tBgFrames(:).img};
    mAll = cat(3, cAll{:,:,:});
    mBgFrame = mean(mAll,3);
    mBgFrameRe = mBgFrame;
    mBgFrameN = mBgFrameRe./max(max(mBgFrameRe));
    
    % Get range of values in input image
    nInMin = double(min(mImgIn(:)));
    nInMax = double(max(mImgIn(:)));
    mImgInN = double(mImgIn)./max(max(double(mImgIn)));
    mImgOut = mImgInN - double(mBgFrameN);
    
    % Stretch output image to original range of input image
    mImgOut = mImgOut - min(mImgOut(:));
    mImgOut = mImgOut ./ max(mImgOut(:));
    mImgOut = mImgOut .* (nInMax-nInMin);
    mImgOut = mImgOut + nInMin;
else
    for bg = 1:size(p_tBgFrames,2)
        % Subtract background frame is there is a such one for the current frame
        if (nCurrentFrame >= p_tBgFrames(bg).from) && (nCurrentFrame <= p_tBgFrames(bg).to)
            % Check images have same dimensions
            if (size(mImgIn,1) == size(p_tBgFrames(bg).img,1)) && (size(mImgIn,2) == size(p_tBgFrames(bg).img,2))
                mBgFrame = double(p_tBgFrames(bg).img);
                mBgFrameRe = mBgFrame;
                mBgFrameN = mBgFrameRe./max(max(mBgFrameRe));
                % Get range of values in input image
                nInMin = double(min(mImgIn(:)));
                nInMax = double(max(mImgIn(:)));
                mImgInN = double(mImgIn)./max(max(double(mImgIn)));
                mImgOut = mImgInN - mBgFrameN;
                % Stretch output image to original range of input image
                mImgOut = mImgOut - min(mImgOut(:));
                mImgOut = mImgOut ./ max(mImgOut(:));
                mImgOut = mImgOut .* (nInMax-nInMin);
                mImgOut = mImgOut + nInMin;
            else
                wt_error('Current frame and its background frame do not have the same dimensions.')
            end
        end
    end
end

% Plot original, background frame and adjusted image
if bDebug
    subplot(2,3,4)
    imagesc(mImgIn); title('Original')
    subplot(2,3,5)
    imagesc(mBgFrame); title('Background')
    subplot(2,3,6)
    imagesc(mImgOut); title('Adjusted')
    colormap gray
    drawnow
end

return;
