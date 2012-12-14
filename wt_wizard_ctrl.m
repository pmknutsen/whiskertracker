function wt_wizard_ctrl(sName, sStateVector, sFuncVector)
%
% Whisker Tracker (WT)
%
% Authors: Per Magne Knutsen, Dori Derdikman
%          The code in this script was contributed by Aharon Sheer.
%
% (c) Copyright 2004 Yeda Research and Development Company Ltd.,
%     Rehovot, Israel
%
% This software is protected by copyright and patent law. Any unauthorized
% use, reproduction or distribution of this software or any part thereof
% is strictly forbidden. 
%
% Citation:
% Knutsen, Derdikman, Ahissar (2004), Tracking whisker and head movements
% of unrestrained, behaving rodents, J. Neurophys, 2004, IN PRESS
%

global g_tWT

persistent nNextState  % The state that will be done if we press Perform

nStateVectorSize = size(sStateVector);
nStrings = nStateVectorSize(1);

nFuncVectorSize = size(sFuncVector);
if ( nStrings ~= nFuncVectorSize(1) )
    error('Num Functions not same as num States');
end

%--------------------------------------------------------------------------
% There are several types of states:
%   1) the First State.  Here the Wizard can only perform the current
%   state, or advance to the next state, or exit
%
%   2) the Last State.  Here the Wizard can only perform the current state,
%   or go back to the previous state, or exit, or Finish
%
%   3) All intermediate states.  Here the Wizard can perform the current state,
%   or go back to the previous state, or advance to the next state, or exit
%
%   4) Past the Last State.  Here the Wizard can only go back to the previous state, 
%   or exit, or Finish
%--------------------------------------------------------------------------
nFirstState = 1;
nLastState = nStrings;

nExitByX = 0; % When user hits "X" in upper right corner

% forever loop
while 1
    
%-------------------------------------
% Are we at First State?
%-------------------------------------
if (isempty(nNextState) | (nNextState <= nFirstState) )
    %-------------------------------------
    % First State
    %-------------------------------------
    % at beginning
    % action buttons - display only Perform and Exit
    nPerform = 1;  % no BACK yet
    nSkip = 2;
    nExit = 3;
    nNextState = nFirstState;  % step to first state
    nSkipState = nNextState + 1;   
    nAction = menu('Wizard', ...
                    ['Perform -- ', sStateVector(nNextState, :)], ...
                    ['Skip to ', sStateVector(nSkipState, :)],     ...
                    'Exit');
    if (nAction == nExitByX | nAction == nExit)
        return;  %  user exited the menu with no choice, or chose Exit
    elseif (nAction == nSkip)
        % DO NOT DO THE ACTION
        % Skip to next action unless already at end
        if (nNextState < nLastState)
            nNextState = nNextState + 1;
        end
    else
        % DO THE ACTION
        success = wt_do_action(nNextState, sFuncVector);
        if (success)
            nNextState = nNextState + 1;    % Step to Next State
        end
    end % end of processing actions
else
    % no longer at beginning
    nBackState = nNextState - 1;
    
    %-------------------------------------
    % Are we at Intermediate State?
    %-------------------------------------
    if (nNextState < nLastState)
        %-------------------------------------
        % Intermediate State
        %-------------------------------------
        % display both Back and Perform and Skip
        nSkipState = nNextState + 1;
        nBack = 1;   % action buttons
        nPerform = 2;
        nSkip = 3;
        nExit = 4;
        nAction = menu('Wizard', ...
                    'Back',                                     ...
                    ['Perform -- ', sStateVector(nNextState, :)], ...
                    ['Skip to ', sStateVector(nSkipState, :)],   ...
                    'Exit');
        if (nAction == nBack) 
            %return to previous state
            nNextState = nBackState;
            % DO NOT DO THE ACTION
        elseif (nAction == nExitByX | nAction == nExit)
            return;  %  user exited the menu with no choice, or chose Exit
        elseif (nAction == nSkip)
            % DO NOT DO THE ACTION
            % Skip to next action unless already at end
            nNextState = nSkipState;
        else
            % Perform
            % DO THE ACTION
            success = wt_do_action(nNextState, sFuncVector);
            if (success & (nNextState < nLastState))
                nNextState = nNextState + 1;    % Step to Next State
            end
        end  % end of processing actions
    
    %-------------------------------------
    % Are we at Last State?
    %-------------------------------------
    elseif (nNextState == nLastState)
        %-------------------------------------
        % Last State
        %-------------------------------------
        % display both Back and Perform but not Skip, allow Finish
        nBack = 1;   % action buttons
        nPerform = 2;
        nExit = 3;
        nFinish = 4;
        
        nAction = menu('Wizard', ...
                    'Back',                                     ...
                    ['Perform -- ', sStateVector(nNextState, :)], ...
                    'Exit',                                     ...
                    'Finish'                                    ...
                    );
        if (nAction == nBack) 
            %return to previous state
            nNextState = nBackState;
            % DO NOT DO THE ACTION
        elseif (nAction == nExitByX | nAction == nExit)
            return;  %  user exited the menu with no choice, or chose Exit
        elseif (nAction == nFinish)
            nNextState = nFirstState;  % return to first state
            return;  % user finished processing 
        else
            % Perform
            % DO THE ACTION
            success = wt_do_action(nNextState, sFuncVector);
            if (success)
                nNextState = nNextState + 1;    % Step to State After Last State
            end
    
        end  % end of processing actions

    %-------------------------------------
    % Are we at state After Last State?
    %-------------------------------------
    else (nNextState > nLastState)
        %-------------------------------------
        % State After Last State
        %-------------------------------------
        % display Back but not Skip or Perform, allow Finish
        nBack = 1;   % action buttons
        nFinish = 2;
        
        nAction = menu('Wizard', ...
                    'Back',                                     ...
                    'Finish'                                    ...
                    );
        if (nAction == nBack) 
            %return to previous state
            nNextState = nBackState;
            % DO NOT DO THE ACTION
        elseif (nAction == nExitByX)
            return;  %  user exited the menu with no choice
        else (nAction == nFinish)
            nNextState = nFirstState;  % return to first state
            return;  % user finished processing 
        end;  % end of processing actions
        
    end  % end of all states except First State
    
