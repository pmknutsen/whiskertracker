function wt_create_outline(sOption, nOL)
% WT_CREATE_OUTLINE Mark lines that denote various axis in image
% This function allows points, lines, polygons etc. to be labelled for
% later data analysis. Outlines can also be added to provide additional
% functionality for some WT functions. This is a (incomplete) list of
% functions that use outlines:
%
%   -- Function --              -- Outline name --
%   track_average_position      AVGPOS_ROI
%   wt_track_whisker_label      LABELLIM
%
% Usage:
%   wt_create_outline('add', OL)
%   wt_create_outline('draw', OL)
%   wt_create_outline('copy', OL)
%   wt_create_outline('paste', OL)
%       If OL is NaN, a new object will be created
%   wt_create_outline('delete', OL)
%   wt_create_outline('name', OL)
%   wt_create_outline('hide', OL)
%

global g_tWT

switch lower(sOption)
    case 'add'
        set(g_tWT.Handles.hStatusText, 'string', 'LEFT = Add point, MIDDLE = Exit, RIGHT = Undo last');
        tOutline = AddOutline;
        set(g_tWT.Handles.hStatusText, 'string', '');
        if isempty(tOutline.Coords), return, end % return if no coordinates entered
        tOutline.Name = {''};
        
        if ~isfield(g_tWT.MovieInfo, 'Outlines')
            g_tWT.MovieInfo.Outlines = tOutline;
        else
            g_tWT.MovieInfo.Outlines(end+1) = tOutline;
        end
        wt_set_identity(length(g_tWT.MovieInfo.Outlines), 'outline')
        wt_display_frame
        
    case 'draw'
        DrawOutline(nOL)
    case 'copy'
        CopyPasteOutline(nOL, 'copy')
    case 'paste'
        CopyPasteOutline(nOL, 'paste')
        wt_display_frame
    case 'delete' % delete outline
        g_tWT.MovieInfo.Outlines(nOL) = [];
        delete(findobj('tag',sprintf('outline-%d', nOL)))
        wt_display_frame
    case 'deleteall' % delete ALL outline
        if isfield(g_tWT.MovieInfo, 'Outlines')
            g_tWT.MovieInfo = rmfield(g_tWT.MovieInfo, 'Outlines');
            wt_prep_gui
            wt_display_frame
        end
    case 'name' % rename
        wt_set_identity(nOL, 'outline')
    case 'hide' % hide all outlines
        if ~isfield(g_tWT, 'HideOutlines'), g_tWT.HideOutlines = 0; end
        g_tWT.HideOutlines = ~g_tWT.HideOutlines;
        switch g_tWT.HideOutlines % update user-menu
            case 0, sStatus = 'off';
            case 1, sStatus = 'on';
        end
        set(findobj('Label', 'Hide outlines'), 'checked', sStatus);
        wt_display_frame
    otherwise
        return
end

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DrawOutline(nOL)
global g_tWT

hOL = findobj('Tag', sprintf('outline-%d', nOL));
vX = g_tWT.MovieInfo.Outlines(nOL).Coords(:,1);
vY = g_tWT.MovieInfo.Outlines(nOL).Coords(:,2);
vCol = g_tWT.Colors(size(g_tWT.Colors,1)-nOL, :);

if ~isempty(hOL) % refresh
    if g_tWT.HideOutlines % hide outlines
        set(hOL, 'XData', vX, 'YData', vY, 'Visible', 'off')
    else
        set(hOL, 'XData', vX, 'YData', vY, 'Visible', 'on')
    end
else % redraw
    if ~isfield(g_tWT, 'HideOutlines'), g_tWT.HideOutlines = 0; end
    if g_tWT.HideOutlines % hide outlines
        hOL = plot(g_tWT.FrameAx, vX, vY, 'x-', 'Tag', sprintf('outline-%d', nOL), 'Visible', 'off', 'color', vCol);
    else
        hOL = plot(g_tWT.FrameAx, vX, vY, 'x-', 'Tag', sprintf('outline-%d', nOL), 'Visible', 'on', 'color', vCol);
    end
end
hMenu = uicontextmenu;
set(hOL, 'uicontextmenu',  hMenu)
uimenu(hMenu, 'Label', 'Set name', 'Callback', [sprintf('wt_create_outline(''name'',%d)', nOL)])
uimenu(hMenu, 'Label', 'Delete', 'Callback', [sprintf('wt_create_outline(''delete'',%d)', nOL)])
uimenu(hMenu, 'Label', 'Copy', 'Callback', [sprintf('wt_create_outline(''copy'',%d)', nOL)])
uimenu(hMenu, 'Label', 'Paste', 'Callback', [sprintf('wt_create_outline(''paste'',%d)', nOL)])
 
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CopyPasteOutline(nOL, sAction)
global g_tWT
persistent vCopiedX
persistent vCopiedY
persistent sCopiedName

hOL = findobj('Tag', sprintf('outline-%d', nOL));

switch sAction
    case 'copy'
        vCopiedX = g_tWT.MovieInfo.Outlines(nOL).Coords(:,1);
        vCopiedY = g_tWT.MovieInfo.Outlines(nOL).Coords(:,2);
        sCopiedName = g_tWT.MovieInfo.Outlines(nOL).Name;
    case 'paste'
        if isempty(vCopiedX) | isempty(vCopiedY)
            uiwait(warndlg('Nothing to paste'))
            return
        end
        if ~isfield(g_tWT.MovieInfo, 'Outlines')
            g_tWT.MovieInfo.Outlines = struct([]);
        end
        if isnan(nOL) % create new outline
            g_tWT.MovieInfo.Outlines(end+1).Coords = [vCopiedX vCopiedY];
            g_tWT.MovieInfo.Outlines(end).Name = sCopiedName;
        else % copy coordinates into currently selected outline
            g_tWT.MovieInfo.Outlines(nOL).Coords = [vCopiedX vCopiedY];
        end
end

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tOutline = AddOutline()
global g_tWT
vX = [];
vY = [];
hOutline = plot(g_tWT.FrameAx,0,0,'wx-'); % outline handle
while 1
    [nX, nY, nButton] = ginput(1);
    switch nButton
        case 1 % left   ADD POINT
            vX(end+1) = nX;
            vY(end+1) = nY;
        case 3 % middle UNDO LAST POINT
            if ~isempty(vX)
                vX(end) = [];
                vY(end) = [];
            end
        case 2 % right  FINISHED
            break;
    end
    set(hOutline, 'xdata', vX, 'ydata', vY)
end
delete(hOutline)
tOutline.Coords = [vX' vY'];

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


