function wt_track_stimulus
% WT_TRACK_STIMULUS
% Manually select location of a frame overlays and track status (on/off).

global g_tWT

% Get position of trigger manually
wt_set_status('Click on the center of the trigger location')
[nX, nY] = ginput(1);
nX = max([0 floor(nX)]);
nY = max([0 floor(nY)]);
wt_set_status('Press any button to cancel tracking...')

cAns = questdlg('Assign to trigger A or B?', 'WT', 'A', 'B', 'Cancel', 'A');
if isempty(cAns), return; end
if strcmpi(cAns, 'Cancel'), return;
elseif strcmpi(cAns, 'A')
    bUseTrigA = 1;
    g_tWT.MovieInfo.StimulusA = [];
else
    bUseTrigA = 0;
    g_tWT.MovieInfo.StimulusB = [];
end

% Iterate over frames
mFrameRanges = [0:g_tWT.MovieInfo.NoFramesToLoad:g_tWT.MovieInfo.NumFrames g_tWT.MovieInfo.NumFrames];
for fr = 1:length(mFrameRanges)-1
    nStart = mFrameRanges(fr)+1;
    nStop = mFrameRanges(fr+1);
    
    %  Load frames
    wt_set_status('Loading next range of frames...');
    mFrames = wt_load_avi(sprintf('%s', g_tWT.MovieInfo.Filename), nStart:nStop, 'noresize');
    wt_set_status('');
    
    for f = nStart:nStop
        nIndx = f-nStart+1;
        wt_set_status(sprintf('Processing frame %d', nIndx));
        
        % Preprocess frame
        mFrame = mFrames(:, :, nIndx);
        [mFrame, VOID] = wt_image_preprocess(mFrame);
        
        % Evaluate if squares are black (mean<128) or white (mean>128)
        if mFrame(nY, nX) > 128
            if bUseTrigA
                g_tWT.MovieInfo.StimulusA(f) = 1;
            else
                g_tWT.MovieInfo.StimulusB(f) = 1;
            end
        else
            if bUseTrigA
                g_tWT.MovieInfo.StimulusA(f) = 0;
            else
                g_tWT.MovieInfo.StimulusB(f) = 0;
            end
        end
    end
end

wt_set_status('Done tracking stimulus triggers')

return
