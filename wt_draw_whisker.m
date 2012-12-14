function wt_draw_whisker(w, nCurrentFrame, varargin)
% WT_DRAW_WHISKER
% Syntax:
%  wt_draw_whisker
%  wt_draw_whisker('nomenu')  Draw whisker without context menu
%

global g_tWT

sOption = [];
if nargin==3, sOption = varargin{1}; end

bDelWhisker = 0;

% Get spline-points
try
    vX = g_tWT.MovieInfo.SplinePoints(:, 1, nCurrentFrame, w);% * g_tWT.MovieInfo.ResizeFactor;
    vY = g_tWT.MovieInfo.SplinePoints(:, 2, nCurrentFrame, w);% * g_tWT.MovieInfo.ResizeFactor;
    if all(vX==0) && all(vY==0), bDelWhisker = 1; end
catch bDelWhisker = 1; end

if bDelWhisker
    % If XY values don't exist, try to delete the displayed whisker
    delete(findobj('Tag', sprintf('whisker%d', w))) % whisker
    delete(findobj('Tag', sprintf('scatpt%d', w))) % spline-points
    wt_draw_object(w, nCurrentFrame);
    return
end

if size(vX,1) == 4  % ignore 4th point if there is no value for it
    if vX(4) == 0, vX = vX(1:3); vY = vY(1:3); end
end

% If right side, expand X coordinates so points will fall in right part of the frame
if g_tWT.DisplayMode
    vAxSize = g_tWT.MovieInfo.ImCropSize(1);
    if g_tWT.MovieInfo.WhiskerSide(w) == 2, vX = vX + vAxSize; end
end

% Calculate spline that defines whisker
vXX = min(vX):max(vX);
try [vXX, vYY] = wt_spline(vX, vY, vXX); end
% Transform coordinates between frameworks, if necessary
if ~g_tWT.DisplayMode % relative to absolute, coordinates are always stored in relative coordinates
    mCoords = wt_rotate_coords([vXX' vYY'], ...
        'rel2abs', ...
        g_tWT.MovieInfo.RightEye(nCurrentFrame,:), ...
        g_tWT.MovieInfo.LeftEye(nCurrentFrame,:), ...
        g_tWT.MovieInfo.Nose(nCurrentFrame,:), ...
        g_tWT.MovieInfo.WhiskerSide(w), ...
        g_tWT.MovieInfo.ImCropSize, ...
        g_tWT.MovieInfo.RadExt, ...
        g_tWT.MovieInfo.HorExt );
    vXX = mCoords(:,1);
    vYY = mCoords(:,2)-5;
    mCoords = wt_rotate_coords([vX vY], ...
        'rel2abs', ...
        g_tWT.MovieInfo.RightEye(nCurrentFrame,:), ...
        g_tWT.MovieInfo.LeftEye(nCurrentFrame,:), ...
        g_tWT.MovieInfo.Nose(nCurrentFrame,:), ...
        g_tWT.MovieInfo.WhiskerSide(w), ...
        g_tWT.MovieInfo.ImCropSize, ...
        g_tWT.MovieInfo.RadExt, ...
        g_tWT.MovieInfo.HorExt );
    vX = mCoords(:,1);
    vY = mCoords(:,2);
end

% If the whisker already exists, update it. Otherwise, create new whisker.
if ~isempty(findobj('Tag', sprintf('whisker%d', w)))
    % Redraw whisker
    set(findobj('Tag', sprintf('whisker%d', w)), 'XData', vXX, 'YData', vYY )
    % Redraw scatter points
    set(findobj('Tag', sprintf('scatpt%d', w)), 'XData', vX', 'YData', vY' )
