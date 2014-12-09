function mFrames = wt_load_avi(sFile, vFrames, varargin)
% wt_load_avi
% Load specified range of frames from an AVI movie
% 
% wt_load_avi(FILENAME, FRAMES, OPTION), where
%  FILENAME is the path and name of the AVI file
%  FRAMES   is a vector that contains framenumbers to be loaded
%  OPTION   is an optional parameter, that can be:
%     'none'      no option
%     'noresize'  don't resize frames
% 
% If input file is a different format, such as .bin, this function will
% detect that and call the correct reader function (eg. wt_load_bin).
%
global g_tWT

% Get full filename
% If extension is missing, assume this is an AVI file
[sPath, sFilename, sExt] = fileparts(sFile);
if isempty(sExt)
    sExt = '.avi';
    sFile = fullfile(sPath, [sFilename sExt]);
end

% Check that file exists
if ~exist(sFile, 'file')
    wt_error(sprintf('The file %s does not exist', sFile))
end

% Process alternative file formats, eg. Streamer BIN files.
if ~strcmpi(sExt, '.avi')
    eval(sprintf('mFrames = wt_load_%s(sFile, vFrames);', sExt(2:end)))
    return
end

warning off MATLAB:mat2cell:ObsoleteSingleInput
warning off MATLAB:audiovideo:aviread:FunctionToBeRemoved

persistent p_bForceNewReader p_bDidAviReadCheck;
if isempty(p_bDidAviReadCheck)
    p_bForceNewReader = 0;
    p_bDidAviReadCheck = 0;
end

% Discover video reader (in order of preference)
if exist('VideoReader')
    sVidReader = 'VideoReader';
    bNewVidReader = 1;
elseif exist('mmreader', 'file')
    sVidReader = 'mmreader';
    bNewVidReader = 1;
else
    sVidReader = 'aviread';
    bNewVidReader = 0;
end

% Load frames
try
    % On Linux, mmreader is ~7 times faster than aviread. So, if the mmreader function
    % exists on this system then use it instead of aviread. However, mmreader takes 1-2
    % sec to initialize. Thus, for a small number of frames, continue to use aviread.
    % On PC (Windows), always use mmreader (or VideoReader on Matlab 2012+)
    %
    % Warning: mmreader for unknown reasons seem to return slightly
    % different matrices than aviread. In some cases, pixel values have
    % been seen to 'saturate'. To avoid this, pre-load 50 frames or less.
    %
    % mmreader reads videos as RGB, even when originals are grayscale. The
    % code below thus converts to grayscale.
    %
    % Note 06/13/12: mmreader was found to be extremely slow, with any
    % buffer size, also on Windows. Thus, mmreader was disabled on PCs.
    % If you experience slow performance of aviread() try reducing the
    % buffer size, e.g. to 32 frames if you have a fast disk. The optimal
    % buffer size may also depend on the size of frames, but a a 7-fold
    % improvement in load speeds has been seen when the buffer is set
    % optimally.
    %
    % Note 05/06/13: aviread, being a deprecated function, fails when
    % reading certain AVI containers. Code was added below function
    % that checks aviread() will read successfully. If not, then mmreader/
    % VideoReader is selected as the default.
    %

    % Check that avireader() is capable of reading file
    if ~p_bDidAviReadCheck
        try
            tFrames = aviread(sFile, 1); %#ok<*FREMO>
        catch
            p_bForceNewReader = 1;
        end
        p_bDidAviReadCheck = 1;
    end
    
    if (((bNewVidReader && length(vFrames) > 10) && ~ispc) || ~exist('aviread', 'file')) || p_bForceNewReader
        tMov = eval([sVidReader '(sFile)']);
        nNumberOfFrames = tMov.NumberOfFrames;
        nHeight = tMov.Height;
        nWidth = tMov.Width;

        if isempty(vFrames)
            nFrames = 1:nNumberOfFrames;
        else
            vFrames(vFrames > nNumberOfFrames) = [];
            nFrames = length(vFrames);
        end
        
        % Pre-allocate frames
        tFrames(1:nFrames) = struct('cdata', zeros(nHeight, nWidth, 3, 'uint8'), 'colormap', []);
        
        % Read frames one at a time
        for k = 1:length(vFrames)
            try
                tFrames(k).cdata = read(tMov, vFrames(k));
            catch
                wt_set_status(sprintf('Warning: Frame %d could not be read. The file could be damaged.', vFrames(k)))
                if length(tFrames) > 2
                    tFrames(k).cdata = tFrames(k-1).cdata;
                else
                    tFrames(k).cdata = g_tWT.CurrentFrameBuffer.Img;
                end
            end
        end
    else
        % Use aviread on older systems
        if isempty(vFrames)
            tFrames = aviread(sFile); %#ok<*FREMO>
        else
            tFrames = aviread(sFile, vFrames);
        end
        % Suppress future warnings about aviread
        w = warning('query','last');
        warning('off', w.identifier);
    end    
catch
    wt_error(lasterr)
end

% Remove colormap data
if isfield(tFrames, 'colormap')
    tFrames = rmfield(tFrames, 'colormap');
end

M = size(tFrames(1).cdata,1); % image width
N = size(tFrames(1).cdata,2); % image height
P = size(tFrames(1).cdata,3); % number of dimensions in cdata
Q = size(tFrames, 2);         % number of frames

try
    if P == 3
        tmp = struct2cell(tFrames);
        for t = 1:length(tmp)
            tmp2 = cell2mat(tmp(t));
            tmp(t) = mat2cell(squeeze(tmp2(:,:,1)));
        end
        mFrames = reshape(cell2mat(tmp), [M N 1 Q]); % transform from struct to matrix
    elseif P == 1
        mFrames = reshape(cell2mat(struct2cell(tFrames)), [M N P Q]); % transform from struct to matrix   
    end
catch
    wt_error(lasterr)
end

mFrames = squeeze(mFrames(:,:,1,:)); % reduce RGB to monochrome


return
