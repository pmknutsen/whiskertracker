function wt_flip_frame( sDirection )
% wt_flip_frame
% Flip frame vertically or horizontally
%
% Use:
%   wt_flip_frame('updown')
%   wt_flip_frame('leftright')
%

global g_tWT

if ~isfield(g_tWT.MovieInfo, 'Filename') return; end

switch sDirection
    case 'updown'       % Flip vertically
        g_tWT.MovieInfo.Flip(1) = ~g_tWT.MovieInfo.Flip(1);
    case 'leftright'    % Flip horizontally
        g_tWT.MovieInfo.Flip(2) = ~g_tWT.MovieInfo.Flip(2);
end

wt_display_frame();

return