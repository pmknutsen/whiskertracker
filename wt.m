function wt
% Whisker Tracker (WT)
%
% Start-up and initialize WT workspace
%

% Set paths
sWT_dir = which('wt');
sWT_dir = sWT_dir(1:findstr(sWT_dir, 'wt.m')-1);
sWT_bin_path = sprintf('%sbin/', sWT_dir);
path(path, sWT_dir)
path(path, sWT_bin_path)

% Start WT if not already running
hFig = findobj('CloseRequestFcn', 'wt_exit');
if ~isempty(hFig), return, end

global g_tWT

% Initialize GUI
g_tWT.WTWindow = figure;
set(g_tWT.WTWindow, 'Menubar', 'none', ...
    'Tag', 'WTMainWindow', ...
    'Name', 'WT', ...
    'DoubleBuffer', 'on', ...
    'CloseRequestFcn', 'wt_exit', ...
    'Renderer', 'painters', ...
    'BackingStore', 'on', ...
    'visible', 'off')
movegui(g_tWT.WTWindow, 'center')

% Default parameters
g_tWT.WhiskerWidth = 2;
g_tWT.CompressData = 0;
g_tWT.ShowSR = 0;
g_tWT.AccessedPaths = [];
g_tWT.FiltVec = [];
g_tWT.ShowWhiskerIdentity = 1;
g_tWT.DisplayMode = 0;
g_tWT.TriggerOverlays = 0;
g_tWT.OverlayLocation = 'UpperLeft';
g_tWT.CurrentFrameBuffer.Img = []; % image buffer
g_tWT.CurrentFrameBuffer.Frame = 1;
g_tWT.VerboseMode = 0;
g_tWT.EyeFilter=wt_create_filter(struct('Size', 14, 'Sigma_A', 3, 'Sigma_B', .5, 'Threshold', 256), 'create-only'); % default eye-tracker filter
g_tWT.LabelFilter=wt_create_filter(struct('Size', 10, 'Sigma_A', 1, 'Sigma_B', 2, 'Threshold', 256), 'create-only'); % default whisker-label filter
g_tWT.Movies = [];
g_tWT.MovieInfo = struct('Roi', []);
g_tWT.BatchMode = 0;

g_tWT.Colors = ... % Colors look-up table
   [  0            0         1       % 1 BLUE
   0          0.5            0       % 2 GREEN (medium dark)
   1            0            0       % 3 RED
   0         0.75         0.75       % 4 TURQUOISE
   0.75            0         0.75    % 5 MAGENTA
   0.75         0.75            0    % 6 YELLOW (dark)
   0.8         0.8         0.8       % 7 GREY (very bright)
   1            0.50         0.25    % 8 ORANGE
   0.6          0.5          0.4     % 9 BROWN
   1            1            0  ];   % 10 YELLOW (pale)

% Look-up table for coordinates of stimulus squares
% TODO: REMOVE THIS AND LET USER DEFINE LOCATION OF SQUARES!!!
g_tWT.Stimulus = [ ...
        % Framerate width   height  pos_x1  pos_y1  pos_x2  pos_y2
            500     320     280     19      12      35      12
            1000    240     210     12      12      28      12
            1000    320     156     22      12      38      12 ];

wt_prep_gui;

% Splash image
mImg = imread('wt_splash.tif');
imshow(mImg)
set(g_tWT.WTWindow, 'color', 'k')

return
