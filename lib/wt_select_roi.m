function wt_select_roi
% WT_SELECT_ROI
% Select the region of interest (ROI) within which to track whisker
% movements. The ROI is set with the mouse.
%
% If head-movements have been tracked in the current movie, a dialog will
% instead appear with values to enter directly.
%

global g_tWT

% Determine if the loaded movie contains head-movements
if g_tWT.MovieInfo.EyeNoseAxLen, bHeadIsTracked = 1;
else bHeadIsTracked = 0; end

if bHeadIsTracked % Head is tracked
    % Pop-up dialog box for user to fill in ROI parameters for
    % freely-moving movies. If user hits CANCEL, leave values as they are
    cAnswers = inputdlg({'Radial extensions of cut-out (pixels)', 'Longitudinal extensions of cut-out from eye and nose (pixels)'}, ...
        'ROI Parameters', 1, ...
        {num2str(g_tWT.MovieInfo.RadExt), num2str(g_tWT.MovieInfo.HorExt)} );
    nOldHorExt = g_tWT.MovieInfo.HorExt;
    if ~isempty(cAnswers) % user did not hit CANCEL, remove old values
        g_tWT.MovieInfo.RadExt = str2double(cAnswers{1});
        g_tWT.MovieInfo.HorExt = str2double(cAnswers{2});
        g_tWT.MovieInfo.ImCropSize = round([g_tWT.MovieInfo.RadExt g_tWT.MovieInfo.EyeNoseAxLen+g_tWT.MovieInfo.HorExt*2]);
        g_tWT.MovieInfo.Roi = [1 1 g_tWT.MovieInfo.Width g_tWT.MovieInfo.Height];% * g_tWT.MovieInfo.ResizeFactor;
    else return, end

    % Adjust vertical (horizontal) whisker coordinates for ROI changes
    if ~isempty(g_tWT.MovieInfo.SplinePoints)
        mSpl = g_tWT.MovieInfo.SplinePoints(:,2,:,:);
        nYadj = g_tWT.MovieInfo.HorExt - nOldHorExt;
        mSpl = mSpl + nYadj;
        mSpl(mSpl == 0) = 0; % let zeros stay zero
        g_tWT.MovieInfo.SplinePoints(:,2,:,:) = mSpl;
    end
    
else % if head is not tracked...
    % Show 'raw' frame (not rotated, uncropped etc)
    
    % remove old values
    vROI = g_tWT.MovieInfo.Roi;
    nRot = g_tWT.MovieInfo.Rot;
    vFlip = g_tWT.MovieInfo.Flip;
    g_tWT.MovieInfo.Roi = [];
    g_tWT.MovieInfo.Rot = 0;
    g_tWT.MovieInfo.Flip = [0 0];

    wt_display_frame
    axis tight image
    set(g_tWT.FrameAx,'visible','on') 
    
    %axes(g_tWT.FrameAx)
    [vX, vY, mA, vRect] = imcrop;

    % Put back numbers we removed above
    g_tWT.MovieInfo.Roi = vROI;
    g_tWT.MovieInfo.Rot = nRot;
    g_tWT.MovieInfo.Flip = vFlip;
    
    % Limit region of interest to image size limits
    if (vRect(1) < 1) vRect(1) = 1; end
    if (vRect(1) > vX(2)) vRect(1) = vX(2); end
    if (vRect(2) < 1) vRect(2) = 1; end
    if (vRect(2) > vY(2)) vRect(2) = vY(2); end
    if ((vRect(3)+vRect(1)) > vX(2)) vRect(3) = (vX(2)-vRect(1)); end
    if ((vRect(4)+vRect(2)) > vY(2)) vRect(4) = (vY(2)-vRect(2)); end
    
    % Get coordinates of cropped image
    g_tWT.MovieInfo.Roi = round(vRect);
    g_tWT.MovieInfo.ImCropSize = g_tWT.MovieInfo.Roi(3:4)+1;
end

wt_display_frame % refresh frame
wt_autosize_window

return