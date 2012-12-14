% wt_get_build_number
function sBuild = wt_get_build_number

% Set paths
sWT_dir = which('wt');
sWT_dir = sWT_dir(1:findstr(sWT_dir, 'wt.m')-1);

% Get build number from SVN entries files
sBuild = 'Unknown';
if ispc, sSVNPath = [sWT_dir '.svn\' 'entries'];
else, sSVNPath = [sWT_dir '.svn/' 'entries']; end
if exist(sSVNPath)
    fid = fopen(sSVNPath);
    for i = 1:5
        sLine = fgetl(fid);
        if strcmp(sLine, 'dir')
            sBuild = fgetl(fid);
        end
    end
    fclose(fid);
end

return
