% WT_CROP_BEHAVING_VIDEO
% Extract region of interest parallel to whisker-pad.
% wt_crop_behaving_video(M, C, HOR, RAD, METHOD), where
%   M is the loaded frame
%   C is a 3-by-2 vector containing X Y coordinates of right-eye, left-eye
%     and nose.
%   HOR is the length of the extracted region (anterior-posterior axis)
%   RAD is the width of the extracted region (distance from face)
%   METHOD is the interpolation method used when rotating the extracted
%     region, either 'linear' (fast) or 'bicubic' (slow, but better).
%

function mCropImg = wt_crop_behaving_video(mImg, mCoords, hor_ext, rad_ext, method);
global g_tWT

% Resize cropping parameters according to the ersize factor
%hor_ext = hor_ext * g_tWT.MovieInfo.ResizeFactor;
%rad_ext = rad_ext * g_tWT.MovieInfo.ResizeFactor;
%mCoords = mCoords * g_tWT.MovieInfo.ResizeFactor;

bDebug = g_tWT.VerboseMode;
switch lower(method)
    case 'bicubic'
        bBicubic = 1;
    case 'nearest'
        bBicubic = 0;
    otherwise
        error('Unknown method in wt_crop_behaving_vide')
end

% Rotate and extract the relevant parts of the image
% A small note: the routine first defines the vertices of the relevant
% section in the coordinates of the original frame. It then extracts this
% part, rotates it and re-crops it so only the defined rectangle is kept.
% An alternative would be to rotate the entire frame, and then crop. This is
% intuitively simpler, but because the imrotate(...) function is slow on
% large matrices (e.g. such as the entire frame), this method takes more
% than 3 times longer to execute than the first method.

% TODO:
%   - account for possible errors coordinates are outside the frame
%   - return both right and left side and the ROI in absolute coordinates
%   - check consistency of mCoords input matrix

if bDebug
    hFig = findobj('Tag', 'CROP_FRAME_WINDOW');
    if isempty(hFig)
        hFig = figure;
        set(hFig, 'Tag', 'CROP_FRAME_WINDOW', 'DoubleBuffer', 'on', 'Name', 'WT - CROP_FRAME_WINDOW', 'numbertitle', 'off')
    else, figure(hFig), end
    clf;
end

nPadFact = 4;

% zero-pad image to avoid boundary errors
mImg = padarray(mImg, [hor_ext*nPadFact rad_ext*nPadFact], mean(mean(mImg(:,:,1))),'both');

