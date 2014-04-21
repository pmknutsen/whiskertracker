function wt_prep_gui
% WT_PREP_GUI
% Open and initialize main WT window and GUI elements (menu, slider etc)
%

global g_tWT

hFrameWin = findobj('Tag', 'WTMainWindow');
set(hFrameWin, 'color', [.8 .8 .8])

figure(hFrameWin);
clf;
g_tWT.Handles.hSlider = [];
set(hFrameWin, 'NumberTitle', 'off', 'Name', 'Whisker Tracker', ...
    'resizeFcn', ['wt_resize_slider'])

g_tWT.FrameAx = axes;
set(g_tWT.FrameAx, 'Visible', 'off', ...
    'buttondownfcn', ['global g_tWT; g_sLastBtnPress = get(gcf,''selectiontype'')'], ...
    'DrawMode', 'fast', ...
    'Position', [.025 .075 .95 .93] );

% Create toolbar
sPath = which('wt');
sPath = [sPath(1:end-4) 'icons/'];
hToolbar = uitoolbar('Parent', g_tWT.WTWindow, 'Tag', 'WT_Toolbar');

mCData = im2double(imread([sPath 'tool_open.png'])); mCData(mCData == 0) = NaN; % open
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'WT_Toolbar_Open', 'TooltipString', 'Open file', 'ClickedCallback', ['wt_select_file']);

mCData = im2double(imread([sPath 'tool_save.png'])); mCData(mCData == 0) = NaN; % save
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'WT_Toolbar_Save', 'TooltipString', 'Save', 'ClickedCallback', ['wt_save_data']);

mCData = im2double(imread([sPath 'tool_zoom_in.png'])); mCData(mCData == 0) = NaN; % zoom in
uitoggletool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_ZoomOut', 'TooltipString', 'Zoom in', 'ClickedCallback', ['switch get(gcbo,''state''),case ''on'',zoom on; case ''off'',zoom off;end'], 'separator', 'on');

[mCData, mCM] = imread([sPath 'tools_table.gif']); mCData = ind2rgb(mCData, mCM); mCData(mCData == 1) = NaN; % parameters
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_EditParameters', 'TooltipString', 'Edit Parameters', 'ClickedCallback', ['wt_set_parameters']);

mCData = im2double(imread([sPath 'tool_plottools_show.png'])); mCData(mCData == 0) = NaN;
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_PanRight', 'TooltipString', 'Auto-resize window', 'ClickedCallback', ['wt_autosize_window']);

[mCData, mCM] = imread([sPath 'tool_rotate_counterclockwise.gif']); mCData = ind2rgb(mCData, mCM); mCData(mCData == 1) = NaN; % parameters
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_RotateAntiClockwise', 'TooltipString', 'Rotate Counter-Clockwise', 'ClickedCallback', ['wt_rotate_frame(-1); wt_batch_redo(''wt_rotate_frame(-1)'')'], 'separator', 'on');
[mCData, mCM] = imread([sPath 'tool_rotate_clockwise.gif']); mCData = ind2rgb(mCData, mCM); mCData(mCData == 1) = NaN; % parameters
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_RotateClockwise', 'TooltipString', 'Rotate Clockwise', 'ClickedCallback', ['wt_rotate_frame(1); wt_batch_redo(''wt_rotate_frame(1)'')']);
[mCData, mCM] = imread([sPath 'tool_flip_horizontal.gif']); mCData = ind2rgb(mCData, mCM); mCData(mCData == 1) = NaN; % parameters
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_RotateClockwise', 'TooltipString', 'Flip Horizontally', 'ClickedCallback', ['wt_flip_frame(''leftright''); wt_batch_redo(''wt_flip_frame(''''leftright'''')'')']);
[mCData, mCM] = imread([sPath 'tool_flip_vertical.gif']); mCData = ind2rgb(mCData, mCM); mCData(mCData == 1) = NaN; % parameters
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_RotateClockwise', 'TooltipString', 'Flip Vertically', 'ClickedCallback', ['wt_flip_frame(''updown''); wt_batch_redo(''wt_flip_frame(''''updown'''')'')']);

