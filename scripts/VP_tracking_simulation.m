function varargout = VP_tracking_simulation(g_tWT, varargin)
% VP Tracking Simulation
% Simulate the Virtual Pole real-time tracking algorithm. Algorithm has
% several inputs (here supplied internally in the script);
%
%
% Function stores in g_tWT.MovieInfo the following parameters;
%
% 1) frames whisking was detected
% 2) average X/Y position
%

global g_tWT

g_tWT.StopProc = 0;


% ----------------------PARAMETERS-------------------------------------%
sFilename = g_tWT.MovieInfo.Filename;
hFig = g_tWT.WTWindow;

% Change in gray level between frames to be considered motion (0-255)
% Typical VP value 10 - 30
nThresh = 14;

% Percent of virtual pole occupied by motion pixels for contact to be
% detected (default = 10)
nArea = 10;

% Trigger on median whisker position
% Amplitude threshold (pixels)
nAmpThresh = 100; % pixels

% boxcar window length (default = 10)
nBoxLen = 10; % frames

% Min # of motion pixels for median calculation
nMinForMedian = 10;

vLims = [70 150];

%-----------------------end params-------------------------------------%

% create new movie

bMakeMov = 1;
if bMakeMov
    NewMov = avifile('VP_Demo_Tracking5.avi');
    NewMov.Quality = 100;
    NewMov.Compression = 'none';
end

% load info
tInfo = aviinfo(sFilename);
nFrames = tInfo.NumFrames;
nStep = g_tWT.MovieInfo.ScreenRefresh; 


mov = aviread(sFilename,1);
pixgrid = wt_image_preprocess( double(mov.cdata) );
pixgridim(:,:,1) = pixgrid(:,:,1);
pixgridim(:,:,2) = pixgrid(:,:,1);
pixgridim(:,:,3) = pixgrid(:,:,1);
image(uint8(pixgridim)); axis equal;

wt_set_status('Running VP tracking simulation. Press Stop to abort.')
nStepCount = 0;

vTrackFrames = 8000:g_tWT.MovieInfo.NoFramesToLoad:10000;
%vTrackFrames = 1:g_tWT.MovieInfo.NoFramesToLoad:100;
vJAll = [];
vIAll = [];
for nStepRange = vTrackFrames
    % Prevent frame-range not to exceed actual max number of frames
    vFrames = nStepRange:nStepRange+g_tWT.MovieInfo.NoFramesToLoad-1;
    vFrames = vFrames(find(vFrames <= nFrames));
    
    % Load frames in current range
    % if this fails, video may be corrupted etc
    try, mFrames = wt_load_avi(sFilename, vFrames);
    catch, break, end

    % Iterate over frames in current range
    for nFrame = 1:length(vFrames)
        iframe = vFrames(nFrame); % real framenumber
        
        % Current frame
        mov = mFrames(:,:,nFrame);
        mImg = wt_image_preprocess( mov );
        
        if iframe == vTrackFrames(1)
            mPreviousFrame = mImg;
            vIAll(iframe) = NaN;
            vJAll(iframe) = NaN;
            continue
        end

        % IMAGE PROCESSED

        %if rand(1) > .9, keyboard, end

        % Subtract last frame from current frame
        mImgO = mImg;
        mImg2 = mImg - mPreviousFrame;
        mPreviousFrame = mImgO;
        vIndx = find(mImg2 >= nThresh);
        mImg = zeros(size(mImg2));
        mImg(vIndx) = 255;
        [vI, vJ] = ind2sub(size(mImg), vIndx);
        vIndxKeep = find(vJ > vLims(1) & vJ < vLims(2));
        vI = vI(vIndxKeep);
        vJ = vJ(vIndxKeep);
        
        %if length(vIndx) > 3000, keyboard, end
            
        if length(vIndx) > nMinForMedian
            nIAllThis = nanmedian(vI);
            nJAllThis = nanmedian(vJ);
        else
            nIAllThis = NaN;
            nJAllThis = NaN;
        end
        
        % box car filter
        if iframe > (vTrackFrames(1) + nBoxLen)
            nIAllThis = nanmean([vIAll((iframe-nBoxLen):(iframe-1)) nIAllThis]);
            nJAllThis = nanmean([vJAll((iframe-nBoxLen):(iframe-1)) nJAllThis]);
        end

        vIAll(iframe) = nIAllThis;
        vJAll(iframe) = nJAllThis;

        % END OF IMAGE PROCESSED


        % GUI updates
        set(g_tWT.Handles.hSlider, 'value', iframe)
        
        % Show images with dot on center of mass
        if nStepCount == 0
            figure(g_tWT.WTWindow);
            cla
            imagesc(uint8(mImgO)); axis equal; hold on
            if length(vIndx) > nMinForMedian
                plot(vJ,vI,'w.','markersize', 5)
                plot(100,nanmedian(vI), 'r.', 'markersize', 16)
            end
            
            if bMakeMov
                F = getframe(gca);
                NewMov = addframe(NewMov,F);
            end
            
        end

        if nStepCount >= nStep, nStepCount = 0;
        else, nStepCount = nStepCount + 1; end

        drawnow
    end

end
wt_set_status('')

if bMakeMov
    NewMov = close(NewMov);
end

% Save tracked data
g_tWT.MovieInfo.VPTrackerSim = [vIAll' vJAll'];

return
