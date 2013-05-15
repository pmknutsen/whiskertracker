%%%% WT_FLIP_FRAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Whisker Tracker (WT)
%
% Authors: Per Magne Knutsen, Dori Derdikman
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

function wt_flip_frame( sDirection )

global g_tWT

switch sDirection
    case 'updown' % Flip Up-Down
        g_tWT.MovieInfo.Flip(1) = ~g_tWT.MovieInfo.Flip(1);
    case 'leftright' % Flip Left-Right
        g_tWT.MovieInfo.Flip(2) = ~g_tWT.MovieInfo.Flip(2);
end

% Refresh display
wt_display_frame