[mCData, mCM] = imread([sPath 'right.gif']); mCData = ind2rgb(mCData, mCM); mCData(mCData == 1) = NaN; % Start tracking SLOW
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_PanRight', 'TooltipString', 'Track SLOW', 'ClickedCallback', ['global g_tWT;g_tWT.StopProc=0;wt_track_auto(''slow'')'], 'separator', 'on');

[mCData, mCM] = imread([sPath 'right_double.gif']); mCData = ind2rgb(mCData, mCM); mCData(mCData == 1) = NaN; % Start tracking FAST
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_PanRight', 'TooltipString', 'Track FAST', 'ClickedCallback', ['global g_tWT;g_tWT.StopProc=0;wt_track_auto(''fast'')']);

mCData = im2double(imread([sPath 'cancel.png'])); mCData(mCData == 0) = NaN;
uipushtool('Parent', hToolbar, 'cdata', mCData, 'Tag', 'Spiky_WaitbarAction_CancelTracking', 'TooltipString', 'Cancel Tracking', 'ClickedCallback', ['global g_tWT; g_tWT.StopProc = 1;']);

% Menu
hFile = uimenu(hFrameWin, 'Label', 'File');
uimenu(hFrameWin, 'Label','Open...', 'Parent', hFile, 'Callback', ['wt_select_file'], 'accelerator', 'O');
uimenu(hFrameWin, 'Label','Open Directory...', 'Parent', hFile, 'Callback', ['wt_select_directory'], 'accelerator', 'D');
uimenu(hFrameWin, 'Label','Open Directory Tree...', 'Parent', hFile, 'Callback', ['wt_select_directory_tree'], 'accelerator', 'T');
uimenu(hFrameWin, 'Label','Open Selection...', 'Parent', hFile, 'Callback', ['wt_select_batchfile']);

