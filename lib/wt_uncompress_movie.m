function wt_uncompress_movie
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
global g_tWT

% Request outputfile
vIndx = findstr(g_tWT.MovieInfo.Filename,'\');
vIndx = [vIndx findstr(g_tWT.MovieInfo.Filename,':')];
sName = g_tWT.MovieInfo.Filename;
sName(vIndx) = '-';

% Before trying to uncompress this video in MatLab, try to load it in
% Matlab
try
    MOV = aviread(sName, 1);
catch
    warndlg(sprintf('The current file cannot be loaded into WT and uncompressed from within Matlab for the following reason:\n\n%s', lasterr))
    return
end

[sPath] = uigetdir('C:\', 'Select uncompress directory');
if sPath == 0, return, end % return if user hit 'Cancel'

sFilename = fullfile(sPath,sName);
if isempty(strfind(sFilename,'.avi'))
    sFilename = [sFilename '.avi'];
end

% Open handle to output file
hMov = avifile(sFilename, ...
    'fps', g_tWT.MovieInfo.FramesPerSecond, ...
    'compression', 'none' );

% Increment over frames
hWaitbar = waitbar(0, 'Uncompressing frames...');
try
    vFrames = 1:g_tWT.MovieInfo.NoFramesToLoad:g_tWT.MovieInfo.NumFrames;
    vFrames = [vFrames g_tWT.MovieInfo.NumFrames];
    for i = 1:(length(vFrames)-1)
        waitbar(i/length(vFrames))
        vIndx = vFrames(i):(vFrames(i+1)-1);
        if isempty(vIndx), continue, end
        tFrames = aviread(g_tWT.MovieInfo.Filename, vIndx);
        for f = 1:length(tFrames)
            hMov = addframe(hMov, tFrames(f).cdata);
        end
    end
catch
    wt_error('An error occured during the decompression. Out of disk space? Hit continue.')
end
hMov = close(hMov); % close output file
close(hWaitbar)

g_tWT.MovieInfo.FilenameUncompressed = sFilename;


return
