function varargout = track_ROI_event(g_tWT)
% TRACK_ROI_EVENT
% Track an event in a region of interest. Return a vector with the median
% pixel value in the ROI.
%
% Uses the ROI Event_ROI as the default regional of interest to analyze. If
% this ROI does not exist it will ask the user you draw it.
%

global g_tWT % load global parameter
g_tWT.StopProc = 0;
sFilename = g_tWT.MovieInfo.Filename;

% Get AVI oAVIInfo
oAVIInfo = aviinfo(sFilename);
nNumFrames = oAVIInfo.NumFrames;
nStep = g_tWT.MovieInfo.ScreenRefresh; % added 10/01 Per

wt_set_status('Draw an outline of the region where the event occurs.')

% Get ROI
mov = aviread(sFilename,1);
mFrame = wt_image_preprocess( double(mov.cdata) );
mFrameim(:,:,1) = mFrame(:,:,1);
mFrameim(:,:,2) = mFrame(:,:,1);
mFrameim(:,:,3) = mFrame(:,:,1);
image(uint8(mFrameim)); axis equal;
width = size(mFrame,2); height = size(mFrame,1);

% If there exists an outline by the name EVENT_ROI, then use this as the
% ROI. If not, define it again manually. To override this, user must first
% manually delete the outline.
BWroi = [];
if isfield(g_tWT.MovieInfo, 'Outlines')
    csFields = [g_tWT.MovieInfo.Outlines.Name];
    nIndx = find(strcmp(csFields, 'EVENT_ROI'));
    if ~isempty(nIndx)
        mCoords = g_tWT.MovieInfo.Outlines(nIndx(1)).Coords;
        mCoords(end+1,:) = mCoords(1,:); % make sure ROI is closed
        BWroi = roipoly([1 size(mFrameim,2)],[1 size(mFrameim,1)],mFrameim(:,:,1),mCoords(:,1),mCoords(:,2));
    end
end
if isempty(BWroi)
    [x,y,BWroi,xi,yi] = roipoly;
    % Save region of interest as an outline
    if ~isfield(g_tWT.MovieInfo, 'Outlines')
        g_tWT.MovieInfo.Outlines = struct([]);
    end
    g_tWT.MovieInfo.Outlines(end+1).Name = {'EVENT_ROI'};
    g_tWT.MovieInfo.Outlines(end).Coords = [xi yi];
end

vROIIndx = find(BWroi);

wt_set_status('Tracking ROI event. Press Stop to abort.')
nStepCount = 0;
nStep = g_tWT.MovieInfo.ScreenRefresh;

% Iterate over and analyze frames
vStartFrames = 1:g_tWT.MovieInfo.NoFramesToLoad:nNumFrames;
for nStepRange = vStartFrames
    % Prevent frame-range not to exceed actual max number of frames
    vFrames = nStepRange:nStepRange+g_tWT.MovieInfo.NoFramesToLoad-1;
    vFrames = vFrames(find(vFrames <= nNumFrames));
    
    % Load frames in current range
    % if this fails, video may be corrupted etc
    try, mFrames = wt_load_avi(sFilename, vFrames);
    catch, break, end

    % Iterate over frames in current range
    for f = 1:length(vFrames)
        nFrame = vFrames(f); % real framenumber
        
        % Pre-process frame
        mFrame = mFrames(:,:,f);
        mFrame = wt_image_preprocess(mFrame);                
        
        % Analyze and get median pixel value in ROI
        vROIMedian(nFrame) = median(mFrame(vROIIndx));

        % Update slider
        set(g_tWT.Handles.hSlider, 'value', nFrame)

        % Display image
        if nStepCount == 0
            if ~ishandle(g_tWT.WTWindow) | g_tWT.StopProc % abort
                wt_set_status('')
                return
            end
            figure(g_tWT.WTWindow);
            cla
            image(mFrame); axis equal; hold on
        end

        % Count frames and reset when 
        if nStepCount >= nStep, nStepCount = 0;
        else, nStepCount = nStepCount + 1; end

        drawnow
    end

end
wt_set_status('')

% Save tracking data
g_tWT.MovieInfo.ROIEvent = vROIMedian;

% Refresh gui
wt_display_frame

return
