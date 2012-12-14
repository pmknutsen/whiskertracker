function wt_mark_object(nWhisker, sOption, nLocation)
% WT_MARK_OBJECT
% Mark object. Accepts whisker ID as its single input parameter.
% Brings up a cross-hair to mark location in frame where whisker touches
% object. Only works in conjunction with the WT GUI.
% Syntax: wt_mark_object(ID)
global g_tWT

nCurrentFrame = round(get(g_tWT.Handles.hSlider, 'Value'));

switch sOption
    case 'delete'
        g_tWT.MovieInfo.ObjectRadPos(nWhisker, :, nLocation) = NaN;
        delete(findobj('Tag', sprintf('object%d%d', nWhisker, nLocation)))
    case 'move'
        g_tWT.MovieInfo.ObjectRadPos(nWhisker, 1:2, nLocation) = GetCoords(nWhisker);
        %  - replace zeros with NaNs
        g_tWT.MovieInfo.ObjectRadPos(find(g_tWT.MovieInfo.ObjectRadPos==0)) = NaN;
    case 'editframe'
        % Display current frame value and allow changing it
        cNewFrame = inputdlg('New frame number', 'Edit frame', 1,  ...
                            {num2str(g_tWT.MovieInfo.ObjectRadPos(nWhisker, 3, nLocation))});
        if ~isempty(cNewFrame)
            g_tWT.MovieInfo.ObjectRadPos(nWhisker, 3, nLocation) = str2num(char(cNewFrame));
        end            
        %  - replace zeros with NaNs
        g_tWT.MovieInfo.ObjectRadPos(find(g_tWT.MovieInfo.ObjectRadPos==0)) = NaN;
    case 'add'
        % If this is the 1st marked touch location for this whisker, change
        % the 1st frame for this location to be the 1st tracked frame
        nF = find(squeeze(g_tWT.MovieInfo.SplinePoints(1,1,:,nWhisker)));
        if nWhisker > size(g_tWT.MovieInfo.ObjectRadPos,1)
            nCurrentFrame = nF(1);
        else
            % Following lines takes into account that old movies did not
            % allow marking of more than one object
            if size(g_tWT.MovieInfo.ObjectRadPos,2) == 3
                if ~any(g_tWT.MovieInfo.ObjectRadPos(nWhisker,3,:))
                    nCurrentFrame = nF(1);
                end
            elseif size(g_tWT.MovieInfo.ObjectRadPos,2) == 2
                g_tWT.MovieInfo.ObjectRadPos(nWhisker,3,:) = nF(1); % set frame of previous location to 1st tracked frame
            end
        end

        % Check if there already is a location that starts from current frame
        if size(g_tWT.MovieInfo.ObjectRadPos,2) == 3 & size(g_tWT.MovieInfo.ObjectRadPos,1) >= nWhisker
            if find(g_tWT.MovieInfo.ObjectRadPos(nWhisker,3,:)==nCurrentFrame)
                wt_error('There already is a defined location starting in current frame. Move location instead.')
            end
        end
        vAbsCoords = GetCoords(nWhisker);

        % Save in absolute coordinates
        %  - determine number of locations marked for this whisker
        if isempty(g_tWT.MovieInfo.ObjectRadPos)
            nObjectNum = 0;
        else
            try
                nObjectNum = length(find(~isnan(g_tWT.MovieInfo.ObjectRadPos(nWhisker, 1:2, :))))/2;
            catch, nObjectNum = 0; end
        end
        %  - replace zeros with NaNs
        g_tWT.MovieInfo.ObjectRadPos(find(g_tWT.MovieInfo.ObjectRadPos==0)) = NaN;
        %  - tidy up order of locations
        for w = 1:size(g_tWT.MovieInfo.ObjectRadPos,1)
            vRows = find(~isnan(g_tWT.MovieInfo.ObjectRadPos(w,1,:)));
            tmp = g_tWT.MovieInfo.ObjectRadPos;
            tmp(w,:,:) = NaN;
            tmp(w,:,1:length(vRows)) = g_tWT.MovieInfo.ObjectRadPos(w,:,vRows);
            g_tWT.MovieInfo.ObjectRadPos = tmp;
        end
        %  - allocate new location
        g_tWT.MovieInfo.ObjectRadPos(nWhisker, 1:3, nObjectNum+1) = [vAbsCoords nCurrentFrame];
        %  - replace zeros with NaNs
        g_tWT.MovieInfo.ObjectRadPos(find(g_tWT.MovieInfo.ObjectRadPos==0)) = NaN;

        % Delete whisker-distance-from-object vector
        g_tWT.MovieInfo.PositionOffset(:,nWhisker) = NaN;
end

% Refresh frame
wt_display_frame

return;


%%%% SUB ROUTINES %%%%
function vAbsCoords = GetCoords(nWhisker)

global g_tWT
nCurrentFrame = round(get(g_tWT.Handles.hSlider, 'Value'));

% Get user input in absolute coordinates
[nX nY] = ginput(1);
vAbsCoords = [nX nY];% ./ g_tWT.MovieInfo.ResizeFactor;


% If head-position is known for the *current frame* then transform from
% relative to absolute coordinates.
if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen) & g_tWT.MovieInfo.Nose(nCurrentFrame, 1) & g_tWT.DisplayMode
    if ~isempty(g_tWT.MovieInfo.Nose(nCurrentFrame,:)) & ~isnan(prod(g_tWT.MovieInfo.Nose(nCurrentFrame,:)))
        nWhiskerSide = g_tWT.MovieInfo.WhiskerSide(nWhisker);
        if nWhiskerSide == 2, vAbsCoords(1) = vAbsCoords(1) - (g_tWT.MovieInfo.ImCropSize(1) + 1); end
        vAbsCoords = wt_rotate_coords(vAbsCoords, ...
            'rel2abs', ...
            g_tWT.MovieInfo.RightEye(nCurrentFrame, :), ...
            g_tWT.MovieInfo.LeftEye(nCurrentFrame, :), ...
            g_tWT.MovieInfo.Nose(nCurrentFrame, :), ...
            nWhiskerSide, ...
            g_tWT.MovieInfo.ImCropSize, ...
            g_tWT.MovieInfo.RadExt, ...
            g_tWT.MovieInfo.HorExt );    
    end
end

return
