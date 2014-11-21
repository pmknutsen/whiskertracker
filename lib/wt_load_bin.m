function mFrames = wt_load_bin(sFile, vFrames, varargin)
% wt_load_bin
% Load specified range of frames from a Streamer BIN file
%
% wt_load_bin(FILENAME, FRAMES, OPTION), where
%  FILENAME is the path and name of the AVI file
%  FRAMES   is a vector that contains framenumbers to be loaded
%
% If input file is a different format, such as AVI, this function will
% detect that and call the correct reader function (eg. wt_load_avi).
%

% Process alternative file formats, eg. Streamer BIN files.
sExt = sFile(end-2:end);
if ~strcmpi(sExt, 'bin')
    eval(sprintf('mFrames = wt_load_%s(sFile, vFrames);', sExt))
    return
end

% Load frames
try
    if isempty(vFrames)
        % Read entire movie
        mFrames = wt_readstreamer(sFile);
    else
        % Read a range of frames
        mFrames = wt_readstreamer(sFile, vFrames);
    end
catch
    wt_error(lasterr)
end

return
