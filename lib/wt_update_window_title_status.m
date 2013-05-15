function wt_update_window_title_status

global g_tWT
set(g_tWT.WTWindow, 'Name', sprintf('%s*', cell2mat(regexp(get(g_tWT.WTWindow, 'Name'), '[^*]*', 'match')) ))

return
