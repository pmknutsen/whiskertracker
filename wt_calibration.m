function wt_calibration(sOption)
% WT_CALIBRATION Calibrate and measure image regions
% 
%  wt_calibration('calibrate')
%  wt_calibration('measure')
%  wt_calibration('recalculate')

global g_tWT

switch lower(sOption)
    case 'calibrate'
        Calibrate
        wt_display_frame
    case 'calibrate-import-image'
        CalibrateWithImportedImage
        wt_display_frame
    case 'measure'
        Measure
    case 'recalculate'
        RecalculatePixelsPerMM
    otherwise
        Calibrate
        wt_display_frame
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Calibrate
global g_tWT
% Get distance between locations
if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen)
    g_tWT.DisplayMode = 0; % go to absolute view
end
wt_display_frame
hLine = [];
try
    for i = 1:2
        [vX(i) vY(i)] = ginput(1);  % press of return will provide no input
        hLine(end+1) = plot(vX(i), vY(i), 'r.');
    end
catch, return, end
hLine(end+1) = plot(vX, vY, 'r:', 'LineWidth', 1);
nL = round(sqrt(sum([diff(vX).^2 diff(vY).^2])));

% Ask how much the distance corresponds to in millimeters
% Control that input is a number
cAns = [];
sMsg = 'Enter distance in millimeters corresponding to %d pixels.';
while length(str2num(char(cAns))) ~= 1
    cAns = inputdlg(sprintf(sMsg, nL), 'WT Calibrate', 1);
    sMsg = 'Invalid entry (must be a number; do not use comma).\nEnter distance in millimeters corresponding to %d pixels.';
end

delete(hLine)
g_tWT.MovieInfo.CalibCoords = round([vX' vY']);
g_tWT.MovieInfo.CalBarLength = str2num(cAns{1});

RecalculatePixelsPerMM;

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CalibrateWithImportedImage
global g_tWT

[sFilename, sFilepath] = uigetfile({'*.bmp';'*.tiff';'*.gif';'*.jpg';'*.png';'*.*'}, 'Select image file'); % select image file
if ~sFilename return; end % return if user cancelled dialog
mImg = imread([sFilepath sFilename]); % Load image
wt_display_frame; cla % refresh and clear display
imagesc(wt_image_preprocess(mImg)) % Display image

hLine = [];
try
    for i = 1:2
        [vX(i) vY(i)] = ginput(1);  % press of return will provide no input
        hLine(end+1) = plot(vX(i), vY(i), 'r.');
    end
catch, return, end
hLine(end+1) = plot(vX, vY, 'r:', 'LineWidth', 1);
nL = round(sqrt(sum([diff(vX).^2 diff(vY).^2])));

% Ask how much the distance corresponds to in millimeters
% Control that input is a number
cAns = [];
sMsg = 'Enter distance in millimeters corresponding to %d pixels.';
while length(str2num(char(cAns))) ~= 1
    cAns = inputdlg(sprintf(sMsg, nL), 'WT Calibrate', 1);
    sMsg = 'Invalid entry (must be a number; do not use comma).\nEnter distance in millimeters corresponding to %d pixels.';
end

delete(hLine)
g_tWT.MovieInfo.CalibCoords = round([vX' vY']);
g_tWT.MovieInfo.CalBarLength = str2num(cAns{1});

RecalculatePixelsPerMM;

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Measure
% Draw line and measure its length in pixels or mm (if image is calibrated)
% as well as the angle of the line.
global g_tWT

if ~isfield(g_tWT.MovieInfo, 'PixelsPerMM') % create field if it does not exist
    g_tWT.MovieInfo.PixelsPerMM = [];
end

if isempty(g_tWT.MovieInfo.PixelsPerMM) % check image has been calibrated
    sUnit = 'px';
    nPixPerMM = 1;
else
    sUnit = 'mm';
    nPixPerMM = g_tWT.MovieInfo.PixelsPerMM;
end

hLin = [];
try
    for i = 1:2
        [vX(i) vY(i)] = ginput(1);  % press of return will provide no input
        if isempty(hLin)
            hLin = plot(vX(i), vY(i), 'rx-');
        else
            set(hLin, 'XData', vX, 'YData', vY)
        end
    end
catch % in case user pressed Return
    delete(hLin)
end
nDistMM = sqrt(diff(vX)^2 + diff(vY)^2) / nPixPerMM;
% get angle of line
try
    nAngle = wt_get_angle([vX(:) vY(:)], g_tWT.MovieInfo.RefLine, 0);
catch
    nAngle = NaN;
end

hTxt = text(mean(vX), mean(vY), sprintf('%.1f%s, %.1fdeg', nDistMM, sUnit, nAngle), ...
    'Color', 'w', 'BackgroundColor', 'k', 'FontSize', 7, ...
    'HorizontalAlignment', 'center');
set([hLin hTxt], 'UserData', {hLin, hTxt}) % store handles

hCntxtMenu = uicontextmenu;
set([hLin hTxt], 'uicontextmenu',  hCntxtMenu)
uimenu(hCntxtMenu, 'Label', 'Remove', 'Callback', 'vU=get(gco, ''UserData'');delete(vU{1}),delete(vU{2})')

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RecalculatePixelsPerMM
global g_tWT

if sum(sum(g_tWT.MovieInfo.CalibCoords)) == 0, return; end

vX = g_tWT.MovieInfo.CalibCoords(:,1);
vY = g_tWT.MovieInfo.CalibCoords(:,2);

% Store pixels per millimeter
nL = round(sqrt(sum([diff(vX).^2 diff(vY).^2])));
g_tWT.MovieInfo.PixelsPerMM = nL / g_tWT.MovieInfo.CalBarLength;

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
