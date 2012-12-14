function [vOut, sUnit] = wt_pix_2_mm(vIn)
% WT_PIX_2_MM
% Convert from pixels to millimeters according to calibration settings.
% Syntax: [OUT,UNIT] = wt_pix_2_mm(IN), where
%   IN is a trace in pixels
%   UNIT is the unit of the trace returned (mm or pix)
%

global g_tWT

% Defaults
vOut = vIn;
sUnit = 'pix';

if isfield(g_tWT.MovieInfo, 'PixelsPerMM')
    if ~isempty(g_tWT.MovieInfo.PixelsPerMM)
        vOut = vIn ./ g_tWT.MovieInfo.PixelsPerMM;
        sUnit = 'mm';
    end
end

return;
