function sPath = wt_check_path(sPath)
% WT_CHECK_PATH
% Check path so it conforms to system format.
%
%   S2 = wt_fix_path(S1) where S1 and S2 are both strings
%
%   S2 contains only either forward-slashes (Linux/Unix) or backward
%   slashes (Windows). S1 may contain either.
%
% Example:
%   wt_check_path('/media/disk/\movie.avi')
%
%   will on a Linux/Unix system be fixed to
%
%   wt_check_path('/media/disk/movie.avi')
%

if ispc
    sPath = strrep(sPath, '/', '\');
    sPath = strrep(sPath, '\\', '\');
elseif isunix
    sPath = strrep(sPath, '\', '/');
    sPath = strrep(sPath, '//', '/');
end

return
