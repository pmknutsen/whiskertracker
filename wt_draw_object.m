function wt_draw_object(w, nCurrentFrame)
% WT_DRAW_OBJECT
% Draws object in current video-frame. Works only in conjunction with WT GUI.
% Takes as input parameters whisker ID and current frame.
% Syntax: wt_draw_object(ID, FRAMENUM)
%


global g_tWT

if ~isfield(g_tWT, 'HideOutlines'), g_tWT.HideOutlines = 0; end

if w > size(g_tWT.MovieInfo.ObjectRadPos,1), return; end % if no object is marked for whisker

for o = find(~isnan(g_tWT.MovieInfo.ObjectRadPos(w,1,:)))' % iterate over object locations
    nX = g_tWT.MovieInfo.ObjectRadPos(w, 1, o);
    nY = g_tWT.MovieInfo.ObjectRadPos(w, 2, o);
    try
        nStartFrame = g_tWT.MovieInfo.ObjectRadPos(w, 3, o);
    catch
        nStartFrame = NaN;
    end

    if g_tWT.DisplayMode & ~isempty(g_tWT.MovieInfo.EyeNoseAxLen)
        vNewCoords = wt_rotate_coords([nX nY], 'abs2rel', ...
            g_tWT.MovieInfo.RightEye(nCurrentFrame,:), ...
            g_tWT.MovieInfo.LeftEye(nCurrentFrame,:), ...
            g_tWT.MovieInfo.Nose(nCurrentFrame,:), ...
            g_tWT.MovieInfo.WhiskerSide(w), ...
            g_tWT.MovieInfo.ImCropSize, ...
            g_tWT.MovieInfo.RadExt, ...
            g_tWT.MovieInfo.HorExt );
        nX = vNewCoords(1);% * g_tWT.MovieInfo.ResizeFactor;
        nY = vNewCoords(2);% * g_tWT.MovieInfo.ResizeFactor;
    end

    hObj = findobj('Tag', sprintf('object%d%d', w, o));
    if isempty(hObj) % draw object for first time
        hObjectMenu(w) = uicontextmenu; % context menu
        hObj = plot(nX, nY, ...
            'color', g_tWT.Colors(w,:), ...
            'Marker', '+', 'Markersize', 5, ...
            'Linewidth', 2, ...
            'Tag', sprintf('object%d%d', w,o), ...
            'uicontextmenu',  hObjectMenu(w) );
        uimenu(hObjectMenu(w), 'Label', 'Delete', 'Callback', sprintf('wt_mark_object(%d, ''delete'', %d)', w, o));
        uimenu(hObjectMenu(w), 'Label', 'Move', 'Callback', sprintf('wt_mark_object(%d, ''move'', %d)', w, o) );
        uimenu(hObjectMenu(w), 'Label', 'Edit frame', 'Callback', sprintf('wt_mark_object(%d,''editframe'', %d)', w, o));
    else % update object XY coordinates
        set(hObj, 'Xdata', nX, 'Ydata', nY, 'Visible', 'on');
    end
    if ~isnan(nStartFrame)
        text(nX+3, nY, sprintf('%d', nStartFrame), ... % framenumber
            'color', 'w', 'fontsize', 7, ...
            'tag', sprintf('objecttxt%d%d', w, o) );
    end
end

return
