function bSuccess = wt_mark_eyes(varargin)
% WT_MARK_EYES
% Mark location of eyes in current frame
% return bSuccess = 0 if user does not input all required points
%

global g_tWT
persistent p_mEyePos p_mNosePos

bSuccess = 1;

figure(findobj('Tag', 'WTMainWindow'))

% Get frame number
if ~isempty(varargin), nCurrentFrame = varargin{1};
else nCurrentFrame = get(g_tWT.Handles.hSlider, 'Value'); end

% Determine whether to mark nose as well
% Nose is only marked if g_tWT.MovieInfo.EyeNoseAxLen is not set
if ~isfield(g_tWT.MovieInfo, 'EyeNoseAxLen'), bMarkNose = 1;
else
    if isempty(g_tWT.MovieInfo.EyeNoseAxLen), bMarkNose = 1;
    else bMarkNose = 0; end
end

% Get user input, unless we are in batch mode
if ~g_tWT.BatchMode
    
    % Get coordinates of eyes via ginput
    hold on;
    try
        wt_set_status('Click once on left eye and once on right eye')
        for i = 1:2
            [nX nY] = ginput(1);  % user may hit RETURN if he does not want to input data
            vCurrXPos(i,1) = nX;
            vCurrYPos(i,1) = nY;
            scatter(vCurrXPos(i), vCurrYPos(i), 'go');
            drawnow;
        end
    catch
        bSuccess = 0;   % eyes not marked
        return;
    end
    
    % Get coordinates of nose via ginput
    if bMarkNose
        wt_set_status('Click on tip of nose')
        try
            [nNoseX nNoseY] = ginput(1);
        catch
            bSuccess = 0;   % nose not marked
            return;
        end
        scatter(nNoseX, nNoseY, 'ro');
    end
    hold off
    wt_set_status('')
    
    % Sort value-pairs so that right eye is first
    mPos = round(sortrows([vCurrXPos(1:2) vCurrYPos(1:2)]));
    
    % Store set position in persistent variable used for batch processing
    p_mEyePos = mPos;
    p_mNosePos = [nNoseX nNoseY];

else
    % Get persistent values if we are in batch mode
    if isempty(p_mEyePos)
        return
    end
    mPos = p_mEyePos;
    nNoseX = p_mNosePos(1);
    nNoseY = p_mNosePos(2);
end

% Reset old data
g_tWT.MovieInfo.RightEye = zeros(g_tWT.MovieInfo.NumFrames, 2) * NaN; % [x y]
g_tWT.MovieInfo.LeftEye = zeros(g_tWT.MovieInfo.NumFrames, 2) * NaN; % [x y]
g_tWT.MovieInfo.Nose = zeros(g_tWT.MovieInfo.NumFrames, 2) * NaN; % [x y]

% Assign new values for first frame
g_tWT.MovieInfo.RightEye(nCurrentFrame, :) = mPos(1, :);
g_tWT.MovieInfo.LeftEye(nCurrentFrame, :) = mPos(2, :);
if bMarkNose
    g_tWT.MovieInfo.Nose(nCurrentFrame, :) = [nNoseX nNoseY];
end

% Calculate length of eye-nose axes
if bMarkNose
    R = mPos(1, :); % right eye
    L = mPos(2, :); % left eye
    M = [mean([R(1) L(1)]) mean([R(2) L(2)])]; % mid-point between eyes
    g_tWT.MovieInfo.EyeNoseAxLen = sqrt(diff([nNoseX M(1)])^2 + diff([nNoseY M(2)])^2); % length of eyes-nose axes
end

return
