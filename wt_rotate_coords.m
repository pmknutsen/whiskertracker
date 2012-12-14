% WT_ROTATE_COORDS
% Transform coordinates of objects or whiskers between absolute and
% relative framework. A note on transformations:
%   Absolute coordinates are in the framework of the actual image
%   Relative coordinates are with respect to head position in the image
%
% Syntax: wt_rotate_coords(COORDS, DIR, RE, LE, NO, S, F, DEB, RAD, HOR), where
%           COORDS are pair-wise [X Y] coordinates to be transformed. Any
%           number of such pairs may be passed arranged along rows.
%           DIR is the transform to be performed:
%               'rel2abs' for a relative to absolute transformation
%               'abs2rel' for an absolute to relative transformation
%           RY are right-eye coordinates across frames arranged across rows
%           LY are right-eye coordinates across frames arranged across rows
%           N are nose coordinates across frames arranged across rows
%           S is the side on the face of the whisker:
%               1 = right
%               2 = left
%

function vNewCoords = wt_rotate_coords(vCoords, sDirection, vRightEye, vLeftEye, vNose, nSide, ...
    vImCropSize, nRadExt, nHorExt)

% Return immediately if object position is not given for current whiskers
if sum(vCoords) == 0, return; end

% Current frame head coordinates
mHead = [vLeftEye; vRightEye; vNose];

% Initialize output matrix
vNewCoords = repmat(NaN, size(vCoords));

% Iterate over pairs of [X Y] coordinates
for i = 1:size(vCoords,1)
    switch sDirection
        case 'rel2abs'
            vNewCoords(i,:) = TransformRelToAbs(vCoords(i,:), nSide, mHead, vImCropSize, nRadExt, nHorExt);
        case 'abs2rel'
            vNewCoords(i,:) = TransformAbsToRel(vCoords(i,:), nSide, mHead, vImCropSize, nRadExt, nHorExt);
    end
end

return;


%%%% TransformRelToAbs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Transform relative to absolute coordinates

function mCoordsNew = TransformRelToAbs(mCoords, nSide, mHead, vImCropSize, nRadExt, nHorExt)

% Relative to absolute transformation:
%  nA = angle between nose-eye and nose-object axis (in relative framework)
%  nB = angle of eye relative to nose (in absolute framework)
%  nC = unknown angle of object relative to nose (in absolute framework)
%  Solution: nC = nA - nB
%  From nC we derive the position of the object in the absolute framework.

vNoseAbs = mHead(3,:);
vNoseRel = [1 vImCropSize(2)-nHorExt+6];
if nSide == 1, vEyeAbs = [mHead(2,1) mHead(2,2)]; else vEyeAbs = [mHead(1,1) mHead(1,2)]; end
vObjRel = mCoords - repmat(vNoseRel,size(mCoords,1),1); % note: object relative to nose!
nA = abs(-deg2rad(90)-(atan(vObjRel(:,2)./vObjRel(:,1))));
vEyeRel = vEyeAbs - vNoseAbs; % note: eye relative to nose!
nB = abs(atan(vEyeRel(2)/vEyeRel(1)));
nC = nA - nB;
% Now get position of object in absolute framework and we're done...
nR = sqrt(sum(vObjRel'.^2))';% distance of object from nose
nXRel = nR .* cos(nC); % object x position relative to nose
nYRel = nR .* sin(nC); % object y position relative to nose
if nSide == 1
    mCoordsNew = [ ...
            repmat(vNoseAbs(1),size(mCoords,1),1) - nXRel ...
            repmat(vNoseAbs(2),size(mCoords,1),1) + nYRel
        ];
elseif nSide == 2
    mCoordsNew = repmat(vNoseAbs,size(mCoords,1),1) + [nXRel nYRel];
end

return;


%%%% TransformRelToAbs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Transform absolute to relative coordinates

function vNewCoords = TransformAbsToRel(vCoords, nSide, mHead, vImCropSize, nRadExt, nHorExt)

% 1. Find angle between nose-eye and nose-object axis
% 2. Find distance from nose to object

% Object position relative to nose, and angle
vObjRelNose = [vCoords(1)-mHead(3,1) vCoords(2)-mHead(3,2)];
nLenNose2Obj = sqrt(sum([vObjRelNose.^2]));
nNoseObjAng = rad2deg(atan2(vObjRelNose(2),vObjRelNose(1)));

% Eye position relative to nose, and angle
if nSide == 1, vEyeRelNose = [mHead(2,1)-mHead(3,1) mHead(2,2)-mHead(3,2)];
else, vEyeRelNose = [mHead(1,1)-mHead(3,1) mHead(1,2)-mHead(3,2)]; end
nNoseEyeAng = rad2deg(atan2(vEyeRelNose(2),vEyeRelNose(1)));

% Get new angle of object relative to nose
if nSide == 2
    nNewNoseObjAng = nNoseObjAng - (90 - abs(nNoseEyeAng));
else
    nNewNoseObjAng = -180 - (nNoseObjAng - (90 - abs(nNoseEyeAng)));
end

% Calculate object position relative to nose
nX = nLenNose2Obj * cos(deg2rad(nNewNoseObjAng));
nY = nLenNose2Obj * sin(deg2rad(nNewNoseObjAng));
vRelObjPos = [nX nY];

% Calculate real position in frame
% IMPORTANT: The code below compensates for the fact that both left and
% right frame are shown in the WT GUI in the same axis. Therefore, to
% obtain true relative position for left-side the cut-out section's width
% (effectively g_tWT.MovieInfo.RadExt) must be subtracted from the object's X
% coordinate.
if nSide == 2
    vNose = [nRadExt+2 vImCropSize(2) - nHorExt+6];
    vNewCoords = [vNose(1)+vRelObjPos(1) vNose(2)+vRelObjPos(2)];
else
    vNose = [1 vImCropSize(2)-nHorExt+6];
    vNewCoords = [vNose(1)+vRelObjPos(1) vNose(2)+vRelObjPos(2)];
end

return;
