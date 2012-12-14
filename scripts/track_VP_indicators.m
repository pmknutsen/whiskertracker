function varargout = track_pixel_value(g_tWT)

% Track pixel values in VirtualPole movies

% Index:
% [1,1-4]	Framenumber WORD bytes 1-4
% [1,5]     Trigger OUT	BOOL (object contact, frequency trigger)
% [1,6]     Trigger IN	BOOL
% [1,7]     FFT power
% [1,8]     Tracking, Channel #1

global g_tWT % load global parameter
g_tWT.StopProc = 0;

% ----------------------PARAMETERS-------------------------------------%
vidfile = g_tWT.MovieInfo.Filename;
viewims = 1;
%---------------- end params-------------------------------------------%

% Get AVI info
info = aviinfo(vidfile);
numframes = info.NumFrames;
nStep = g_tWT.MovieInfo.ScreenRefresh;

figure(g_tWT.WTWindow)

% Create waitbar
hWaitbar = waitbar(0, 'Tracking pixel values...');
wt_set_status('Tracking pixel values...')

% Compute mean image
mov = aviread(vidfile, 1);
vTrackingCh1 = zeros(1,numframes);
vFrameByte1 = zeros(1,numframes);
vFrameByte2 = zeros(1,numframes);
vFrameByte3 = zeros(1,numframes);
vFrameByte4 = zeros(1,numframes);
vTriggerIN = zeros(1,numframes);
vTriggerOUT = zeros(1,numframes);
vFFT = zeros(1,numframes);
tic
vTrackFrames = 1:g_tWT.MovieInfo.NoFramesToLoad:numframes;
for nStepRange = vTrackFrames
    % Prevent frame-range not to exceed actual max number of frames
    vFrames = nStepRange:nStepRange + g_tWT.MovieInfo.NoFramesToLoad-1;
    vFrames = vFrames(find(vFrames <= numframes));
    
    % Load frames in current range
    % if this fails, video may be corrupted etc
    try mFrames = wt_load_avi(vidfile, vFrames);
    catch, break, end

    % Iterate over frames in current range
    for nFrame = 1:length(vFrames)
        f = vFrames(nFrame); % real framenumber
    
        if ishandle(hWaitbar) && ~g_tWT.StopProc
            waitbar(f / numframes, hWaitbar);
        else wt_set_status(''), return; end
    
        % Extract frame
        mFrame = mFrames(:,:,nFrame);
        
        % Extract values from frame
        % [1,1-4]	Framenumber WORD bytes 1-4
        vFrameByte1(f) = mFrame(1, 1);
        vFrameByte2(f) = mFrame(1, 2);
        vFrameByte3(f) = mFrame(1, 3);
        vFrameByte4(f) = mFrame(1, 4);
        % [1,5]     Trigger OUT	BOOL (object contact, frequency trigger)
        vTriggerOUT(f) = mFrame(1, 5);
        % [1,6]     Trigger IN	BOOL
        vTriggerIN(f) = mFrame(1, 6);
        % [1,7]     FFT power
        vFFT(f) = mFrame(1, 7);
        % [1,8]     Tracking, Channel #1
        vTrackingCh1(f) = mFrame(1, 8);
    end
end
toc

% Close waitbar
close(hWaitbar)
wt_set_status('')

% Reconstruct frame number
vFrame = bin2dec([dec2bin(vFrameByte1) dec2bin(vFrameByte2) dec2bin(vFrameByte3) dec2bin(vFrameByte4)]);

% Save data in global structure
g_tWT.MovieInfo.StimulusA = vTriggerIN ./ 255;
g_tWT.MovieInfo.StimulusB = vTriggerOUT ./ 255;

g_tWT.MovieInfo.VP_FFT = vFFT;
g_tWT.MovieInfo.VP_RealTimeTracking = vTrackingCh1;
g_tWT.MovieInfo.VP_FrameNumber = vFrame;

return
