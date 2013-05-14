function wt_set_parameters(varargin)
% wt_set_parameters

global g_tWT

% If no movie is loaded, do not open Parameters dialog
bMovieLoaded = 0;
if isfield(g_tWT.MovieInfo, 'Filename')
    if ~isempty(g_tWT.MovieInfo.Filename)
        bMovieLoaded = 1;
    end
end
if ~bMovieLoaded, return, end

% Execute sub-function
if nargin > 0
    switch varargin{1}
        case 'apply'
            ApplyParams
        case 'updatevars'
            UpdateVars(varargin{2});
        case 'loadparams'
            LoadParams;
        case 'saveparams'
            SaveParams;
        case 'savedefaultparams'
            SaveDefaultParams;
    end
    return;
end

global g_hOptWin;
if ~isempty(g_hOptWin), figure(g_hOptWin), return, end

%%%% Start of field data %%%%

% FORMAT OF PARAMETERS FIELD STRUCTURE
% {DESCRIPTION, DEFAULT_VALUE, OPTION, TARGET_VARIABLE}
global g_tOptFields; g_tOptFields = [];
global g_cFieldNames; g_cFieldNames = [];
g_tOptFields.nDisplayTitle   = {'Display', '', 'title', ''};
g_tOptFields.nRotate         = {'Rotate image (deg)', num2str(g_tWT.MovieInfo.Rot), '', 'g_tWT.MovieInfo.Rot'};
g_tOptFields.vFlip           = {'Flip image (up-down left-right)', num2str(g_tWT.MovieInfo.Flip), '', 'g_tWT.MovieInfo.Flip'};
g_tOptFields.vROI            = {'Region of interest [x y width height]', num2str(g_tWT.MovieInfo.Roi), '', 'g_tWT.MovieInfo.Roi'};
g_tOptFields.nRefresh        = {'Interval between refresh (frames)', num2str(g_tWT.MovieInfo.ScreenRefresh), '', 'g_tWT.MovieInfo.ScreenRefresh'};
g_tOptFields.nLoadFrames     = {'Pre-load (frames)', num2str(g_tWT.MovieInfo.NoFramesToLoad), '', 'g_tWT.MovieInfo.NoFramesToLoad'};

g_tOptFields.nHeadTitle      = {'Coordinates of reference line', '', 'title', ''};
g_tOptFields.vHeadA          = {'Point A', num2str(g_tWT.MovieInfo.RefLine(1,:)), '', 'g_tWT.MovieInfo.RefLine(1,:)'};
g_tOptFields.vHeadB          = {'Point B', num2str(g_tWT.MovieInfo.RefLine(2,:)), '', 'g_tWT.MovieInfo.RefLine(2,:)'};
g_tOptFields.nFindWhiskTitle = {'Whisker tracking parameters', '', 'title', ''};
g_tOptFields.nHorJitterSlow  = {'Horizontal jitter [left mid right] SLOW >', num2str(g_tWT.MovieInfo.HorJitterSlow), '', 'g_tWT.MovieInfo.HorJitterSlow'};
g_tOptFields.nHorJitter      = {'Horizontal jitter [left mid right] FAST >>', num2str(g_tWT.MovieInfo.HorJitter), '', 'g_tWT.MovieInfo.HorJitter'};
g_tOptFields.nHorJitter      = {'Horizontal jitter [left mid right] FAST >>', num2str(g_tWT.MovieInfo.HorJitter), '', 'g_tWT.MovieInfo.HorJitter'};
g_tOptFields.nHorAutoThresh  = {'Speed-select threshold (deg)', num2str(g_tWT.MovieInfo.nHorAutoThresh), '', 'g_tWT.MovieInfo.nHorAutoThresh'};

g_tOptFields.nVertJitter     = {'Radial jitter of mid-point', num2str(g_tWT.MovieInfo.RadJitter), '', 'g_tWT.MovieInfo.RadJitter'};
g_tOptFields.nWhiskerWidth   = {'Whisker filter-width', num2str(g_tWT.MovieInfo.WhiskerWidth), '', 'g_tWT.MovieInfo.WhiskerWidth'};
g_tOptFields.nFilterLength   = {'Width of local-angle filters', num2str(g_tWT.MovieInfo.FilterLen), '', 'g_tWT.MovieInfo.FilterLen'};
g_tOptFields.nImageProcTitle = {'Image pre-processing', '', 'title', ''};

