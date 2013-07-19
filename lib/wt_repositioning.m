function wt_repositioning()
% wt_repositioning
% Improve tracking by repositioning tracked whisker to interpolated
% centre-of-mass of whisker shaft.
%
%

% Run wt_track_auto() but with the additional instruction to ONLY
% reposition whisker. Note that whisker(s) will still be tracked in those
% individual frames where it has not already been tracked.

global g_tWT
g_tWT.RepositionOnly = 1;

try
    wt_set_status('Repositioning whisker(s)')
    wt_track_auto('auto')
    g_tWT.RepositionOnly = 0;
    wt_set_status('Repositioning of whisker(s) completed')
catch
    wt_set_status('Warning: Repositioning of whisker(s) failed')
    g_tWT.RepositionOnly = 0;
end

return