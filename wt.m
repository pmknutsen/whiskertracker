function wt
% Whisker Tracker (WT)
% Start-up and initialize WT workspace
%

%    WhiskerTracker - Automated whiskertracking in Matlab
%    Copyright (C) 2005-2013  Per M Knutsen <pmknutsen@gmail.com>
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

clc
disp('WhiskerTracker')
disp('Copyright (C) 2005-2013 Per M Knutsen <pmknutsen@gmail.com>')
disp('This program comes with ABSOLUTELY NO WARRANTY. This is free software, and you are')
disp('are welcome to redistribute it under certain conditions; see LICENSE for details.')

% Set paths
sWT_dir = which('wt');
sWT_dir = sWT_dir(1:findstr(sWT_dir, 'wt.m')-1);
path(path, sWT_dir)
path(path, sprintf('%sbin/', sWT_dir))
path(path, sprintf('%slib/', sWT_dir))
path(path, sprintf('%sicons/', sWT_dir))
path(path, sprintf('%sscripts/', sWT_dir))

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
g_tWT.EyeFilter = wt_create_filter(struct('Size', 14, 'Sigma_A', 3, 'Sigma_B', .5, 'Threshold', 256), 'create-only'); % default eye-tracker filter
g_tWT.LabelFilter = wt_create_filter(struct('Size', 10, 'Sigma_A', 1, 'Sigma_B', 2, 'Threshold', 256), 'create-only'); % default whisker-label filter
g_tWT.Movies = [];
g_tWT.MovieInfo = struct('Roi', []);
g_tWT.BatchMode = 0;
g_tWT.Colors = distinguishable_colors(100);

wt_prep_gui

% Splash image
mImg = imread('wt_splash.tif');
imshow(mImg)
set(g_tWT.WTWindow, 'color', 'k')

% Check timestamps on wt.m file. If older than 6 months ask to check for updates
tFiles = dir(sWT_dir);
nSec = etime(datevec(today()), datevec(datenum(tFiles(1).date)));
if nSec > (6*30*60*60*24) % warn if file is older than 6 months
    sAns = questdlg(sprintf('Your version of WhiskerTracker is older than 6 months.\nDo you want to check for updates now?'), ...
        'WhiskerTracker Update', 'Yes', 'No', 'Yes');
    if strcmp(sAns, 'Yes') wt_check_update(); end
end

return
