function wt_toggle_whisker_visibility(nStatus)
% WT_TOGGLE_WHISKER_VISIBILITY

hObj = findobj('Label', 'Hide Whiskers', 'type', 'uimenu');

% Update user-menu
switch get(hObj, 'checked')
    case 'on'
        set(hObj, 'checked', 'off')
        sVisible = 'on';
    case 'off'
        set(hObj, 'checked', 'on')
        sVisible = 'off';
end

for w =1:50
    hWhisk = findobj('Tag', sprintf('whisker%d', w)); % whisker
    hSpl = findobj('Tag', sprintf('scatpt%d', w)); % spline-points
    set([hWhisk hSpl], 'visible', sVisible)
end

return
