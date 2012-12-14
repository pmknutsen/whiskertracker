function wt_wizard_head_fixed(varargin)
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

% char() creates a 2 dim char array of strings, and pads all strings to
% same max length
sAnesthStateVector = char(                                      ...
                 'Setting Image Region of Interest',     ...
                 'Rotate Image Anti-Clockwise',     ...
                 'Track Stimulus Squares',     ...
                 'Calibrate',     ...                 
                 'Setting Parameters'    ,                ...
                 'Marking Whisker',                 ...
                 'Set Full Length'                  ...
                              );
         
sAnesthFuncVector =  char(                        ...
                'wt_wizard_select_roi',            ... % 'Setting Image Region of Interest'
                'wt_wizard_rotate_anti',            ... % 'Rotate Image Anti-Clockwise'
                'wt_wizard_track_stimulus',         ... % Track stimulus squares
                'wt_wizard_calibrate',              ... % Calibrate
                'wt_wizard_tracking_parameters',   ... % 'Setting Parameters'                    
                'wt_wizard_mark_whisker',           ... % 'Marking Whisker' 
                'wt_wizard_set_full_length'         ... % 'Set Full Length'
                );


wt_wizard_ctrl('Wizard (head-fixed)', sAnesthStateVector, sAnesthFuncVector);
return;