% Produce list of loaded movies
if ~isempty(g_tWT.Movies)

    uimenu(hFrameWin, 'Label','Load Data...', 'Parent', hFile, 'Callback', ['wt_load_data(''deffile'')'], 'Separator', 'on');
    uimenu(hFrameWin, 'Label','Save', 'Parent', hFile, 'Callback', ['wt_save_data'], 'accelerator', 'S');
    uimenu(hFrameWin, 'Label','Save As...', 'Parent', hFile, 'Callback', ['wt_save_data(''defpath'')']);
    uimenu(hFrameWin, 'Label','Reset Current File', 'Parent', hFile, 'Callback', ['wt_reset_all; wt_batch_redo(''wt_reset_all'')'], 'checked', 'on');

    hMovies = uimenu(hFrameWin, 'Label', 'Movies', 'Parent', hFile, 'Separator', 'on');
    uimenu(hFrameWin, 'Label','Previous...', 'Parent', hFile, 'Callback', ['wt_load_movie(-1)']);
    uimenu(hFrameWin, 'Label','Next...', 'Parent', hFile, 'Callback', ['wt_load_movie(0)'], 'accelerator', 'N');
    for m = 1:size(g_tWT.Movies,2)
        % Menu item label; limit to 50 chars long
        sLabel = sprintf('%s', g_tWT.Movies(m).filename);
        if length(sLabel) > 50
            sLabel = ['..' sLabel(end-47:end)];
        end
        hCurrFile = uimenu(hFrameWin, 'Label', sLabel, 'Parent', hMovies, 'Callback', [sprintf('wt_load_movie(%d)', m)]);
        % Tick off to indicate if movie already has an associated .mat file
        if exist(sprintf('%smat', g_tWT.Movies(m).filename(1:findstr('.avi', g_tWT.Movies(m).filename))), 'file') ...
                || exist(sprintf('%smat.gz', g_tWT.Movies(m).filename(1:findstr('.avi', g_tWT.Movies(m).filename))), 'file')
            set(hCurrFile, 'checked', 'on')
        end
    end

    % Whiskers
    hWhiskers = uimenu(hFrameWin, 'Label', 'Whiskers');
    uimenu(hFrameWin, 'Label','New...', 'Parent', hWhiskers, 'Callback', 'wt_mark_whisker', 'accelerator', 'W');
    uimenu(hFrameWin, 'Label','Paste', 'Parent', hWhiskers, 'Callback', ['wt_copy_paste_whisker(''paste'', NaN); wt_batch_redo(''wt_copy_paste_whisker(''''paste'''', NaN)'');'], 'accelerator', 'V', 'checked', 'on');
    uimenu(hFrameWin, 'Label','Delete...', 'Parent', hWhiskers, 'Callback', 'wt_clear_selected_whisker');
    uimenu(hFrameWin, 'Label','Delete All', 'Parent', hWhiskers, 'Callback', ['wt_clear_whisker(''all''); wt_batch_redo(''wt_clear_whisker(''''all'''')'')'], 'checked', 'on');

    uimenu(hFrameWin, 'Label','Track - Slow', 'Parent', hWhiskers, 'Callback', ['wt_track_auto(''slow'');wt_batch_redo(''wt_track_auto(''''slow'''')'');'], 'Separator', 'on', 'checked', 'on');
    uimenu(hFrameWin, 'Label','Track - Fast', 'Parent', hWhiskers, 'Callback', ['wt_track_auto(''fast'');wt_batch_redo(''wt_track_auto(''''fast'''')'');'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Auto Select Speed', 'Parent', hWhiskers, 'Callback', ['wt_track_auto(''auto'');wt_batch_redo(''wt_track_auto(''''auto'''')'');'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Set Tracking Range', 'Parent', hWhiskers, 'Callback', 'wt_set_tracking_range()');
    uimenu(hFrameWin, 'Label','Reposition Whiskers', 'Parent', hWhiskers, 'Callback', ['wt_repositioning();wt_batch_redo(''wt_repositioning()'');'], 'checked', 'on');
    
    % Whisker labels
    hLabels = uimenu(hFrameWin, 'Label', 'Whisker Labels', 'Parent', hWhiskers, 'Separator', 'on');
    uimenu(hFrameWin, 'Label','Track Labels', 'Parent', hLabels, 'Callback', ['wt_track_whisker_label(0,''continue-all'',0); wt_batch_redo(''wt_track_whisker_label(0,''''continue-all'''',0)'')'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Label Filter...', 'Parent', hLabels, 'Callback', ['global g_tWT; g_tWT.LabelFilter=wt_create_filter(g_tWT.LabelFilter);']);
    uimenu(hFrameWin, 'Label','Mark Whisker and Label...', 'Parent', hLabels, 'Callback', ['wt_mark_whisker_and_label;']);
    uimenu(hFrameWin, 'Label','Clear Labels', 'Parent', hLabels, 'Callback', ['wt_track_whisker_label(0, ''delete-all''); wt_batch_redo(''wt_track_whisker_label(0,''''delete-all'''');'')'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Extend Whiskers', 'Parent', hLabels, 'Callback', ['wt_track_whiskers_with_labels('''','''',[],[])'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Label Names', 'Parent', hLabels, 'Callback', 'wt_toggle_show_label_identity')

    uimenu(hFrameWin, 'Label','Set Last Frame...', 'Parent', hWhiskers, 'Callback', 'wt_set_last_frame', 'Separator', 'on');
    uimenu(hFrameWin, 'Label', 'Whisker Display Width...', 'Parent', hWhiskers, 'Callback', 'wt_change_whisker_width')
    uimenu(hFrameWin, 'Label', 'Show Whisker Identities', 'Parent', hWhiskers, 'Callback', 'wt_toggle_show_identity')
    uimenu(hFrameWin, 'Label', 'Hide Whiskers', 'Parent', hWhiskers, 'Callback', 'wt_toggle_whisker_visibility')
        
    % Head related menu items
    hHead = uimenu(hFrameWin, 'Label', 'Head');
    uimenu(hFrameWin, 'Label','Track Head', 'Parent', hHead, 'Callback', ['wt_init_head_tracker']);
    uimenu(hFrameWin, 'Label','Set Head Position...', 'Parent', hHead, 'Callback', ['wt_init_head_tracker(''static_head'')']);
    uimenu(hFrameWin, 'Label','Configure Eye Filter...', 'Parent', hHead, 'Callback', ['global g_tWT; g_tWT.EyeFilter=wt_create_filter(g_tWT.EyeFilter);'], 'separator', 'on');
    uimenu(hFrameWin, 'Label','Clean Head Movements', 'Parent', hHead, 'Callback', ['wt_clean_splines(0)']);    
    uimenu(hFrameWin, 'Label','Reset Head Tracking', 'Parent', hHead, 'Callback', ['global g_tWT;g_tWT.MovieInfo.RightEye=[];g_tWT.MovieInfo.LeftEye=[];g_tWT.MovieInfo.Nose=[];g_tWT.MovieInfo.EyeNoseAxLen=[];wt_display_frame;']);
    
    % Image options
    hImage = uimenu(hFrameWin, 'Label', 'View');
    uimenu(hFrameWin, 'Label','Select ROI', 'Parent', hImage, 'Callback', ['wt_select_roi']);
    uimenu(hFrameWin, 'Label','Toggle View Mode', 'Parent', hImage, 'Callback', 'wt_toggle_display_mode');

    hTriggers = uimenu(hFrameWin, 'Label', 'Triggers', 'Parent', hImage);
    uimenu(hFrameWin, 'Label','Show Overlays', 'Parent', hTriggers, 'Callback', 'wt_toggle_trigger_overlays');
    uimenu(hFrameWin, 'Label','Overlay Location', 'Parent', hTriggers, 'Callback', 'wt_set_overlay_location');
    uimenu(hFrameWin, 'Label','Track Trigger...', 'Parent', hTriggers, 'Callback', ['wt_track_stimulus; wt_batch_redo(''wt_track_stimulus'')'], 'checked', 'on');
    
    uimenu(hFrameWin, 'Label','Rotate 90° Clockwise', 'Parent', hImage, 'Callback', ['wt_rotate_frame(1); wt_batch_redo(''wt_rotate_frame(1)'')'], 'Separator', 'on', 'accelerator', 'c', 'checked', 'on');
    uimenu(hFrameWin, 'Label','Rotate 90° Counter-Clockwise', 'Parent', hImage, 'Callback', ['wt_rotate_frame(-1); wt_batch_redo(''wt_rotate_frame(-1)'')'], 'accelerator', 'a', 'checked', 'on');
    uimenu(hFrameWin, 'Label','Flip Vertically', 'Parent', hImage, 'Callback', ['wt_flip_frame(''updown''); wt_batch_redo(''wt_flip_frame(''''updown'''')'')'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Flip Horizontally', 'Parent', hImage, 'Callback', ['wt_flip_frame(''leftright''); wt_batch_redo(''wt_flip_frame(''''leftright'''')'')'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Refresh', 'Parent', hImage, 'Callback', ['wt_prep_gui; wt_display_frame'], 'Separator', 'on', 'accelerator', 'R');
    uimenu(hFrameWin, 'Label','Hide', 'Parent', hImage, 'Callback', ['wt_toggle_imageshow'], 'accelerator', 'H');
    uimenu(hFrameWin, 'Label','Go To Frame...', 'Parent', hImage, 'Callback', @GoToFrame, 'accelerator', 'G');
    
    % Measure menu
    hImage = uimenu(hFrameWin, 'Label', 'Measure');

    uimenu(hFrameWin, 'Label','Plot...', 'Parent', hImage, 'Callback', ['wt_graphs']);
    hCompute = uimenu(hFrameWin, 'Label', 'Compute', 'Parent', hImage);
    uimenu(hFrameWin, 'Label', 'All Parameters', 'Parent', hCompute, 'Callback', ['wt_compute_kinematics(''all'', 0); wt_batch_redo(''wt_compute_kinematics(''''all'''',0)'');'], 'checked', 'on');
    uimenu(hFrameWin, 'Label', 'Angle', 'Parent', hCompute, 'Callback', ['wt_compute_kinematics(''angle'', 0); wt_batch_redo(''wt_compute_kinematics(''''angle'''',0)'');'], 'Separator', 'on', 'checked', 'on');
    uimenu(hFrameWin, 'Label', 'Curvature', 'Parent', hCompute, 'Callback', ['wt_compute_kinematics(''curvature'', 0); wt_batch_redo(''wt_compute_kinematics(''''curvature'''',0)'');'], 'checked', 'on');
    uimenu(hFrameWin, 'Label', 'Object Distance', 'Parent', hCompute, 'Callback', ['wt_compute_kinematics(''objectdist'', 0); wt_batch_redo(''wt_compute_kinematics(''''objectdist'''',0)'');'], 'checked', 'on');
    
    uimenu(hFrameWin, 'Label','Set Reference Angle...', 'Parent', hImage, 'Callback', 'wt_set_reference_line', 'Separator', 'on');
    uimenu(hFrameWin, 'Label','Use Default Reference Angle', 'Parent', hImage, 'Callback', 'wt_set_default_reference_line; wt_batch_redo(''wt_set_default_reference_line'')', 'checked', 'on');

    hCalibrate = uimenu(hFrameWin, 'Label','Calibrate...', 'Parent', hImage, 'Separator', 'on');
    uimenu(hFrameWin, 'Label','Calibrate...', 'Parent', hCalibrate, 'Callback', ['wt_calibration(''calibrate'')']);
    uimenu(hFrameWin, 'Label','Calibrate With Image...', 'Parent', hCalibrate, 'Callback', ['wt_calibration(''calibrate-import-image'')']);
    uimenu(hFrameWin, 'Label','Measure Line...', 'Parent', hCalibrate, 'Callback', ['wt_calibration(''measure'')']);
    
    hOutlines = uimenu(hFrameWin, 'Label', 'Outlines', 'Parent', hImage);
    uimenu(hFrameWin, 'Label','Create Outline', 'Parent', hOutlines, 'Callback', ['wt_create_outline(''add'')']);
    uimenu(hFrameWin, 'Label','Paste Outline', 'Parent', hOutlines, 'Callback', ['wt_create_outline(''paste'', NaN); wt_batch_redo(''wt_create_outline(''''paste'''', NaN)'')'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Delete All Outlines', 'Parent', hOutlines, 'Callback', ['wt_create_outline(''deleteall'', NaN); wt_batch_redo(''wt_create_outline(''''deleteall'''', NaN)'')'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Hide Outlines', 'Parent', hOutlines, 'Callback', ['wt_create_outline(''hide'')']);

end

% Options menu
hOptions = uimenu(hFrameWin, 'Label', 'Options');

hScripts = uimenu(hFrameWin, 'Label', 'Scripts', 'Parent', hOptions);
uimenu(hFrameWin, 'Label', 'Run Script...', 'Parent', hScripts, 'Callback', ['wt_run_script'], 'checked', 'on');
uimenu(hFrameWin, 'Label', 'Run Batch Script...', 'Parent', hScripts, 'Callback', ['wt_run_script(''batch'')']);
uimenu(hFrameWin, 'Label', 'Get Script Help...', 'Parent', hScripts, 'Callback', ['wt_run_script_help']);

% Get list of existing scripts in ./scripts directory
sPath = which('wt');
sPath = checkfilename([sPath(1:end-4) 'scripts\']);
tFiles = dir(sPath);
bFirst = 1;
for f = 1:length(tFiles)
    if ~isempty(strfind(tFiles(f).name, '.m')) & isempty(strfind(tFiles(f).name, '.m~'))
        sName = strrep(tFiles(f).name(1:end-2), '_', ' ');
        vIndx = strfind(sName, ' ');
        sName([1 vIndx+1]) = upper(sName([1 vIndx+1]));
        if bFirst
            uimenu(hFrameWin, 'Label', sName, 'Parent', hScripts, 'Callback', [sprintf('wt_run_script(''%s'')', tFiles(f).name)], 'Separator', 'on');
            bFirst = 0;
        else
            uimenu(hFrameWin, 'Label', sName, 'Parent', hScripts, 'Callback', [sprintf('wt_run_script(''%s'')', tFiles(f).name)]);
        end
    end
end

if ~isempty(g_tWT.Movies)
    uimenu(hFrameWin, 'Label', 'Batch Redo', 'Parent', hOptions, 'Callback', 'wt_batch_redo(''redo'')', 'accelerator', 'B');

    uimenu(hFrameWin, 'Label', 'Parameters...', 'Parent', hOptions, 'Callback', 'wt_set_parameters', 'accelerator', 'P');
    uimenu(hFrameWin, 'Label', 'User Variables...', 'Parent', hOptions, 'Callback', ['wt_user_variables;wt_batch_redo(''wt_user_variables(''''copyfrommem'''')'')'], 'accelerator', 'U', 'checked', 'on');

    uimenu(hFrameWin, 'Label','Signal-to-Noise', 'Parent', hOptions, 'Callback', 'wt_toggle_signal_noise', 'Separator', 'on');
    uimenu(hFrameWin, 'Label','Notes...', 'Parent', hOptions, 'Callback', 'wt_edit_notes', 'accelerator', 'e');
    uimenu(hFrameWin, 'Label','Debug Window', 'Parent', hOptions, 'Callback', 'wt_toggle_verbose');
    uimenu(hFrameWin, 'Label','Use Parallel Processing', 'Parent', hOptions, 'Callback', 'wt_toggle_parallel', 'checked', 'on');
    uimenu(hFrameWin, 'Label','Compress Datafiles', 'Parent', hOptions, 'Callback', 'wt_toggle_datacompress', 'Separator', 'on');
    uimenu(hFrameWin, 'Label','Uncompress Movie', 'Parent', hOptions, 'Callback', 'wt_uncompress_movie');
    uimenu(hFrameWin, 'Label','Play Movie', 'Parent', hOptions, 'Callback', 'wt_play_movie', 'Separator', 'on', 'accelerator', 'M');
    uimenu(hFrameWin, 'Label','Movie Preview', 'Parent', hOptions, 'Callback', ['wt_play_movie(''preview''); wt_batch_redo(''wt_play_movie(''''preview'''')'');'], 'checked', 'on');
    uimenu(hFrameWin, 'Label','Save Movie', 'Parent', hOptions, 'Callback', 'wt_play_movie(''save'')');
    uimenu(hFrameWin, 'Label','Dump Screen...', 'Parent', hOptions, 'Callback', 'wt_dump_screen', 'Separator', 'on');
end

% Help menu
hHelp = uimenu(hFrameWin, 'Label', 'Help');
uimenu(hFrameWin, 'Label','&Tip of the day', 'Parent', hHelp, 'Callback', 'wt_tip_of_the_day');
uimenu(hFrameWin, 'Label','&Version', 'Parent', hHelp, 'Callback', 'wt_get_build_number');
uimenu(hFrameWin, 'Label','&Check for Updates', 'Parent', hHelp, 'Callback', 'wt_check_update');
uimenu(hFrameWin, 'Label','&License', 'Parent', hHelp, 'Callback', 'wt_show_license');
uimenu(hFrameWin, 'Label','&About WT', 'Parent', hHelp, 'Callback', 'wt_about_wt');

if ~isempty(g_tWT.Movies)
    % 'Go to frame' push-button
    g_tWT.Handles.hGoToButton = uicontrol(g_tWT.WTWindow, 'units', 'normalized' ...
        , 'Position', [.88 .025 .07 .03] ... % fig opos = .05 .05 .9 .9
        , 'Style', 'edit' ...
        , 'String', '' ...
        , 'Tag', 'goto_edit' ...
        , 'tooltipString', 'Enter value of frame to go to and press Enter' ...
        , 'Callback', ['wt_display_frame(str2num(get(gco,''string'')))'] );
    % Fix height in pixels
    set(g_tWT.Handles.hGoToButton, 'units', 'pixels');
    vPos = get(g_tWT.Handles.hGoToButton, 'position');
    set(g_tWT.Handles.hGoToButton, 'Position', [vPos(1) 20 vPos(3) 17]);
    
    % 'Go to last tracked frame' push button
    g_tWT.Handles.hGoToEndButton = uicontrol(g_tWT.WTWindow, 'units', 'normalized' ...
        , 'Position', [.95 .025 .03 .03] ... % fig opos = .05 .05 .9 .9
        , 'Style', 'pushbutton' ...
        , 'String', 'E' ...
        , 'Tag', 'goto_button' ...
        , 'tooltipString', 'Go to last whisker-tracked frame' ...
        , 'CallBack', @GotoLastFrame );
    % Fix button height in pixels
    set(g_tWT.Handles.hGoToEndButton, 'units', 'pixels');
    vPos = get(g_tWT.Handles.hGoToEndButton, 'position');
    set(g_tWT.Handles.hGoToEndButton, 'Position', [vPos(1) 20 vPos(3) 17]);
    
    % 'Go to first tracked frame' push button
    g_tWT.Handles.hGoToFirstButton = uicontrol(g_tWT.WTWindow, 'units', 'normalized' ...
        , 'Position', [.02 .025 .03 .03] ... % fig opos = .05 .05 .9 .9
        , 'Style', 'pushbutton' ...
        , 'String', '1' ...
        , 'Tag', 'goto_firstframe' ...
        , 'tooltipString', 'Go to first frame in movie' ...
        , 'CallBack', @GotoFirstFrame );
    % Fix button height in pixels
    set(g_tWT.Handles.hGoToFirstButton, 'units', 'pixels');
    vPos = get(g_tWT.Handles.hGoToFirstButton, 'position');
    set(g_tWT.Handles.hGoToFirstButton, 'Position', [vPos(1) 20 vPos(3) 17]);

    % Status text field below slider
    g_tWT.Handles.hStatusText = uicontrol(g_tWT.WTWindow, 'units', 'normalized' ...
        , 'Position', [.02 .005 .96 .02] ...
        , 'Style', 'text' ...
        , 'fontsize', 9 ...
        , 'horizontalalignment', 'left' ...
        , 'String', '' ...
        , 'Tag', 'statustext' ...
        , 'FontWeight', 'normal' ...
        , 'backgroundcolor', get(g_tWT.WTWindow, 'color'));
    % Fix height in pixels
    set(g_tWT.Handles.hStatusText, 'units', 'pixels');
    vPos = get(g_tWT.Handles.hStatusText, 'position');
    set(g_tWT.Handles.hStatusText, 'Position', [vPos(1) 2 vPos(3) 15]);
end

% List of previously accessed paths
if ~isempty(g_tWT.AccessedPaths)
    for p = 1:length(g_tWT.AccessedPaths)
        sLabel = sprintf('%d  %s', p, g_tWT.AccessedPaths{p});
        if length(sLabel) > 40
            sLabel = ['..' sLabel(end-37:end)];
        end
        if p == 1
            uimenu(hFrameWin, 'Label', sLabel, ...
                'Parent', hFile, ...
                'Callback', [sprintf('wt_select_directory(''%s'')', g_tWT.AccessedPaths{p})], ...
                'Separator', 'on');
        else
            uimenu(hFrameWin, 'Label', sLabel, ...
                'Parent', hFile, ...
                'Callback', [sprintf('wt_select_directory(''%s'')', g_tWT.AccessedPaths{p})]);
        end
    end
end

uimenu(hFrameWin, 'Label','E&xit WT', 'Parent', hFile, 'Callback', ['wt_exit'], 'separator', 'on', 'accelerator', 'q');

set(hFrameWin, 'keypressfcn', @FigKeyPressExec)
set(g_tWT.WTWindow, 'visible', 'on')

return % end of main function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FigKeyPressExec( varargin )
global g_tWT
sKey = lower(get(gcf, 'currentcharacter'));

% If pressed key is a number, then go that number of frames back from
% current
if ~isempty(str2num(sKey))
    if str2num(sKey) == 0
        nNewFrame = round(get(g_tWT.Handles.hSlider, 'Value')) + 1;
    else
        nNewFrame = round(get(g_tWT.Handles.hSlider, 'Value')) - str2num(sKey);
    end
    if nNewFrame < 1 || nNewFrame > g_tWT.MovieInfo.NumFrames
        beep; return;
    end
    wt_display_frame(nNewFrame);
end

if strcmp(' ', sKey)
    if isfield(g_tWT, 'StopProc')
        if g_tWT.StopProc
            g_tWT.StopProc = 0;
            % If whisker are marked and head-tracking is not active, then
            % resume automatic whisker tracking
            if ~isempty(g_tWT.MovieInfo.SplinePoints) && isempty(findobj('tag', 'auto'))
                wt_track_auto('bicubic');
            end
        else g_tWT.StopProc = 1; end
    end
end
return

function GoToFrame(varargin)
sF = inputdlg('Go to frame', 'Go to frame', 1);
if isempty(sF), return
else wt_display_frame(str2num(char(sF))); end
return

function GotoFirstFrame(varargin)
global g_tWT
if ~isempty(g_tWT.MovieInfo.Nose)
    f = find(~isnan(g_tWT.MovieInfo.Nose(:,1)));
else f = 1; end
wt_display_frame(f(1));
return

function GotoLastFrame(varargin)
global g_tWT
if ~isempty(g_tWT.MovieInfo.SplinePoints)
    f = size(g_tWT.MovieInfo.SplinePoints, 3);
else
    f = g_tWT.MovieInfo.NumFrames;
end
wt_display_frame(f);
return
