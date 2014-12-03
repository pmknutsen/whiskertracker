function varargout = joint_analysis(sWT, varargin)
% Generate limb representation from tracked markers on shoulder, elbow,
% wrist and digit joints.
%
%

% Get joint data
cMarkers = sWT.MovieInfo.WhiskerLabels;
cMarkerNames = [sWT.MovieInfo.WhiskerIdentity{:}];

% Get joint indices and data
iS = strcmpi(cMarkerNames, 'S');
mS = cMarkers{iS}; % [x y]

iE = strcmpi(cMarkerNames, 'E');
mE = cMarkers{iE}; % [x y]

iW = strcmpi(cMarkerNames, 'W');
mW = cMarkers{iW}; % [x y]

iD = strcmpi(cMarkerNames, 'D');
mD = cMarkers{iD}; % [x y]

%% Plot joint movements
hFig = figure;
hAx = subplot(2, 2, 1);

%%
hold(hAx, 'on')

% Get frames with largest deviations from mean
vD = mD(:,1);
vD = vD - mean(vD);
iF = abs(vD) > (std(vD));

plot(hAx, mS(iF,1), mS(iF,2), 'k')
plot(hAx, mE(iF,1), mE(iF,2), 'k')
plot(hAx, mW(iF,1), mW(iF,2), 'k')
plot(hAx, mD(iF,1), mD(iF,2), 'k')

plot(hAx, [mean(mS(:,1)) mean(mE(:,1))], [mean(mS(:,2)) mean(mE(:,2))], 'b.-', 'markersize', 20)
plot(hAx, [mean(mE(:,1)) mean(mW(:,1))], [mean(mE(:,2)) mean(mW(:,2))], 'r.-', 'markersize', 20)
plot(hAx, [mean(mW(:,1)) mean(mD(:,1))], [mean(mW(:,2)) mean(mD(:,2))], 'g.-', 'markersize', 20)

%set(hAx, 'ydir', 'reverse')
axis(hAx, 'equal')
title(hAx, 'Joint movements')

% Calculcate joint angles

% Shoulder - Elbow
vSE_theta = atan2(mE(:,2) - mS(:,2), mE(:,1) - mS(:,1));
vSE_rho = sqrt((mE(:,2) - mS(:,2)).^2 + (mE(:,1) - mS(:,1)).^2);

% Elbow - Wrist
vEW_theta = atan2(mW(:,2) - mE(:,2), mW(:,1) - mE(:,1));
vEW_rho = sqrt((mW(:,2) - mE(:,2)).^2 + (mW(:,1) - mE(:,1)).^2);

% Wrist - Digit
vWD_theta = atan2(mD(:,2) - mW(:,2), mD(:,1) - mW(:,1));
vWD_rho = sqrt((mD(:,2) - mW(:,2)).^2 + (mD(:,1) - mW(:,1)).^2);

% Arm extension/flexion (biceps/triceps)
vA_theta = vSE_theta + (pi - vEW_theta);

% Wrist extension/flexion
vW_theta = vEW_theta - vWD_theta;

% Plot joint angles
hAx(2) = subplot(2,2,[3 4]);
hold(hAx(2), 'on')
plot(hAx(2), rad2deg(vA_theta), 'r')
plot(hAx(2), rad2deg(vW_theta), 'g')
plot(hAx(2), rad2deg(vSE_theta), 'b')

%plot(hAx(2), rad2deg(vEW_theta), 'k')
%plot(hAx(2), rad2deg(vWD_theta), 'k')
xlabel(hAx(2), 'Time (frames)')
ylabel(hAx(2), 'Angle (deg)')

legend({'Arm extension/flexion', 'Wrist extension/flexion', 'Shoulder extension/flexion'})
legend boxoff

% Export joint angles as MAT file
vArmExtFlex = vA_theta;
vWristExtFlex = vW_theta;
vShoulderExtFlex = vSE_theta;
nFPS = sWT.MovieInfo.FramesPerSecond;
[sPath, sFile, sExt] = fileparts(sWT.MovieInfo.Filename);
sOutFile = fullfile(sPath, [sFile '_JointAngles.mat']);
save(sOutFile, 'vArmExtFlex', 'vWristExtFlex', 'vShoulderExtFlex', 'nFPS')

%%

return