else
    % Draw new whisker
    hSpline = plot(vXX, vYY, '-', 'LineWidth', g_tWT.WhiskerWidth, ...
        'color', g_tWT.Colors(w,:), 'Tag', sprintf('whisker%d', w));
    hScatHand = plot(vX, vY, 'k.', 'LineWidth', 10, 'Tag', sprintf('scatpt%d', w));
    
    if ~strcmp(sOption, 'nomenu')
        % Remove old menus if any are found
        hRemObj = findobj('Tag', sprintf('whisker%d_menu', w));
        delete(hRemObj)
        % Create new menu and associate with whisker
        hSplineMenu = uicontextmenu;
        set(hSplineMenu, 'Tag', sprintf('whisker%d_menu', w));
        set(hSpline, 'uicontextmenu',  hSplineMenu)
        uimenu(hSplineMenu, 'Label', 'Track manual without deletion', 'Callback', [sprintf('wt_track_manual(%d, ''without_deletion'')', w)])
        uimenu(hSplineMenu, 'Label', 'Track manual with deletion', 'Callback', [sprintf('wt_track_manual(%d)', w)])
        uimenu(hSplineMenu, 'Label', 'Clear from current frame...', 'Callback', [sprintf('global g_tWT;nLast=str2num(char(inputdlg(''Delete until frame'',''WT'')));if isempty(nLast), return, end;wt_clear_whisker(%d, get(g_tWT.Handles.hSlider,''Value''):nLast)', w)])
        uimenu(hSplineMenu, 'Label', 'Add point', 'Callback', [sprintf('wt_mark_whisker(''addpoint'', %d)', w)], 'Separator', 'on')
        uimenu(hSplineMenu, 'Label', 'Remove point', 'Callback', [sprintf('wt_mark_whisker(''removepoint'', %d)', w)])
        uimenu(hSplineMenu, 'Label', 'Constrain mid-point', 'Callback', [sprintf('wt_constrain_midpoint(%d)', w)])
        uimenu(hSplineMenu, 'Label', 'Move base-point', 'Callback', [sprintf('wt_mark_whisker(''movebasepoint'',%d)', w)])
        uimenu(hSplineMenu, 'Label', 'Set last frame', 'Callback', [sprintf('wt_mark_whisker(''setlastframe'', %d)', w)], 'Separator', 'on')
        uimenu(hSplineMenu, 'Label', 'Add touch location', 'Callback', sprintf('wt_mark_object(%d,''add'')', w));
        uimenu(hSplineMenu, 'Label', 'Set full length', 'Callback', sprintf('wt_mark_whisker(''setfulllength'', %d)', w));
        uimenu(hSplineMenu, 'Label', 'Set whisker identity', 'Callback', sprintf('wt_set_identity(%d,''whisker'')', w));
        uimenu(hSplineMenu, 'Label', 'Mark whisker label', 'Callback', sprintf('wt_track_whisker_label(%d, ''mark'')', w));
        uimenu(hSplineMenu, 'Label', 'Clean', 'Callback', [sprintf('wt_clean_splines(%d)', w)], 'Separator', 'on')
        uimenu(hSplineMenu, 'Label', 'Delete', 'Callback', [sprintf('wt_clear_whisker(%d)', w)])
        uimenu(hSplineMenu, 'Label', 'Copy', 'Callback', [sprintf('wt_copy_paste_whisker(''copy'', %d)', w)])
    end
end

% Show whisker name next to whisker base
if isfield(g_tWT, 'ShowWhiskerIdentity')
    if g_tWT.ShowWhiskerIdentity && isfield(g_tWT.MovieInfo, 'WhiskerIdentity')
        sIdent = '';
        if length(g_tWT.MovieInfo.WhiskerIdentity) >= w
            sIdent = g_tWT.MovieInfo.WhiskerIdentity{w};
            if isempty(sIdent), sIdent = ''; end
        end
        hTxtSide = findobj(g_tWT.FrameAx, 'Type', 'text', 'string', sIdent);
        if isempty(hTxtSide)
            hTxt = text(vX(1)-12, vY(1), sIdent, 'fontsize', 10, 'color', g_tWT.Colors(w,:), 'FontWeight', 'bold');
            set(hTxt, 'interpreter', 'none');
        else
            set(hTxtSide, 'Position', [vX(1)-12 vY(1)], 'color', g_tWT.Colors(w,:))
        end
    end
else g_tWT.ShowWhiskerIdentity = 0; end

% Show whisker name next to whisker labels
if isfield(g_tWT, 'ShowLabelIdentity')
    if g_tWT.ShowLabelIdentity && isfield(g_tWT.MovieInfo, 'WhiskerIdentity')
        sIdent = '';
        if length(g_tWT.MovieInfo.ShowLabelIdentity) >= w
            sIdent = g_tWT.MovieInfo.ShowLabelIdentity{w};
            if isempty(sIdent), sIdent = ''; end
        end
        hTxt = text(vX(1)-12, vY(1), sIdent, 'fontsize', 10, 'color', g_tWT.Colors(w,:), 'FontWeight', 'bold');
        set(hTxt, 'interpreter', 'none');
    end
else g_tWT.ShowLabelIdentity = 0; end

wt_draw_object(w, nCurrentFrame);

return
