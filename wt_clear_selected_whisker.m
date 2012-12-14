function wt_clear_selected_whisker()
% WT_CLEAR_SELECTED_WHISKER
% Delete all or parts of tracked data of selected whiskers, or delete all
% tracked whiskers.

global g_tWT

cIdents = {g_tWT.MovieInfo.WhiskerIdentity{:}};

nFontSize = 8;
nLinSep = 10;

vScrnSize = get(0, 'ScreenSize');
nFigHeight = (length(cIdents)-1) * (nFontSize*2 + nLinSep) + 60;
nFigWidth = 150;
vFigPos = [5 vScrnSize(4)-(nFigHeight+21) nFigWidth nFigHeight];
hCurrWin = figure;
set(hCurrWin, 'NumberTitle', 'off', ...
    'Name', 'Select whisker', ...
    'Position', vFigPos, ...
    'Tag', 'ClearSelectedWhiskers', ...
    'MenuBar', 'none' )

nCurrLine = nFigHeight;
nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);

for w = 1:length(cIdents)
    w_this = w;
    if w > 10, w_this = w-10; end
    if w > 20, w_this = w-20; end
    if w > 30, w_this = w-30; end
    if w > 40, w_this = w-40; end
    if isempty(cIdents{w}), cIdents{w}{1} = ''; end
    hBox = uicontrol(hCurrWin, 'Style', 'checkbox', 'Position', [10 nCurrLine 125 20], ...
        'Callback', '', ...
        'HorizontalAlignment', 'right', ...
        'String', cIdents{w}, ...
        'FontWeight', 'bold', ...
        'Tag', sprintf('whisker_%d_%s', w, cIdents{w}{:}), ...
        'BackgroundColor', g_tWT.Colors(w_this,:) );
    nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
end

% Refresh pushbutton
uicontrol(hCurrWin, 'Style', 'pushbutton', 'Position', [10 nCurrLine 125 20], ...
    'Callback', @ClearWhiskers, ...
    'String', 'Clear whiskers', ...
    'FontWeight', 'bold' );

uiwait(hCurrWin)

return

%%%%%%%%%%%%%% CLEAR WHISKERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ClearWhiskers(varargin)

global g_tWT
hCurrWin = findobj('Tag', 'ClearSelectedWhiskers');

% Iterate over checkboxes and decide which to delete
vDelWhiskers = [];
cIdents = {g_tWT.MovieInfo.WhiskerIdentity{:}};
for w = 1:length(cIdents)
    if isempty(cIdents{w}), cIdents{w}{1} = ''; end
    hCheckBox = findobj(hCurrWin, 'Tag', sprintf('whisker_%d_%s', w, cIdents{w}{:}));
    if get(hCheckBox, 'Value')
        vDelWhiskers(end+1) = w;
    end
end

% Clear whiskers
if ~isempty(vDelWhiskers)
    wt_clear_whisker(vDelWhiskers)
end

% Close window
close(hCurrWin)

% Re-open window
wt_clear_selected_whisker

return
