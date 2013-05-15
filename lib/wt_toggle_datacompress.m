function wt_toggle_datacompress
% WT_TOGGLE_DATACOMPRESS
%

global g_tWT

% Toggle compress status
g_tWT.CompressData = ~g_tWT.CompressData;

% Update user-menu
switch g_tWT.CompressData
    case 1
        sStatus = 'on';
    case 0
        sStatus = 'off';        
    otherwise
        wt_error('Compress status is undefined. Click continue to set compress to OFF.')
        g_tWT.CompressData = 0;
        sStatus = 'off';
end
set(findobj('Label', 'Compress datafiles'), 'checked', sStatus);

return
