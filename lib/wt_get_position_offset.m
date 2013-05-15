function [vPosOffset] = wt_get_position_offset(mWhisker, mObjAbs, vImCropSize, nRadExt, nHorExt, varargin)
% WT_GET_POSITION_OFFSET
%
% Calculate distance of whisker from object. The position returned is the
% distance between the whisker and object Y position at the location of X
% axis of the object. This function is 'stand-alone' and can be called
% without WT being currently invoked (it does not access any globals variables
% used by WT).
%
% Syntax: wt_get_position_offset(W, OBJ, IC, RE, HE, RY, LY, NO, WS), where
%           W is a matrix of splinepoints denoting whisker shaped arranged
%           in frames along the 3rd dimension.
%           OBJ is the object's position in absolute coordinates.
%           IC is the ImCropSize variable in g_tWT.MovieInfo
%           RE is the RadExt variable in g_tWT.MovieInfo
%           HE is the HorExt variable in g_tWT.MovieInfo
%           ** Optional parameters **
%           Note: These parameters are REQUIRED when head is not stationary
%           RY are right-eye coordinates across frames arranged across rows
%           LY are right-eye coordinates across frames arranged across rows
%           NO are nose coordinates across frames arranged across rows
%           WS is which side of the face the passed whisker is located:
%               1 = right
%               2 = left
%
% Note that when whisker length is too short to reach X coordinate of
% object, the whisker shape extrapolated to that position and the resultant
% Y value used to calculate distance from object. If head-coordinates are
% passed, however, the whisker shape is NOT extrapolated and frames where
% whisker is too short to reach object distance from object will be denoted
% by NaN.
%
% Whisker Tracker (WT)
%
% Authors: Per Magne Knutsen, Dori Derdikman
%
% (c) Copyright 2004 Yeda Research and Development Company Ltd.,
%     Rehovot, Israel
%
% This software is protected by copyright and patent law. Any unauthorized
% use, reproduction or distribution of this software or any part thereof
% is strictly forbidden. 
%
% Citation:
% Knutsen, Derdikman, Ahissar (2004), Tracking whisker and head movements
% of unrestrained, behaving rodents, J. Neurophys, 2004, IN PRESS
%

% Remove rows in mObjAbs with only NaNs
vRows = find(prod(isnan(mObjAbs)*1));
mObjAbs(:,:,vRows) = [];

% Initialize head-coordinates
if nargin > 5
    mRightEye = varargin{1};
    mLeftEye = varargin{2};
    mNose = varargin{3};
    nWhiskerSide = varargin{4};
end

% Intialize vector that will hold the position-offste values
vPosOffset = repmat(NaN, size(mWhisker,3), 1);

% Get start frame for all touch locations
if size(mObjAbs, 2) == 2, vStartFrames = 1;
else, vStartFrames = mObjAbs(1,3,:); end
vStartFrames(find(isnan(vStartFrames))) = 1;
vStartFrames = squeeze(vStartFrames);

% Iterate over all frames
for f = 1:size(mWhisker, 3)
    % Decide which touch location to use
    vIndx = find(f >= vStartFrames);
    if isempty(vIndx) | ~prod(prod(mWhisker(1:3,:,f))) % in case no touch location was marked before current frame
        vPosOffset(f) = NaN;
        continue
    end
    vObjAbs = mObjAbs(1,1:2,vIndx(end));
    if isnan(vObjAbs(1))
        vPosOffset(f) = NaN;
        continue
    end

    % Calculate object position in relative coordinates
    if nargin>5
        % Note: The values returned by wt_rotate_coords are in the
        % framework of the WT GUI. Thus, the X coordinate of left-side
        % objects is shifted upwards to higher values (exactly, by the
        % width of the cut-out along the head-axis, i.e. RadExt).
        % Therefore, we subtract RadExt (radial extent of cut-out, or
        % width) from the X coordinated obtained from wt_rotate_coords for
        % left-side whiskers ONLY.
        mRelObjPos = wt_rotate_coords(vObjAbs, ...
            'abs2rel', ...
            mRightEye(f,:), ...
            mLeftEye(f,:), ...
            mNose(f,:), ...
            nWhiskerSide, ...
            vImCropSize, ...
            nRadExt, ...
            nHorExt );
        if nWhiskerSide == 2
            mRelObjPos = [mRelObjPos(1)-(nRadExt+1) mRelObjPos(2)];
        end
    else, mRelObjPos = vObjAbs; end
    mWhiskRel = mWhisker(:,:,f);
    % Remove [0,0] splinepoints
    mWhiskRel = unique(mWhiskRel, 'rows');
    vIndxNoneZero = find(~all(mWhiskRel == 0, 2));
    mWhiskRel = mWhiskRel(vIndxNoneZero,:);

    % Find distance of whisker from object at object's X coordinate
    % Extrapolate whisker if necessary, UNLESS head-coordinates are known
    % AND whisker is too short (then just leave NaN)
    if nargin>5
        if round(mWhiskRel(length(find(mWhiskRel(:,1))),1)) >= mRelObjPos(1)
            % Interpolate whisker Y position at object's X position
            [vXX, nYWhiskPos] = wt_spline(mWhiskRel(:,1), mWhiskRel(:,2), mRelObjPos(1));
            % Calculate difference between whisker and object Y position
            vPosOffset(f) = nYWhiskPos - mRelObjPos(2);
        end
    else
        % Do this if head has not been tracked
        %  - interpolate whisker position (allow extrapolation)
        nYWhiskPos = spline(mWhiskRel(:,1), mWhiskRel(:,2), mRelObjPos(1));
        %  - calculate offset along Y dimension
        vPosOffset(f) = nYWhiskPos - mRelObjPos(2);
    end
end

return
