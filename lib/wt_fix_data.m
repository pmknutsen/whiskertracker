function wt_fix_data
% WT_FIX_DATA Correct errors in data structure
% Find and correct errors in global WT data structure, such as empty
% fields.
%

global g_tWT


if isfield(g_tWT, 'MovieInfo')

    % Check for markers that were improperly removed
    if isfield(g_tWT.MovieInfo, 'WhiskerLabels')
        iRem = [];
        for i = 1:length(g_tWT.MovieInfo.WhiskerLabels)
            if isempty(g_tWT.MovieInfo.WhiskerLabels{i})
                iRem = [iRem i];
            end
        end
        if ~isempty(iRem)
            g_tWT.MovieInfo.WhiskerLabels(iRem) = [];
            if isfield(g_tWT.MovieInfo, 'WhiskerIdentity')
                g_tWT.MovieInfo.WhiskerIdentity(iRem) = [];
            end
        end
        
        % Check that there is the same number of markers and marker names
        % If not, remove marker names at end
        if isfield(g_tWT.MovieInfo, 'WhiskerIdentity')
            nLen = length(g_tWT.MovieInfo.WhiskerLabels);
            nLen = min([nLen length(g_tWT.MovieInfo.WhiskerIdentity)]);
            g_tWT.MovieInfo.WhiskerIdentity = g_tWT.MovieInfo.WhiskerIdentity(1:nLen);
        end
    end
    
end


return