end   %end of all states

end     % end of while forever




% DO THE ACTION 
function success = wt_do_action(nNextState, sFuncVector)
success = 1;    % assume success
sActionName = deblank(sFuncVector(nNextState, :));
if (strcmp(sActionName, ''))
    success = 0;  % no function name
else
    success = feval(sActionName);
end


% go to frame...
function success = wt_wizard_go_to_frame
sF = inputdlg('Go to frame', 'Go to frame', 1);
if isempty(sF)
    % WARNING -- fail if frame NOT found
    success = 0;  % 'Go to frame' failed 
else
    wt_display_frame(str2num(char(sF)));
    success = 1; % 'Go to Frame' succeeded
end


% 'Tracking head movements'
% To terminate input press RETURN
function success = wt_wizard_init_head_tracker
success = 1;
wt_init_head_tracker;  % Tracking head movements


% Cleaning head movements
function success = wt_wizard_clean_head_movements
success = 1;
wt_clean_splines(0)  % Cleaning head movements



% 'Setting Image Region of Interest'      
function success = wt_wizard_select_roi
success = 1;
wt_select_roi;  % 'Setting Image Region of Interest'      


% Setting Parameters
function success = wt_wizard_tracking_parameters
success = 1;
wt_set_parameters;  % 'Setting Parameters'


% Marking Whisker
% To terminate input press RETURN
function success = wt_wizard_mark_whisker
global g_tWT
success = 1;
wt_mark_whisker;  % Marking Whisker

% verify that a whisker has been marked
% find index of last SplinePoint
if isempty(g_tWT.MovieInfo.SplinePoints)
    % no SplinePoint defined
    success = 0;  % failed to define a whisker
end



% Set last frame
function success = wt_wizard_set_last_frame
global g_tWT
success = 1;
sL = inputdlg('Set last frame to track', 'Set last frame', 1, {num2str(get(g_tWT.Handles.hSlider, 'value'))}  ...
            );
if isempty(sL)
    % WARNING -- fail if last frame NOT found
    success = 0;  % 'Set Last frame' failed 
else
    g_tWT.MovieInfo.LastFrame(1:size(g_tWT.MovieInfo.SplinePoints,4)) = str2num(char(sL));
    success = 1; % 'Set last Frame' succeeded
end


% Rotate image anti-clockwise
function success = wt_wizard_rotate_anti
success = 1;
wt_rotate_frame(-1);


% Track stimulus squares
function success = wt_wizard_track_stimulus
success = 1;
wt_track_stimulus;

% Calibrate
function success = wt_wizard_calibrate
success = 1;
wt_calibration('calibrate');

% 'Set Full Length'
function success = wt_wizard_set_full_length
global g_tWT
success = 1;
% find index of last SplinePoint
if isempty(g_tWT.MovieInfo.SplinePoints)
    % no SplinePoint defined
    success = 0;  % do nothing
else
    % Set full length for LAST SplinePoint
    nIndx = size(g_tWT.MovieInfo.SplinePoints, 4) + 1;
    wt_mark_whisker('setfulllength', nIndx);
end


% Edit notes
function success = wt_wizard_edit_notes
global g_tWT
success = 1;
% If notes DO NOT yet exist for this movie, pop up the Notes window
if isfield(g_tWT.MovieInfo, 'Notes')
    if isempty(g_tWT.MovieInfo.Notes), wt_edit_notes, end  % No notes yet, force writing of notes
end


