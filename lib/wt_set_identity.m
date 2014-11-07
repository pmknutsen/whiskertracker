function wt_set_identity(nObj, sType)
% WT_SET_IDENTITY
% Set name for an object (whisker or other).
%
% Usage:
%   wt_mark_object(WID)
%   wt_mark_object(WID, 'whisker')
%   wt_mark_object(OID, 'outline')
%
% If the second argument is not provided, 'whisker' is used as default
%

global g_tWT

if ~exist('sType'), sType = 'whisker'; end

% Get old name
switch lower(sType)
    case 'whisker'
        try, sOldName = g_tWT.MovieInfo.WhiskerIdentity{nObj};
        catch, sOldName = {''}; end
    case 'outline'
        try, sOldName = g_tWT.MovieInfo.Outlines(nObj).Name;
        catch, sOldName = {''}; end
end
if isempty(sOldName), sOldName = {''}; end

% Ask for name
switch lower(sType)
    case 'whisker'
        sNewName = inputdlg('Enter name for this object (eg. C1, EYE_NOSE etc)', ...
            'WT Set name', 1, sOldName);
    case 'outline'
        sNewName = inputdlg('Enter name for this object (eg. AVGPOS_ROI, LABELLIM etc)', ...
            'WT Set name', 1, sOldName);
end
if isempty(sNewName), sNewName = sOldName; end

% Set new name 
switch lower(sType)
    case 'whisker'
        g_tWT.MovieInfo.WhiskerIdentity{nObj} = upper(sNewName);
    case 'outline'
        g_tWT.MovieInfo.Outlines(nObj).Name = upper(sNewName);
end

wt_display_frame

return
