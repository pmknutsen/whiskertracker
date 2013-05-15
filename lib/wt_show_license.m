function wt_show_license
% WT_SHOW_LICENSE
%

sWT_dir = which('wt');
sLICENSEPath = checkfilename([sWT_dir(1:strfind(sWT_dir, 'wt.m')-1) 'LICENSE']);

sLicense = textread(sLICENSEPath, '%s', 'whitespace', '', 'bufsize', 2^16);

hFig = figure;
set(hFig, 'name', 'WhiskerTracker License', 'menubar', 'none', 'numbertitle', 'off', 'color', 'w')
uicontrol('parent', hFig, 'style', 'edit', 'backgroundcolor', 'w', 'max', 2, ...
    'units', 'normalized', 'position', [0 0 1 1], 'string', sLicense, ...
    'horizontalalignment', 'left')

return