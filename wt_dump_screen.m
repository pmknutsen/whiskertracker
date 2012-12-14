% WT_DUMP_SCREEN
% Make a graphic dump of the current WT screen/GUI to the clipboard or a
% file on disk.
%
% Files are exported as TIFF images (.tif)
%
% Usage:
%   wt_dump_screen
%

function wt_dump_screen

global g_tWT

hFrameWin = findobj('Tag', 'WTMainWindow');

sAnswer = questdlg('Select where to dump the screen', ...
    'Dump screen', ...
    'Copy to clipboard', 'Save to disk', 'Send to printer', ...
    'Copy to clipboard');

% Hide slider and text elements
set(g_tWT.Handles.hSlider, 'visible', 'off')
hText = findobj('tag','antpost');
set(hText, 'visible', 'off')
set(findobj('tag','gotoframe'), 'visible', 'off')
set(findobj('tag','movieandframe'), 'visible', 'off')

switch sAnswer
    case 'Copy to clipboard' % copy to clipboard
        print(hFrameWin, '-dbitmap')
    case 'Save to disk' % save to disk
        [sFilename sFilepath, nFilterIndx] = uiputfile({'*.tif';'*.eps'}, 'Select output file');
        if nFilterIndx == 1     % save as TIDD
            print(hFrameWin, '-dtiff', sprintf('%s%s', sFilepath, sFilename));
        elseif nFilterIndx == 2 % save as color EPS
            print(hFrameWin, '-depsc', sprintf('%s%s', sFilepath, sFilename));
        end
    case 'Send to printer' % send to printer
        print(hFrameWin, '-v')
end

% Turn back on slider
set(g_tWT.Handles.hSlider, 'visible', 'on')
set(hText, 'visible', 'on')
set(findobj('tag','gotoframe'), 'visible', 'on')
set(findobj('tag','movieandframe'), 'visible', 'on')

return
