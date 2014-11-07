function wt_wizard_freely_moving(varargin)
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
sNormalStateVector = char(                                      ...
                 'Go to frame',                           ...
                 'Tracking head movements',               ...
                 'Cleaning head movements' ,              ...
                 'Setting Image Region of Interest' ,     ...
                 'Setting Parameters'    ,                ...
                 'Go to frame',                           ...
                 'Marking Whisker'       ,                ...
                 'Setting Last Frame to Track'            ...
                              );
         
sNormalFuncVector =  char(                        ...
                'wt_wizard_go_to_frame',           ... % 'Go to Frame'
                'wt_wizard_init_head_tracker',     ... % 'Tracking head movements'               
                'wt_wizard_clean_head_movements',  ... % 'Cleaning head movements'    
                'wt_wizard_select_roi',            ... % 'Setting Image Region of Interest'      
                'wt_wizard_tracking_parameters',   ... % 'Setting Parameters'                    
                'wt_wizard_go_to_frame',           ... % 'Go to Frame'
                'wt_wizard_mark_whisker',          ... % 'Marking Whisker'                
                'wt_wizard_set_last_frame'         ... % 'Setting Last Frame to Track'    
                );


wt_wizard_ctrl('Wizard', sNormalStateVector, sNormalFuncVector);
return;


