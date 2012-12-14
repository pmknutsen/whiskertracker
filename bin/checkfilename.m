%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Converts between forward and backward slash on Windows and Linux filesystems
function sFilename = CheckFilename(sFilename)
if ispc
    sFilename = strrep(sFilename, '/', '\');
    sFilename = strrep(sFilename, '\\', '\');
elseif isunix
    sFilename = strrep(sFilename, '\', '/');
    sFilename = strrep(sFilename, '//', '/');
end
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
