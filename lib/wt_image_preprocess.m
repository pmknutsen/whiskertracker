function [mImgOut, mImgOutCroppedOnly] = wt_image_preprocess( mImgIn )
% IM = WT_IMAGE_PREPROCESS(IM)
% Pre-processes movie frames during tracking:
%   (1) Crop
%   (2) Rotate
%   (3) Invert contrast
%

global g_tWT
bDebug = g_tWT.VerboseMode;

mImgOut = mImgIn; % assign original image

if bDebug % original image (cropped)
    hFig = findobj('Tag', 'IMAGE_PREPROCESS_WINDOW');
    if isempty(hFig)
        hFig = figure;
        set(hFig, 'Tag', 'IMAGE_PREPROCESS_WINDOW', 'DoubleBuffer', 'on', 'toolbar', 'none', ...
            'Name', ['WT Debug - ' mfilename], 'numbertitle', 'off', 'position', [1 1 700 200])
        centerfig(hFig)
    end
    hAx = subplot(1, 3, 1, 'parent', hFig);
    imagesc(mImgIn, 'parent', hAx)
    axis(hAx, 'image')
    colormap gray
    set(hAx, 'xtick', [], 'ytick', [])
    title(hAx, 'Original (avg subtr)')
end

% Crop
if isempty(g_tWT.MovieInfo.Roi)
    g_tWT.MovieInfo.Roi = [1 1 g_tWT.MovieInfo.Width-1 g_tWT.MovieInfo.Height-1];
end
if ~(g_tWT.MovieInfo.Roi(3:4)+1 == [g_tWT.MovieInfo.Height g_tWT.MovieInfo.Width])
    mImgOut = imcrop(mImgOut, g_tWT.MovieInfo.Roi);
end

% Rotate
if g_tWT.MovieInfo.Rot ~= 0, mImgOut = imrotate(mImgOut, g_tWT.MovieInfo.Rot, 'bicubic'); end
if g_tWT.MovieInfo.Flip(1), mImgOut = flipud(mImgOut); end % flip up-down
if g_tWT.MovieInfo.Flip(2), mImgOut = fliplr(mImgOut); end % flip left-right
mImgOutCroppedOnly = mImgOut;

% Invert
if g_tWT.MovieInfo.Invert
    if isinteger(mImgOut)
        % If mImgOut is uint8, a couple of steps are required to invert the image
        mImgOut = double(mImgOut) .* -1;
        mImgOut = uint8(mImgOut - min(mImgOut(:)));
    else
        mImgOut = mImgOut .* -1;
    end
end

if bDebug % original image (cropped)
    hAx = subplot(1, 3, 2, 'parent', hFig);
    imagesc(mImgOut, 'parent', hAx)
    colormap gray
    title(hAx, 'Crop/rotate/invert')
    set(hAx, 'xtick', [], 'ytick', [])
    axis(hAx, 'image')
    
    hAx = subplot(1,3,3, 'parent', hFig);
    imagesc(mImgOut, 'parent', hAx)
    colormap gray
    title(hAx, 'Normalized');
    set(hAx, 'xtick', [], 'ytick', [])
    axis(hAx, 'image')
    drawnow
end

return