% repeat once for right eye and once for left eye
new_coords = zeros(4,2);
for e = 1:2 % 1=right 2=left

    % angle between eye and nose
    y = abs(mCoords(e,2) - mCoords(3,2));
    x = mCoords(e,1) - mCoords(3,1);
    if x < 0
        theta = -1*(90 + rad2deg(atan(y/x)));
    else
        theta = 90 - rad2deg(atan(y/abs(x)));
    end

    if (mCoords(3,1)-mCoords(e,1)) < 0
        ang = pi + atan( (mCoords(3,2)-mCoords(e,2))/(mCoords(3,1)-mCoords(e,1)) ); % ang between points
    else
        ang = atan( (mCoords(3,2)-mCoords(e,2))/(mCoords(3,1)-mCoords(e,1)) ); % ang between points
    end

    eye_nose_zero_intersect = interp1([mCoords(3,2) mCoords(e,2)], [mCoords(3,1) mCoords(e,1)], 0, 'linear', 'extrap');
    r_nose = sqrt(sum([(mCoords(3,1)-eye_nose_zero_intersect) mCoords(3,2)].^2)) + hor_ext;
    new_coords(1,:) = [ r_nose*cos(ang)+eye_nose_zero_intersect r_nose*sin(ang) ]; % ant A

    r_eye = sqrt(sum([(mCoords(e,1)-eye_nose_zero_intersect) mCoords(e,2)].^2)) - hor_ext;
    new_coords(2,:) = [ r_eye*cos(ang)+eye_nose_zero_intersect r_eye*sin(ang) ]; % post A

    adj = [rad_ext*cos(ang-deg2rad(90)) rad_ext*sin(ang-deg2rad(90))];
    if e == 1 % right eye
        new_coords(4,:) = new_coords(1,:) - adj; % ant B
        new_coords(3,:) = new_coords(2,:) - adj; % post B
    else % left eye
        new_coords(4,:) = new_coords(1,:) + adj; % ant B
        new_coords(3,:) = new_coords(2,:) + adj; % post B
    end

    % transform coordinates to take into account zero-padding
    new_coords = [new_coords(:,1)+rad_ext*nPadFact new_coords(:,2)+hor_ext*nPadFact];

    % extract the rectangle
    x = min(new_coords(:,1));
    y = min(new_coords(:,2));
    w = max(new_coords(:,1)) - x; %end % use width of 1st frame
    h = max(new_coords(:,2)) - y; %end % use height of 1st frame
    try
        mTemp = mImg(round(y:y+h), round(x:x+w));
    catch
        wt_error('Possible error with head-coordinates. Check by changing display mode.')
    end

    % calculate what the size of the rotate image will be (uncropped)
    theta_rad = deg2rad(theta);
    R = [cos(theta_rad) sin(theta_rad); -sin(theta_rad) cos(theta_rad)];
    half_w = size(mTemp, 1)/2;
    half_h = size(mTemp, 2)/2;
    % corners = [up_left; up_right; low_left; low_right]
    corners(1,:) = [-half_w half_h];
    corners(2,:) = [half_w half_h];
    corners(3,:) = [-half_w -half_h];
    corners(4,:) = [half_w -half_h];
    new_corners = corners * R;
    if theta < 0
        new_size = abs([new_corners(3,1)*2 new_corners(1,2)*2]);
    else
        new_size = abs([new_corners(1,1)*2 new_corners(2,2)*2]);
    end
    % zeropad image before rotating to take into account loss of pixels
    % during cropping
    vPad = ceil((new_size-size(mTemp))/2);
    % remove negative values
    vPad(vPad<0) = 0;
    mTemp = padarray(mTemp, vPad, 'both');

    % rotate rectangle
    if bBicubic
        %  - use Matlab method if choosing bicubic interpolation
        mTemp = imrotate(mTemp, theta, 'bicubic', 'crop');
    else
        %  - use C script of choosing nearest interpolation
        mTemp = rotate_matrix(double(mTemp), theta);
    end

    % crop again so only the relevant section is included in final image
    % We have replaced the two lines below with parameters defined earlier
    % in the global namespace, as we want all frames to have the same size.
    %new_w = round(rad_ext);
    %new_h = round(hor_ext*2 + sqrt(sum([mCoords(3,1)-mCoords(e,1) mCoords(3,2)-mCoords(e,2)].^2))); %end
    new_w = g_tWT.MovieInfo.ImCropSize(1);% * g_tWT.MovieInfo.ResizeFactor;
    new_h = g_tWT.MovieInfo.ImCropSize(2);% * g_tWT.MovieInfo.ResizeFactor;

    x = round((size(mTemp, 2) - new_w) / 2);
    y = round((size(mTemp, 1) - new_h) / 2);
    mCropImg{e} = mTemp(round(y:y+new_h), round(x:x+new_w));

    if bDebug
        subplot(1,4,e+2)
        imagesc(mCropImg{e}); SetPlotProps;
    end
    
end

% Plot
if bDebug
    subplot(1,4,1:2)
    imagesc(mImg(hor_ext:size(mImg,1)-hor_ext,rad_ext:size(mImg,2)-rad_ext))
    title('Original')
    colormap gray; hold on
    scatter(mCoords(:,1),mCoords(:,2),'g.') % eyes/nose
    scatter(new_coords(:,1)-rad_ext, new_coords(:,2)-hor_ext, 'r.') % rect coords
    plot(new_coords([1 2 3 4 1], 1)-rad_ext, new_coords([1 2 3 4 1], 2)-hor_ext, 'r')
    SetPlotProps;
    drawnow
end

% make sure that both rectangles have the same dimensions before returning
% them
min_height = min([size(mCropImg{1},1) size(mCropImg{2},1)]);
min_width  = min([size(mCropImg{1},2) size(mCropImg{2},2)]);

% crop outwards (from whisker roots) and downwards (from neck)
mCropImg{1} = mCropImg{1}(1:min_height, (size(mCropImg{1},2)+1-min_width):end);
mCropImg{2} = mCropImg{2}(1:min_height, 1:min_width);

% flip right rectangle horizontally
mCropImg{1} = fliplr(mCropImg{1});

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetPlotProps
set(gca, 'xtick', [], 'ytick', [])