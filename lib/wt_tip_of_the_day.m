function wt_tip_of_the_day()
% Display tip of the day

% Tips
%%
cTips = {};

cTips{end+1} = 'You can optimize tracking by adjusting values in Parameters dialog. From the menu, run Options - Parameters.';
cTips{end+1} = 'For whisker tracking, frames must be rotated so that whisker tips point towards the right and the protraction direction is down.';
cTips{end+1} = 'WhiskerTracker can automatically choose your tracking speed. From the menu, run Whiskers - Auto Select Speed.';
cTips{end+1} = 'You can batch process files. Open multiple files with the Open Directory options in the File menu. Initialize each movie, then run the job you want to batch. Stop or wait for job to complete, then run Batch Redo from the Options menu.';
cTips{end+1} = 'You can run any task marked with (B) in menus or on buttons as a batch job. Run the task once first, then select Batch Redo from the Options menu';
cTips{end+1} = 'You can display tracking results (angle, curvature, velocity and more) by selecting Plot from the Measure menu.';
cTips{end+1} = 'If you require sub-degree resolution, increase the Tracking Accuracy parameter in the Paramaters window.';
cTips{end+1} = 'When tracking a whisker during contact, set the Radial Jitter parameter in the Paramaters window to 1.';
cTips{end+1} = 'For a quick replay of tracking results, select Play Movie from the Options menu.';
cTips{end+1} = 'You can draw and save outlines of annotated objects by selecting Outlines from the Measure menu.';
cTips{end+1} = 'Did you know that you can extend WhiskerTracker with your own code? Place your function file in the /scripts folder, and run it from Scripts in the Options menu. See the existing scripts for inspiration.';
cTips{end+1} = 'Tracking many whiskers simultaneously is faster than tracking one whisker at a time.';
cTips{end+1} = 'You can track whiskers bilaterally. First, mark the head position by selecting Set Head Position from the Head menu. The frame will next split in two halves, and you can now mark and track whiskers as usual.';
cTips{end+1} = 'To jump to the last tracked frame, press the E button next to the slider.';
cTips{end+1} = 'Watch the status bar below the slider for useful information and warnings. Some functions also display instructions here when user interaction is required.';
cTips{end+1} = 'You can track whiskers manually with a mouse. Right-click the whisker and select Track Manually from the context menu.';
cTips{end+1} = 'When marking a region of interest, make sure to double click the displayed rectangle to make it disappear. If it does not disappear, the values are not saved!';
cTips{end+1} = 'You can track trigger overlays that appear in the frame. Use the zoom tool in the toolbar to magnify the pixels where the overlay appears. Then, select Triggers and Track Trigger from the view menu. Click on the location of the trigger overlay and wait for tracking to complete. Select Show Overlays to display trigger status.';
cTips{end+1} = 'The WhiskerTracker detects whisker location by assuming it has travelled a short distance relative to its location in the previous frame. You can adjust two such look-ahead ranges by selecting Set Tracking Range from the Whiskers menu. The Slow and Fast ranges are selected during tracking by pressing the Forward (>) and Fast-Forward (>>) buttons in the toolbar.';

% Show a random tip
csAns = 'Next Tip';
while strcmp(csAns, 'Next Tip')
    vIndx = randperm(length(cTips));
    csAns = questdlg(cTips{vIndx(1)}, 'WT - Tip of the day', 'OK', 'Next Tip', 'OK');
end
%%

return