% wt_get_build_number
% Returns the current hash of GIT build
function wt_get_build_number

% Set paths
sWT_dir = which('wt');
sWT_dir = sWT_dir(1:findstr(sWT_dir, 'wt.m')-1);
sGITPath = checkfilename([sWT_dir '.git/refs/heads/master']);
sVERSIONPath = checkfilename([sWT_dir 'VERSION']);

sHash = 'Unknown';
if exist(sGITPath, 'file')
    fid = fopen(sGITPath);
    sHash = fgetl(fid);
    fclose(fid);
    % Copy hash into VERSION file in top directory
    hFID = fopen(sVERSIONPath, 'w');
    fprintf(hFID, '%s', sHash);
    fclose(hFID);
    sHash = sHash(1:10);
elseif exist(sVERSIONPath, 'file')
    % If the GIT has does not exist in .git, check if VERSION file exists
    hFID = fopen(sVERSIONPath, 'r');
    sHash = char(fread(hFID, 10, 'schar'))';
    fclose(hFID);
end

inputdlg('GitHub SHA-1 Checksum:', 'WhiskerTracker Version', 1, {sHash});

return
