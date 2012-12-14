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

%%% DEBUG ONLY
if bDebug % original image (cropped)
    hFig = findobj('Tag', 'IMAGE_PREPROCESS_WINDOW');
    if isempty(hFig)
        hFig = figure;
        set(hFig, 'Tag', 'IMAGE_PREPROCESS_WINDOW', 'DoubleBuffer', 'on', 'Name', 'WT - IMAGE_PREPROCESS_WINDOW', 'numbertitle', 'off')
    else figure(hFig), end
    subplot(1,3,1); imagesc(mImgIn)
    colorbar
    colormap gray
    SetPlotProps();
    title('Original (avg subtr)')
end
%%% DEBUG END

% Crop
if ~(g_tWT.MovieInfo.Roi(3:4)+1 == [g_tWT.MovieInfo.Height g_tWT.MovieInfo.Width])
    mImgOut = imcrop(mImgOut, g_tWT.MovieInfo.Roi);
end

% Rotate
if g_tWT.MovieInfo.Rot ~= 0, mImgOut = imrotate(mImgOut, g_tWT.MovieInfo.Rot, 'bicubic'); end
if g_tWT.MovieInfo.Flip(1) mImgOut = flipud(mImgOut); end % flip up-down
if g_tWT.MovieInfo.Flip(2) mImgOut = fliplr(mImgOut); end % flip left-right
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

%%% DEBUG ONLY
if bDebug % original image (cropped)
    subplot(1,3,2); imagesc(mImgOut)
    colorbar
    colormap gray
    title('Crop/rotate/invert')
    SetPlotProps();
    
    subplot(1,3,3)
    imagesc(mImgOut)
    colorbar
    colormap gray
    title('Normalized');
    SetPlotProps();
    drawnow
end
%%% DEBUG END

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetPlotProps
set(gca, 'xtick', [], 'ytick', [])
return
