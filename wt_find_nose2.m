function wt_find_nose2(vNose, vLeye, vReye, mImg)
% WT_FIND_NOSE Finds the nose in image, given eye positions.
% wt_find_nose(N, L, R, I)
% Inputs:
%   N nose position in previous frame [x y]
%   L left eye position in current frame [x y]
%   R right eye position in current frame [x y]
%   I raw image of current frame
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

keyboard

bPlot = 1;

if bPlot
    figure(888); clf
    subplot(1,3,1)
    imagesc(mImg)
    colormap gray; set(gca,'xtick',[],'ytick',[])
    hold on
    plot(vLeye(1),vLeye(2),'go')
    plot(vReye(1),vReye(2),'go')
    plot(vNose(1),vNose(2),'ro')
    axis square
end

% Rotate frame according to head angle in previous frame
vMid = [(vLeye(1)+vReye(1))/2 (vLeye(2)+vReye(2))/2];
nAng = rad2deg(atan2(vNose(2)-vMid(2), vNose(1)-vMid(1)));

nAngImg = nAng - 90;
nAngNose = deg2rad(90 - nAng);

mImgRot = imrotate(mImg, nAngImg, 'nearest'); % rotate image

R = [cos(nAngNose) sin(nAngNose); -sin(nAngNose) cos(nAngNose)]; % rotate nose [x y]
vNoseNew = vNose * R;
nXmod = size(mImgRot, 1) - size(mImg, 1); % account for change in image size
vNoseNew(1) = vNoseNew(1)+nXmod;

% Extract rectangle centered on nose position in previous frame
nSize = 50;
mCrop = imcrop(mImgRot, [vNoseNew(1)-nSize vNoseNew(2)-nSize nSize*2 nSize*2]);
if bPlot
    subplot(1,3,2)
    imagesc(mCrop);
    set(gca,'xtick',[],'ytick',[])
    axis square
end

% Find new position of nose
[nMin nY] = min(diff(std(double(mCrop')))); % Y
[nMax nX] = max(diff(mean(mCrop(:,nMinIndx-5:nMinIndx+5)'))); % X

diff(mean(mCrop(40:60,:)'))

nX = nX + vNoseNew(1)-nSize;
nY = nY + vNoseNew(2)-nSize;


% Rotate nose location to absolute coordinates


return;
