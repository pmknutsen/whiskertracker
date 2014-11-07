function wt_exit
% WT_EXIT
% Exit WT and clean up workspace.


global g_tWT

wt_save_data('check1st')

% Close windows
delete(findobj('Tag', 'plotprefs'));
delete(findobj('Tag', 'WTMainWindow'));
delete(findobj('Tag', 'wt_sn_figure'));
delete(findobj('Name', 'WT Plots'))

clear global g_tWT

return
