function wt_autosize_window
% Optimally resize WT window so there is minimal empty space surrounding
% the video frame.
global g_tWT

if ~isempty(g_tWT.CurrentFrameBuffer.Img) % keep largest dim

    % Check that view mode is correct
    %if g_tWT.DisplayMode
    %    if isempty(g_tWT.MovieInfo.RightEye)
    %        g_tWT.DisplayMode = 0;
    %    end
    %end
    
    vFigPos = get(g_tWT.WTWindow, 'position');
    if ~g_tWT.DisplayMode % head movements tracked, i.e. 'double' frame
        cFrame = wt_crop_behaving_video(g_tWT.CurrentFrameBuffer.Img, ...
            [g_tWT.MovieInfo.RightEye(1,:); g_tWT.MovieInfo.LeftEye(1,:); g_tWT.MovieInfo.Nose(1,:)] , ...
            g_tWT.MovieInfo.HorExt, g_tWT.MovieInfo.RadExt, 'nearest');
        vAxSize = size(cFrame{1}) .* 2;
    else
        vAxSize = size(wt_image_preprocess(g_tWT.CurrentFrameBuffer.Img));
    end
    
    if vAxSize(1) >= vAxSize(2) % height > width (adjust width)
        nHeightRatio = vFigPos(4) / vAxSize(1);
        vFigPos(3) = max([vAxSize(2) .* nHeightRatio 400]);
        set(g_tWT.WTWindow, 'position', vFigPos)
    else % width > height (adjust height)
        nHeightRatio = vFigPos(3) / vAxSize(2);
        vFigPos(4) = vAxSize(1) * nHeightRatio + 50; % 50 added for slider and title
        set(g_tWT.WTWindow, 'position', vFigPos)
    end
end

return
