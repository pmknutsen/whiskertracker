function wt_draw_whisker_label(w, nCurrentFrame)
% WT_DRAW_WHISKER_LABEL
% Draws whisker labels in current frame. Works only in conjunction with WT GUI.
% Takes as input parameters whisker ID and current frame.
% Syntax: wt_draw_whisker_label(ID, FRAMENUM)
%

global g_tWT

w_this = w;
if w > 10, w_this = w - 10; end
if w > 20, w_this = w - 20; end
if w > 30, w_this = w - 30; end
if w > 40, w_this = w - 40; end

if w > length(g_tWT.MovieInfo.WhiskerLabels), return, end % if no whisker labels are marked for whisker
if isempty(g_tWT.MovieInfo.WhiskerLabels{w}), return, end

for i = 1:size(g_tWT.MovieInfo.WhiskerLabels{w}, 3) % iterate over labels
    if nCurrentFrame > size(g_tWT.MovieInfo.WhiskerLabels{w}, 1), nX = NaN; nY = NaN;
    else
        nX = g_tWT.MovieInfo.WhiskerLabels{w}(ceil(nCurrentFrame), 1, i);
        nY = g_tWT.MovieInfo.WhiskerLabels{w}(ceil(nCurrentFrame), 2, i);
        if g_tWT.MovieInfo.WhiskerSide(w) == 2 && g_tWT.DisplayMode
            vAxSize = get(g_tWT.FrameAx, 'XLim');
            nX = nX + vAxSize(2)/2; % only change X
        end        
    end
    
    sTag = sprintf('whiskerlabel-%d-%d', w, i);
    hObj = findobj('Tag', sTag);

    if isnan(nX), delete(hObj), continue, end
    
    % Transform coordinates between frameworks, if necessary
    if ~g_tWT.DisplayMode % relative to absolute, coordinates are always stored in relative coordinates
        vCoords = wt_rotate_coords([nX nY], 'rel2abs', ...
            g_tWT.MovieInfo.RightEye(nCurrentFrame,:), ...
            g_tWT.MovieInfo.LeftEye(nCurrentFrame,:), ...
            g_tWT.MovieInfo.Nose(nCurrentFrame,:), ...
            g_tWT.MovieInfo.WhiskerSide(w), ...
            g_tWT.MovieInfo.ImCropSize, ...
            g_tWT.MovieInfo.RadExt, g_tWT.MovieInfo.HorExt );
        nX = vCoords(1); nY = vCoords(2);
    end
    
    if isempty(hObj) % draw label for first time
        hObjectMenu(w) = uicontextmenu; % context menu
        set(hObjectMenu(w), 'Tag', sprintf('%s_menu', sTag))
        vCol = g_tWT.Colors(w_this,:) + .4;
        vCol(vCol > 1) = 1;
        hObj = plot(g_tWT.FrameAx, nX, nY, ...
            'color', vCol, ...
            'Marker', '+', 'Markersize', 8, ...
            'Linewidth', 2, ...
            'Tag', sTag, ...
            'uicontextmenu',  hObjectMenu(w) );
        uimenu(hObjectMenu(w), 'Label', 'Track manual without deletion', 'Callback', sprintf('wt_track_whisker_label(%d, ''manual_without_deletion'', %d)', w, i));
        uimenu(hObjectMenu(w), 'Label', 'Track manual with deletion', 'Callback', sprintf('wt_track_whisker_label(%d, ''manual_with_deletion'', %d)', w, i));
        uimenu(hObjectMenu(w), 'Label', 'Continue', 'Callback', sprintf('wt_track_whisker_label(%d, ''continue'', %d)', w, i), 'separator', 'on');
        uimenu(hObjectMenu(w), 'Label', 'Continue in fixed position', 'Callback', sprintf('wt_track_whisker_label(%d, ''continuefixed'', %d)', w, i));
        uimenu(hObjectMenu(w), 'Label', 'Change identity', 'Callback', sprintf('wt_set_identity(%d,''whisker'')', w), 'separator', 'on');
        uimenu(hObjectMenu(w), 'Label', 'Delete', 'Callback', sprintf('wt_track_whisker_label(%d, ''delete'', %d)', w, i), 'separator', 'on');
        uimenu(hObjectMenu(w), 'Label', 'Delete whisker', 'Callback', sprintf('wt_clear_whisker(%d)', w))
    else % update object XY coordinates
        set(hObj, 'Xdata', nX, 'Ydata', nY, 'Visible', 'on');
    end
end

% Show whisker name next to label
if g_tWT.ShowLabelIdentity && isfield(g_tWT.MovieInfo, 'WhiskerIdentity')
    % Remove old labels
    sIdent = '';
    if length(g_tWT.MovieInfo.WhiskerIdentity) >= w
        sIdent = g_tWT.MovieInfo.WhiskerIdentity{w};
        if isempty(sIdent), sIdent = ''; end
    end
    if iscell(sIdent)
        sIdent = sIdent{1};
    end
    
    % Get handle of previously drawn text label
    hTxt = findobj(g_tWT.FrameAx, 'Tag', ['WTMarker_' sIdent]);
    if length(hTxt) > 2
        delete(hTxt)
        hTxt = [];
    end
    if isempty(hTxt)
        hTxt = text(nX-15, nY-15, sIdent, 'fontsize', 10, 'color', g_tWT.Colors(w_this,:), ...
            'FontWeight', 'bold', 'Tag', ['WTMarker_' sIdent], ...
            'parent', g_tWT.FrameAx, 'interpreter', 'none');
    else
        set(hTxt, 'position', [nX-15 nY-15 0])
    end
end

return
 