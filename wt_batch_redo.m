function wt_batch_redo(sAction)
% WT_BATCH_REDO
% Redo last action on all movies in current selection
%
% Running this function repeats the last performed action on all movies in
% the File -> Movies list. Only a subset of actions are supported by this
% function:
%
%   wt_rotate_frame(1)      Rotate 90 deg clockwise
%   wt_rotate_frame(-1)     Rotate 90 deg anti-clockwise
%   wt_flip_frame('updown')
%   wt_flip_frame('leftright')
%   wt_set_parameters('apply')  Apply values in currently open Parameters
%                               window (window must be open for this to
%                               work)
%
% To add support for more actions simply add this function call inside your
% action function code:
%
%   wt_batch_redo(ACTION) where ACTION is your function call
%
% See wt_prep_gui for examples
%
% ACTION is stored as a persistent variable in wt_batch_redo and will be
% performed on all movies when the option Batch Redo in the Options menu is
% called.
%
% Note that to populate the File->Movies list you first need to select
% File->Open Directory or File->Open Directory Tree
%
% Notes:
%   (1) The automatic display of Notes is suppressed during batch mode
%

persistent sLastAction
persistent pIgnoreLockedFiles

global g_tWT

if strcmp(sAction, 'redo')
    g_tWT.BatchMode = 1;

    % Redo last recorded action
    % Note that not all actions are supported
    if isempty(sLastAction)
        % Do nothing
        warndlg('There is no available action to run in batch mode. Note that only actions with the B suffix (e.g. in menus or buttons) can run as batch jobs. To start a batch job, you must first run one of the supported actions and then re-select Batch Redo from the menu.')
    else
        nMovies = length(g_tWT.Movies);
        
        % Repeat last supported redo action
        sAns = questdlg(['The last supported action was ' sLastAction '. Do you want to repeat this function on all (' num2str(nMovies) ') movies in the current directory?'], ...
            'WT Batch Redo');
        switch sAns
            case 'Yes'
                tMovies = g_tWT.Movies;
                hWait = waitbar(0, 'Repeating last action on all movies', 'name', 'Batch Redo');
                
                % Place waitbar just below WT GUI
                vWaitPos = get(hWait, 'Position');
                vWTPos = get(g_tWT.WTWindow, 'Position');
                vWaitPos(2) = vWTPos(2) - vWaitPos(4)*2.8;
                set(hWait, 'Position', vWaitPos);

                figure(g_tWT.WTWindow)
                
                % Load each movie, redo last action and save result
                for m = 1:nMovies
                    % Check if movie is locked
                    if isfield(g_tWT, 'BatchLock')
                        if strcmpi(g_tWT.BatchLock, 'on')
                            if isempty(pIgnoreLockedFiles)
                                sAns = questdlg('The current file is locked, indicating it is being processed by a different instance of WT. Alternatively, the lock may not have been correctly removed when this movie was last processed. Do you wish to proceed with processing locked files or skip such files?', 'WT Batch Redo', 'Process', 'Skip', 'Process');
                                if strcmpi(sAns, 'skip')
                                    pIgnoreLockedFiles = 'yes';
                                else
                                    pIgnoreLockedFiles = 'no';
                                end
                                if strcmpi(pIgnoreLockedFiles, 'yes')
                                    wt_set_status('Skipped locked batch file');
                                    continue;
                                end
                            end
                        end
                    end
                    
                    % Set lock-down on current movie
                    g_tWT.BatchLock = 'on';
                    wt_save_data
                    
                    sStr = sprintf('Batch processing movie %d/%d', m, nMovies);
                    waitbar(m/nMovies, hWait, sStr)
                    figure(g_tWT.WTWindow)
                    
                    wt_set_status(sStr)
                    
                    % Load movie
                    wt_load_movie(tMovies(m).filename);
                    g_tWT.BatchMode = 1;
                    % Redo action
                    eval(sLastAction)
                    
                    % Release lock-down
                    g_tWT.BatchLock = 'off';
                    
                    % Save results
                    wt_save_data
                    if ~ishandle(hWait), break, end % waitbar closed
                end
                if ishandle(hWait), bCancelled = 0;
                else bCancelled = 1; end
                
                if ishandle(hWait)
                    delete(hWait) % close waitbar window
                end
                g_tWT.Movies = tMovies;
                wt_prep_gui
                wt_display_frame
                
                % Display batch complete notification
                if bCancelled
                    sStr = sprintf('Batch job cancelled after movie %d/%d', m, nMovies);
                else
                    sStr = sprintf('Batch job completed (%d movies)', nMovies);
                end
                msgbox(sStr, 'WT Batch Redo');
                wt_set_status(sStr)
            case 'No'
                % Do nothing
            case 'Cancel'
                % Do nothing
        end
    end
    g_tWT.BatchMode = 0;
else
    % Record which action was last performed
    sLastAction = sAction;
end

return

