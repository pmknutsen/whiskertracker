function [vNewPos, nScore, nScoreStd] = wt_track_spot(mI_orig, vPos_orig, mConstraint, mFilter, bDebug, nThresh)
% WT_TRACK_SPOT Track the new location of a bright-on-dark spot (e.g. a
% rat's eye or a marker on a whisker). Convolves an image with a
% difference-of-Gaussians and selects the brightest spot in the vicinity of
% the spot's location in the previous frame as its new location.
%
% Inputs:
%   mI              Image matrix
%   vPos            Position [X Y] in previous frame
%   mConstraints    Locate brightest spot within given [X Y] coordinates
%                   Empty if not applicable
%   mFilter         2D image convolution filter (difference of gaussians)
%   bDebug          Boolean debug switch (0 or 1)
%
% Outputs:
%   vNewPos         Position [X Y] in current frame
%   nScore          Average value of pixels used to compute location
%   nScoreStd       Standard deviation of pixels values in ROI
%                   These two output can be used with wt_plot_signal_noise
%

sMethod = 'center_of_gravity';

if ~exist('nThresh')
    nThresh = 256;
end

nPixRad = max(size(mFilter));

vPos = vPos_orig + nPixRad; % adjust position for padding
mROI_coords = [vPos(1)-nPixRad/2 vPos(2)-nPixRad/2 nPixRad nPixRad]; % ROI coords
mI = padarray(mI_orig, [nPixRad nPixRad], 'both'); % pad
mROI_img = imcrop(mI, mROI_coords); % Raw ROI

% find pixels to threshold
mThreshMat = mROI_img < nThresh.*-1;

%new
%vIndx = find(mROI_img == 0);
vIndx = mROI_img == 0;
mROI_img = mROI_img - min(min(mROI_img));

% Convolve region of interest (plus some region around it)
nX_start = round(max([1 mROI_coords(1)-mROI_coords(3)]));
nX_end = round(min([size(mI,2) mROI_coords(1)+mROI_coords(3)*2]));
vX_indx = nX_start:nX_end;
nY_start = round(max([1 mROI_coords(2)-mROI_coords(4)]));
nY_end = round(min([size(mI,1) mROI_coords(2)+mROI_coords(4)*2]));
vY_indx = nY_start:nY_end;
mI(vY_indx, vX_indx) = conv2(mI(vY_indx, vX_indx), mFilter, 'same');
mROI_conv = imcrop(mI, mROI_coords); % Convolved ROI

%new
mROI_conv(vIndx) = 0;

% threshold
mROI_conv(mThreshMat) = 0;

switch lower(sMethod)
    case 'center_of_gravity' % Find center of spot by location the center-of-gravity in segmented image

        % Segment image
        %  'manual' (center-of-gravity of 10% brightest pixels
        [vB, vIndx] = sort(mROI_conv(:));
        nN = min([round(length(vB) / 100 * 5) length(find(mROI_conv(:)>0))]);
        mSegmentedImage = zeros(size(mROI_conv));
        mSegmentedImage(vIndx(end-nN+1:end)) = 1;

        % Center of gravity
        [vY, vX] = find(mSegmentedImage);
        nX = mean(vX);
        nY = mean(vY);
        vNewPos = [nX+vPos(1)-nPixRad/2 nY+vPos(2)-nPixRad/2] - nPixRad;
        
        nScore = mean(mROI_conv(find(mSegmentedImage(:))));
        nScoreStd = std(mROI_conv(:));
        
    case 'brightest_pixel' % Find center of spot by locating brightest pixel in image
        % Get absolute coordinate and indices of ROI pixels
        vX = repmat(mROI_coords(1):mROI_coords(1)+mROI_coords(3), mROI_coords(4)+1, 1);
        vY = repmat(mROI_coords(2):mROI_coords(2)+mROI_coords(4), mROI_coords(3)+1, 1)';
        vI_abs_roi = sub2ind(size(mI), vY(:), vX(:)); % absolute indices of ROI pixels

        % Remove pixels that don't fall on constraining coordinates
        if ~isempty(mConstraint)
            mConstraint = round(mConstraint) + nPixRad; % round to whole pixels and account for padding
            mConstraint(find(any(mConstraint(:,:) < 1, 2)),:) = []; % remove pixels outside image
            vI_abs_constraint = sub2ind(size(mI), mConstraint(:,2), mConstraint(:,1));
            [vI_abs_roi, vIndx_roi] = intersect(vI_abs_roi, vI_abs_constraint);
        else vIndx_roi = 1:length(vI_abs_roi); end

        % Locate brightest pixel
        [nMaxVal, nMaxIndx] = max(mROI_conv(vIndx_roi));
        nX = vX(vIndx_roi(nMaxIndx));
        nY = vY(vIndx_roi(nMaxIndx));
        vNewPos = [nX nY] - nPixRad;
end

if bDebug
    hFig = findobj('Tag', 'TRACK_SPOT_DEBUG_WINDOW');
    if isempty(hFig)
        hFig = figure;
        set(hFig, 'Tag', 'TRACK_SPOT_DEBUG_WINDOW', ...
            'DoubleBuffer', 'on', ...
            'Name', 'WT - TRACK_SPOT_DEBUG_WINDOW', ...
            'numbertitle', 'off', ...
            'Renderer', 'painters', ...
            'BackingStore', 'on')
    else figure(hFig), end
    clf; colormap gray
    hS1 = subplot(2,3,[1 2 4 5]);
    imagesc(mI_orig); axis equal
    title('Image after pre-processing')
    hold on; plot(vNewPos(1), vNewPos(2), 'rx'); hold off

    hS2 = subplot(2,3,3);
    imagesc(mROI_img); axis equal % original image
    title('ROI')
    
    hS3 = subplot(2,3,6);
    imagesc(mROI_conv); axis equal % convolved image
    title('Convolved ROI')
    set([hS1 hS2 hS3], 'xticklabel', [], 'yticklabel', [], 'color', 'k')
    drawnow
end

return