% Construct string to display in background frames input field
vFr = g_tWT.MovieInfo.AverageFrames;
sStr = sprintf('[%s]', sprintf('%d %d; ', vFr'));
sStr = sprintf('%s]', sStr(1:findstr('; ]', sStr)-1));
g_tOptFields.vAvgFrames      = {'Background frames [from to]', sStr, '', 'g_tWT.MovieInfo.AverageFrames'};
g_tOptFields.nBGFrameLowPass = {'Low-pass background image (pixels)', num2str(g_tWT.MovieInfo.BGFrameLowPass), '', 'g_tWT.MovieInfo.BGFrameLowPass'};
g_tOptFields.nInvert         = {'Invert contrast', num2str(g_tWT.MovieInfo.Invert), '', 'g_tWT.MovieInfo.Invert'};

g_tOptFields.nPosIntTitle    = {'Position extrapolation', '', 'title', ''};
g_tOptFields.nPosIntOn       = {'Enable (0/1)', num2str(g_tWT.MovieInfo.UsePosExtrap), '', 'g_tWT.MovieInfo.UsePosExtrap'};
g_tOptFields.nGaussHw        = {'Scale filter by factor of', num2str(g_tWT.MovieInfo.ExtrapFiltHw), '', 'g_tWT.MovieInfo.ExtrapFiltHw'};

g_tOptFields.nAngleCalc      = {'Angle calculation', '', 'title', ''};
g_tOptFields.nDelta          = {'Pixels from base', num2str(g_tWT.MovieInfo.AngleDelta), '', 'g_tWT.MovieInfo.AngleDelta'};
g_tOptFields.nCalibTitle     = {'Calibration', '', 'title', ''};
g_tOptFields.nCalBarLength   = {'Length of calibration bar (mm)', num2str(g_tWT.MovieInfo.CalBarLength), '', 'g_tWT.MovieInfo.CalBarLength'};

vFr = g_tWT.MovieInfo.CalibCoords;
sStr = sprintf('[%s]', sprintf('%d %d; ', vFr'));
sStr = sprintf('%s]', sStr(1:findstr('; ]', sStr)-1));
g_tOptFields.mCalibCoords    = {'Calibration marks [Xa Ya; Xb Yb]', sStr, '', 'g_tWT.MovieInfo.CalibCoords'};

%%%% End of field data %%%%

% GUI Parameters
nGuiElements = size(fieldnames(g_tOptFields), 1);
nFontSize = 8;
nLinSep = 6;
vScrnSize = get(0, 'ScreenSize');
nFigHeight = nGuiElements * (nFontSize*2 + nLinSep) + 50;
nFigWidth = 500;
nTxtColRatio = 3/5; % portion of figure width occupied by the text column
vFigPos = [(vScrnSize(3)/2)-(nFigWidth/2) (vScrnSize(4)/2)-(nFigHeight/2) nFigWidth nFigHeight];
g_hOptWin = figure;

set(g_hOptWin, 'NumberTitle', 'off', 'Position', vFigPos, 'MenuBar', 'none', 'DeleteFcn', 'clear global g_hOptWin')

nTxtColWidth = nFigWidth*nTxtColRatio; % width of descriptive text column
nEdtColWidth = nFigWidth-nTxtColWidth; % width of input field column

% Place GUI elements on the figure
nCurrLine = nFigHeight;
g_cFieldNames = fieldnames(g_tOptFields);
hEdt = [];
for f = 1:nGuiElements    
    nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
    % Separator if applicable
    if strcmp('title',  g_tOptFields.(char(g_cFieldNames(f)))(:,3)  )
        uicontrol(g_hOptWin, 'Style', 'text', 'Position', [0 nCurrLine nTxtColWidth 20], ...
            'String', sprintf(' %s', char(g_tOptFields.(char(g_cFieldNames(f)))(:,1))), ...
            'HorizontalAlignment', 'left', ...
            'FontWeight', 'bold', ...
            'BackgroundColor', [.8 .8 .8] );
        continue
    end
    
    % Text
    uicontrol(g_hOptWin, 'Style', 'text', 'Position', [0 nCurrLine nTxtColWidth 20], ...
        'String', sprintf('    %s', char(g_tOptFields.(char(g_cFieldNames(f)))(:,1))), ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [.8 .8 .8] );
    % Input field
    hEdt = uicontrol(g_hOptWin, 'Style', 'edit', 'Position', [nTxtColWidth nCurrLine nEdtColWidth 20], ...
        'String', g_tOptFields.(char(g_cFieldNames(f)))(:,2), ...
        'HorizontalAlignment', 'center', 'Tag', char(g_cFieldNames(f)));
    set(hEdt(end), 'Callback', ...
        [sprintf('global g_tOptFields; g_tOptFields.(''%s'')(:,2) = get(gco, ''String'');', char(g_cFieldNames(f)))] )
end

% Load button
uicontrol(g_hOptWin, 'Style', 'pushbutton', ...
    'string', 'Load', ...
    'position', [nFigWidth/2-185 10 50 20], ...
    'Callback', ['wt_set_parameters(''loadparams'')'])

% Save button
uicontrol(g_hOptWin, 'Style', 'pushbutton', ...
    'string', 'Save', ...
    'position', [nFigWidth/2-125 10 50 20], ...
    'Callback', ['wt_set_parameters(''saveparams'')'])

% Save As Default button
uicontrol(g_hOptWin, 'Style', 'pushbutton', ...
    'string', 'Save as default', ...
    'position', [nFigWidth/2-65 10 120 20], ...
    'Callback', ['wt_set_parameters(''savedefaultparams'')'])

set(g_hOptWin, 'userdata', nGuiElements);

% 'Apply' button
uicontrol(g_hOptWin, 'Style', 'pushbutton', ...
    'string', 'Apply (B)', ...
    'position', [nFigWidth/2+65 10 60 20], ...
    'Callback', @ApplyParams)
    
% 'Done' button
uicontrol(g_hOptWin, 'Style', 'pushbutton', ...
    'string', 'Done', ...
    'position', [nFigWidth/2+135 10 50 20], ...
    'Callback', @DoneParams )

return;

%%%% LOAD PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LoadParams
global g_tOptFields g_hOptWin;

% Load .mat file
[sFilename, sPathname] = uigetfile('*.mat', 'Select parameters file');
if sFilename==0
    return
end
load(sprintf('%s%s', sPathname, sFilename));
pause(0.5);

% Update gui
cFieldnames = fieldnames(g_tOptFields);
for e = 1:size(fieldnames(g_tOptFields),1)
    h = findobj(g_hOptWin, 'Tag', char(cFieldnames(e)));
    if ~isempty(h)
        set(h, 'String', g_tOptFields.(char(cFieldnames(e)))(2));
    end
end

return;


%%%% SAVE PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SaveParams
global g_tOptFields

% Save .mat file
[sFilename, sPathname] = uiputfile('wt_default_parameters.mat', 'Save parameters as...');
if sFilename==0
    return
end
pause(0.5);
save(sprintf('%s%s', sPathname, sFilename), 'g_tOptFields');

return;

%%%% SAVE DEFAULT PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SaveDefaultParams
global g_tOptFields

% Save .m file
sFilename = 'wt_default_parameters.mat';
sPathname = 'C:\';
save(sprintf('%s%s', sPathname, sFilename), 'g_tOptFields');

return;

%%%% UPDATE VARS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function UpdateVars(nGuiElements)
global g_tWT
global g_cFieldNames;
global g_tOptFields;

g_tWT.FiltVec = [];

% Update global variables with the new
for f = 1:nGuiElements
    cTargetVar = char(g_tOptFields.(char(g_cFieldNames(f)))(:,4));
    if ~isempty(cTargetVar)
        eval(sprintf('%s = [%s];', cTargetVar, char(g_tOptFields.(char(g_cFieldNames(f)))(:,2))));
    end
end

return;

%%%% APPLY Params %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ApplyParams(varargin)

global g_hOptWin;

% Enable Redo on this function
wt_batch_redo('wt_set_parameters(''apply'')')

nGuiElements = get(g_hOptWin, 'userdata');
wt_set_parameters('updatevars', nGuiElements);
wt_calibration('recalculate');
wt_update_window_title_status;
wt_display_frame;

figure(g_hOptWin);
return;

%%%% DONE Params %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoneParams(varargin)
global g_hOptWin;

nGuiElements = get(g_hOptWin, 'userdata');

wt_set_parameters('updatevars', nGuiElements);
wt_calibration('recalculate');
wt_update_window_title_status;

close(g_hOptWin);
clear global g_cFieldNames;
clear global g_tOptFields;
wt_display_frame;

return;
